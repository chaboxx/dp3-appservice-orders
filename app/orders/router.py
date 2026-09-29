"""Endpoints HTTP de órdenes: traducen HTTP ↔ service, sin reglas de negocio."""

from fastapi import APIRouter, status

from app.orders.dependencies import OrderServiceDep, ValidOrder
from app.orders.schemas import OrderCreate, OrderRead

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", status_code=status.HTTP_201_CREATED)
def create_order(data: OrderCreate, service: OrderServiceDep) -> OrderRead:
    return OrderRead.model_validate(service.create(data))


@router.get("")
def list_orders(service: OrderServiceDep) -> list[OrderRead]:
    return [OrderRead.model_validate(order) for order in service.list_all()]


@router.get("/{order_id}")
def get_order(order: ValidOrder) -> OrderRead:
    return OrderRead.model_validate(order)
