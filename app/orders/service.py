"""Reglas de negocio de órdenes.

No importa nada de FastAPI: no sabe de requests ni de códigos HTTP. Los errores se lanzan
como excepciones de dominio (ver `exceptions.py`) y `app/errors.py` las traduce a HTTP.
Todo lo que hace un método ocurre en una sola transacción (la del request): si se lanza un
error a mitad de camino, la base deshace todo (p. ej. el stock ya descontado).
"""

from uuid import UUID

from app.database import utcnow
from app.orders.constants import MAX_ORDER_TOTAL, OrderStatus
from app.orders.exceptions import (
    InsufficientStock,
    OrderNotEditable,
    OrderNotFound,
    OrderTotalTooLarge,
    ProductNotFound,
)
from app.orders.models import Order, OrderItem
from app.orders.repository import OrderRepository, ProductRepository
from app.orders.schemas import OrderCreate, OrderUpdate


class OrderService:
    def __init__(self, orders: OrderRepository, products: ProductRepository) -> None:
        self._orders = orders
        self._products = products

    def create(self, user_id: UUID, data: OrderCreate) -> Order:
        products = self._products.get_many(line.product_id for line in data.items)
        items = []
        for line in data.items:
            product = products.get(line.product_id)
            if product is None:
                raise ProductNotFound(line.product_id)
            if product.stock < line.quantity:
                raise InsufficientStock(product.id)
            # El precio sale de Products (precio al momento de la compra), nunca del cliente
            items.append(
                OrderItem(product_id=product.id, unit_price=product.price, quantity=line.quantity)
            )

        total = sum(item.unit_price * item.quantity for item in items)
        if total > MAX_ORDER_TOTAL:
            raise OrderTotalTooLarge()

        # El descuento es atómico: si otro request se llevó el stock después de leerlo, falla aquí
        for item in items:
            if not self._products.decrease_stock(item.product_id, item.quantity):
                raise InsufficientStock(item.product_id)

        # id y timestamps los genera la base de datos al guardar (NEWSEQUENTIALID, SYSUTCDATETIME)
        order = Order(
            user_id=user_id,
            total=total,
            payment_type=data.payment_type,
            status=OrderStatus.PENDING,
            items=items,
        )
        self._orders.add(order)
        return order

    def get_for_update(self, order_id: UUID, user_id: UUID) -> Order:
        """La orden activa del usuario. Si es de otro o está borrada: 404 (no se revela)."""
        order = self._orders.get_for_update(order_id, user_id)
        if order is None:
            raise OrderNotFound(order_id)
        return order

    def list_page(self, user_id: UUID, page: int, page_size: int) -> tuple[list[Order], int]:
        orders = self._orders.list_page(user_id, offset=(page - 1) * page_size, limit=page_size)
        return orders, self._orders.count(user_id)

    def update(self, order: Order, data: OrderUpdate) -> Order:
        if order.status != OrderStatus.PENDING:
            raise OrderNotEditable(order.id, order.status)
        if "payment_type" in data.model_fields_set:
            order.payment_type = data.payment_type
        if data.status == OrderStatus.CANCELLED:
            self._cancel(order)
        self._orders.save(order)
        return order

    def delete(self, order: Order) -> None:
        """Soft delete. Una orden pendiente se cancela primero (devuelve el stock)."""
        if order.status == OrderStatus.PENDING:
            self._cancel(order)
        elif order.status != OrderStatus.CANCELLED:
            raise OrderNotEditable(order.id, order.status)
        order.deleted_at = utcnow()
        self._orders.save(order)

    def _cancel(self, order: Order) -> None:
        for item in order.items:
            self._products.increase_stock(item.product_id, item.quantity)
        order.status = OrderStatus.CANCELLED
