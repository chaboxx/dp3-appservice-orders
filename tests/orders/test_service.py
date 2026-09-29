"""Tests unitarios del service: sin HTTP ni FastAPI, con el repositorio en memoria."""

from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from app.orders.constants import OrderStatus
from app.orders.exceptions import OrderNotFound
from app.orders.repository import InMemoryOrderRepository
from app.orders.schemas import OrderCreate
from app.orders.service import OrderService

USER_ID = UUID("11111111-1111-1111-1111-111111111111")


@pytest.fixture
def service() -> OrderService:
    return OrderService(InMemoryOrderRepository())


def test_create_starts_pending(service: OrderService) -> None:
    order = service.create(OrderCreate(user_id=USER_ID, total=Decimal("10.50")))

    assert order.status == OrderStatus.PENDING
    assert service.get(order.id) == order


def test_get_missing_raises(service: OrderService) -> None:
    with pytest.raises(OrderNotFound):
        service.get(uuid4())


def test_list_all(service: OrderService) -> None:
    service.create(OrderCreate(user_id=USER_ID, total=Decimal("1")))
    service.create(OrderCreate(user_id=USER_ID, total=Decimal("2")))

    assert len(service.list_all()) == 2
