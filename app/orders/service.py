"""Reglas de negocio de órdenes.

No importa nada de FastAPI: no sabe de requests ni de códigos HTTP. Los errores se lanzan
como excepciones de dominio (ver `exceptions.py`) y `app/errors.py` las traduce a HTTP.
"""

from uuid import UUID

from app.orders.constants import OrderStatus
from app.orders.exceptions import OrderNotFound
from app.orders.models import Order
from app.orders.repository import OrderRepository
from app.orders.schemas import OrderCreate


class OrderService:
    def __init__(self, repository: OrderRepository) -> None:
        self._repository = repository

    def create(self, data: OrderCreate) -> Order:
        # id y timestamps los genera la base de datos al guardar (NEWSEQUENTIALID, SYSUTCDATETIME)
        order = Order(
            user_id=data.user_id,
            total=data.total,
            payment_type=data.payment_type,
            status=OrderStatus.PENDING,
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
