"""Cómo se guarda una orden.

Hoy es una dataclass porque el repositorio es en memoria. Cuando haya base de datos,
aquí van las tablas del ORM (SQLAlchemy/SQLModel) y el resto del módulo no cambia.
"""

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from app.orders.constants import OrderStatus


@dataclass
class Order:
    id: UUID
    customer_id: str
    total: Decimal
    status: OrderStatus
    created_at: datetime
