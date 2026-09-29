"""Contrato público de la API de órdenes (lo que entra y sale por HTTP).

Se mantiene separado de `models.py`: cambiar cómo se guarda una orden no debe romper la API.
"""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.orders.constants import OrderStatus


class OrderCreate(BaseModel):
    # Temporal: cuando la API valide tokens de Entra, user_id saldrá del token y no del body
    user_id: UUID
    total: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    payment_type: str | None = Field(default=None, max_length=100)


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    total: Decimal
    payment_type: str | None
    status: OrderStatus
    created_at: datetime
    updated_at: datetime
