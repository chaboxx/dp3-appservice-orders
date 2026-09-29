"""Base común de los modelos ORM (SQLAlchemy).

La fuente de verdad del esquema es el DDL de SQL Server: los modelos lo reflejan
(nombres de tablas, constraints e índices) pero no crean tablas.
"""

from datetime import datetime

from sqlalchemy import DateTime, func
from sqlalchemy.dialects.mssql import DATETIME2
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# DATETIME2 en SQL Server (DateTime genérico sería DATETIME, con precisión de ~3 ms)
DateTime2 = DateTime().with_variant(DATETIME2(), "mssql")


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    """created_at / updated_at en UTC, con DEFAULT SYSUTCDATETIME() en la base."""

    created_at: Mapped[datetime] = mapped_column(DateTime2, server_default=func.sysutcdatetime())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime2, server_default=func.sysutcdatetime(), onupdate=func.sysutcdatetime()
    )
