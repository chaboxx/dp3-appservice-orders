"""Acceso a datos de órdenes.

El service depende del `Protocol`, no de una implementación concreta: hoy se usa la versión
en memoria y mañana se agrega una SQL/Cosmos sin tocar la lógica de negocio.
"""

from typing import Protocol
from uuid import UUID

from app.orders.models import Order


class OrderRepository(Protocol):
    def add(self, order: Order) -> None: ...

    def get(self, order_id: UUID) -> Order | None: ...

    def list_all(self) -> list[Order]: ...


class InMemoryOrderRepository:
    """Guarda las órdenes en un dict. Se pierde al reiniciar: solo para desarrollo y tests."""

    def __init__(self) -> None:
        self._orders: dict[UUID, Order] = {}

    def add(self, order: Order) -> None:
        self._orders[order.id] = order

    def get(self, order_id: UUID) -> Order | None:
        return self._orders.get(order_id)

    def list_all(self) -> list[Order]:
        return list(self._orders.values())
