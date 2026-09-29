"""Reglas de negocio de órdenes.

No importa nada de FastAPI: no sabe de requests ni de códigos HTTP. Los errores se lanzan
como excepciones de dominio (ver `exceptions.py`) y `app/errors.py` las traduce a HTTP.
"""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from app.orders.constants import OrderStatus
from app.orders.exceptions import OrderNotFound
from app.orders.models import Order
from app.orders.repository import OrderRepository
from app.orders.schemas import OrderCreate


class OrderService:
    def __init__(self, repository: OrderRepository) -> None:
        self._repository = repository

    def create(self, data: OrderCreate) -> Order:
        order = Order(
            id=uuid4(),
            customer_id=data.customer_id,
            total=data.total,
            status=OrderStatus.PENDING,
            created_at=datetime.now(UTC),
        )
        self._repository.add(order)
        return order

    def get(self, order_id: UUID) -> Order:
        order = self._repository.get(order_id)
        if order is None:
            raise OrderNotFound(order_id)
        return order

    def list_all(self) -> list[Order]:
        return self._repository.list_all()
