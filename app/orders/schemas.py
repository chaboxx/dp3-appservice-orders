"""Contrato público de la API de órdenes (lo que entra y sale por HTTP).

Se mantiene separado de `models.py`: cambiar cómo se guarda una orden no debe romper la API.
Las validaciones siguen el DDL (largos de columnas, CHECKs) y rechazan campos desconocidos:
el dueño sale del token, y el estado, los precios y el total los decide el server.
"""

from datetime import datetime
from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, model_validator

from app.orders.constants import MAX_ITEMS_PER_ORDER, SQL_INT_MAX, OrderStatus

# Orders.payment_type VARCHAR(100)
PaymentType = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]


class OrderItemCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    product_id: UUID
    quantity: int = Field(gt=0, le=SQL_INT_MAX)  # ck_order_item_quantity


class OrderCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    payment_type: PaymentType | None = None
    items: list[OrderItemCreate] = Field(min_length=1, max_length=MAX_ITEMS_PER_ORDER)

    @model_validator(mode="after")
    def products_are_unique(self) -> OrderCreate:
        product_ids = [item.product_id for item in self.items]
        if len(product_ids) != len(set(product_ids)):
            raise ValueError("Each product can appear only once; use quantity instead")
        return self


class OrderUpdate(BaseModel):
    """PATCH: solo se envían los campos a cambiar. El cliente solo puede cancelar."""

    model_config = ConfigDict(extra="forbid")

    payment_type: PaymentType | None = None
    status: Literal[OrderStatus.CANCELLED] | None = None

    @model_validator(mode="after")
    def has_changes(self) -> OrderUpdate:
        if not self.model_fields_set:
            raise ValueError("At least one field is required")
        return self


class OrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID
    unit_price: Decimal
    quantity: int


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    total: Decimal
    payment_type: str | None
    status: OrderStatus
    items: list[OrderItemRead]
    created_at: datetime
    updated_at: datetime


class OrderPage(BaseModel):
    items: list[OrderRead]
    page: int
    page_size: int
    total: int  # órdenes en total (todas las páginas)
