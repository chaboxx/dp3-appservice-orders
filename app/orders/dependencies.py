from typing import Annotated
from uuid import UUID

from fastapi import Depends, Request

from app.orders.models import Order
from app.orders.repository import OrderRepository
from app.orders.service import OrderService


def get_order_repository(request: Request) -> OrderRepository:
    # Una instancia por app (se crea en create_app), así cada test arranca con datos limpios
    return request.app.state.order_repository


def get_order_service(
    repository: Annotated[OrderRepository, Depends(get_order_repository)],
) -> OrderService:
    return OrderService(repository)


OrderServiceDep = Annotated[OrderService, Depends(get_order_service)]


def valid_order_id(order_id: UUID, service: OrderServiceDep) -> Order:
    """Carga la orden de la ruta o responde 404. Reutilizable en cualquier endpoint /{order_id}."""
    return service.get(order_id)


ValidOrder = Annotated[Order, Depends(valid_order_id)]
