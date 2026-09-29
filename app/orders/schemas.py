"""Contrato público de la API de órdenes (lo que entra y sale por HTTP).

Se mantiene separado de `models.py`: cambiar cómo se guarda una orden no debe romper la API.
"""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.orders.constants import OrderStatus


class OrderCreate(BaseModel):
    customer_id: str = Field(min_length=1, max_length=64)
    total: Decimal = Field(gt=0, max_digits=12, decimal_places=2)


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    customer_id: str
    total: Decimal
    status: OrderStatus
    created_at: datetime
