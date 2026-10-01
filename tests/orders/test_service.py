"""Tests unitarios del service: sin HTTP ni FastAPI, con los repositorios en memoria."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from app.orders.constants import OrderStatus
from app.orders.exceptions import (
    InsufficientStock,
    OrderNotEditable,
    OrderNotFound,
    OrderTotalTooLarge,
    ProductNotFound,
)
from app.orders.models import Order, Product
from app.orders.repository import InMemoryOrderRepository, InMemoryProductRepository
from app.orders.schemas import OrderCreate, OrderItemCreate, OrderUpdate
from app.orders.service import OrderService

USER_ID = UUID("11111111-1111-1111-1111-111111111111")
OTHER_USER_ID = UUID("22222222-2222-2222-2222-222222222222")


@pytest.fixture
def products() -> InMemoryProductRepository:
    return InMemoryProductRepository()


@pytest.fixture
def service(products: InMemoryProductRepository) -> OrderService:
    return OrderService(InMemoryOrderRepository(), products)


def add_product(
    products: InMemoryProductRepository, price: str = "10.50", stock: int = 10
) -> Product:
    return products.add(Product(name="Teclado", price=Decimal(price), stock=stock, category="x"))


def order_of(product: Product, quantity: int = 1) -> OrderCreate:
    return OrderCreate(items=[OrderItemCreate(product_id=product.id, quantity=quantity)])


def test_create_uses_product_prices_and_decreases_stock(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    keyboard = add_product(products, price="10.50", stock=10)
    mouse = add_product(products, price="2.00", stock=5)
    data = OrderCreate(
        payment_type="card",
        items=[
            OrderItemCreate(product_id=keyboard.id, quantity=2),
            OrderItemCreate(product_id=mouse.id, quantity=1),
        ],
    )

    order = service.create(USER_ID, data)

    assert order.status == OrderStatus.PENDING
    assert order.user_id == USER_ID
    assert order.total == Decimal("23.00")
    assert [item.unit_price for item in order.items] == [Decimal("10.50"), Decimal("2.00")]
    assert (keyboard.stock, mouse.stock) == (8, 4)


def test_create_rejects_unknown_product(service: OrderService) -> None:
    data = OrderCreate(items=[OrderItemCreate(product_id=uuid4(), quantity=1)])

    with pytest.raises(ProductNotFound):
        service.create(USER_ID, data)


def test_create_rejects_insufficient_stock(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products, stock=1)

    with pytest.raises(InsufficientStock):
        service.create(USER_ID, order_of(product, quantity=2))
    assert product.stock == 1


def test_create_rejects_total_that_does_not_fit_in_decimal_12_2(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products, price="9999999999.99", stock=2)

    with pytest.raises(OrderTotalTooLarge):
        service.create(USER_ID, order_of(product, quantity=2))


def test_list_page_is_newest_first_and_only_the_users_active_orders(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products)
    first, second, third = (service.create(USER_ID, order_of(product)) for _ in range(3))
    for day, order in enumerate((first, second, third), start=1):
        order.created_at = datetime(2026, 1, day)  # el reloj de Windows puede repetir valores
    service.create(OTHER_USER_ID, order_of(product))
    service.delete(second)

    page_1, total = service.list_page(USER_ID, page=1, page_size=1)
    page_2, _ = service.list_page(USER_ID, page=2, page_size=1)

    assert total == 2
    assert page_1 == [third]
    assert page_2 == [first]


def test_update_payment_type(service: OrderService, products: InMemoryProductRepository) -> None:
    order = service.create(USER_ID, order_of(add_product(products)))

    service.update(order, OrderUpdate(payment_type="cash"))

    assert order.payment_type == "cash"
    assert order.status == OrderStatus.PENDING


def test_cancel_returns_the_stock(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products, stock=10)
    order = service.create(USER_ID, order_of(product, quantity=3))

    service.update(order, OrderUpdate(status=OrderStatus.CANCELLED))

    assert order.status == OrderStatus.CANCELLED
    assert product.stock == 10


@pytest.mark.parametrize("status", [OrderStatus.CONFIRMED, OrderStatus.CANCELLED])
def test_only_pending_orders_can_be_updated(
    service: OrderService, products: InMemoryProductRepository, status: OrderStatus
) -> None:
    order = service.create(USER_ID, order_of(add_product(products)))
    order.status = status

    with pytest.raises(OrderNotEditable):
        service.update(order, OrderUpdate(payment_type="cash"))


def test_delete_pending_cancels_it_and_hides_it(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products, stock=10)
    order = service.create(USER_ID, order_of(product, quantity=4))

    service.delete(order)

    assert order.deleted_at is not None
    assert order.status == OrderStatus.CANCELLED
    assert product.stock == 10
    with pytest.raises(OrderNotFound):
        service.get_for_update(order.id, USER_ID)


def test_delete_cancelled_does_not_return_the_stock_twice(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    product = add_product(products, stock=10)
    order = service.create(USER_ID, order_of(product, quantity=4))
    service.update(order, OrderUpdate(status=OrderStatus.CANCELLED))

    service.delete(order)

    assert order.deleted_at is not None
    assert product.stock == 10


def test_confirmed_orders_cannot_be_deleted(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    order = service.create(USER_ID, order_of(add_product(products)))
    order.status = OrderStatus.CONFIRMED

    with pytest.raises(OrderNotEditable):
        service.delete(order)
    assert order.deleted_at is None


def test_orders_of_other_users_are_not_found(
    service: OrderService, products: InMemoryProductRepository
) -> None:
    order: Order = service.create(OTHER_USER_ID, order_of(add_product(products)))

    with pytest.raises(OrderNotFound):
        service.get_for_update(order.id, USER_ID)
