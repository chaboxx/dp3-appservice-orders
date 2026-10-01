"""Endpoints HTTP de órdenes: traducen HTTP ↔ service, sin reglas de negocio.

Todos exigen el scope Orders.ReadWrite y trabajan solo con las órdenes del usuario del token.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.auth.dependencies import require_scope
from app.orders.constants import DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE, ORDERS_SCOPE
from app.orders.dependencies import OrderServiceDep, OwnedOrder
from app.orders.schemas import OrderCreate, OrderPage, OrderRead, OrderUpdate
from app.users.dependencies import CurrentUser

router = APIRouter(
    prefix="/orders", tags=["orders"], dependencies=[Depends(require_scope(ORDERS_SCOPE))]
)


@router.post("", status_code=status.HTTP_201_CREATED)
def create_order(data: OrderCreate, user: CurrentUser, service: OrderServiceDep) -> OrderRead:
    return OrderRead.model_validate(service.create(user.id, data))


@router.get("")
def list_orders(
    user: CurrentUser,
    service: OrderServiceDep,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=MAX_PAGE_SIZE)] = DEFAULT_PAGE_SIZE,
) -> OrderPage:
    """Órdenes del usuario, de la más nueva a la más antigua."""
    orders, total = service.list_page(user.id, page, page_size)
    return OrderPage(
        items=[OrderRead.model_validate(order) for order in orders],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.patch("/{order_id}")
def update_order(order: OwnedOrder, data: OrderUpdate, service: OrderServiceDep) -> OrderRead:
    return OrderRead.model_validate(service.update(order, data))


@router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(order: OwnedOrder, service: OrderServiceDep) -> None:
    service.delete(order)
