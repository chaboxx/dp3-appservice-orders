"""Tests unitarios del service: sin HTTP ni FastAPI, con el repositorio en memoria."""

from decimal import Decimal
from uuid import uuid4

import pytest

from app.orders.constants import OrderStatus
from app.orders.exceptions import OrderNotFound
from app.orders.repository import InMemoryOrderRepository
from app.orders.schemas import OrderCreate
from app.orders.service import OrderService


@pytest.fixture
def service() -> OrderService:
    return OrderService(InMemoryOrderRepository())


def test_create_starts_pending(service: OrderService) -> None:
    order = service.create(OrderCreate(customer_id="c-1", total=Decimal("10.50")))

    assert order.status == OrderStatus.PENDING
    assert service.get(order.id) == order


def test_get_missing_raises(service: OrderService) -> None:
    with pytest.raises(OrderNotFound):
        service.get(uuid4())


def test_list_all(service: OrderService) -> None:
    service.create(OrderCreate(customer_id="c-1", total=Decimal("1")))
    service.create(OrderCreate(customer_id="c-2", total=Decimal("2")))

    assert len(service.list_all()) == 2
