from typing import Annotated
from uuid import UUID

from fastapi import Depends, Request

from app.database import DbSession
from app.orders.models import Order
from app.orders.repository import SqlOrderRepository, SqlProductRepository
from app.orders.service import OrderService
from app.users.dependencies import CurrentUser


def get_order_service(request: Request, session: DbSession) -> OrderService:
    # Sin base configurada (tests) se usan los repositorios en memoria creados en create_app,
    # una instancia por app: así cada test arranca con datos limpios
    if session is None:
        state = request.app.state
        return OrderService(state.order_repository, state.product_repository)
    return OrderService(SqlOrderRepository(session), SqlProductRepository(session))


OrderServiceDep = Annotated[OrderService, Depends(get_order_service)]


def owned_order(order_id: UUID, user: CurrentUser, service: OrderServiceDep) -> Order:
    """Carga la orden de la ruta si es del usuario y no está borrada; si no, 404."""
    return service.get_for_update(order_id, user.id)


OwnedOrder = Annotated[Order, Depends(owned_order)]
