"""Conexión a Azure SQL y base común de los modelos ORM (SQLAlchemy).

La fuente de verdad del esquema es el DDL de SQL Server: los modelos lo reflejan
(nombres de tablas, constraints e índices) pero no crean tablas.
"""

import logging
from datetime import datetime

from sqlalchemy import URL, DateTime, Engine, create_engine, func, text
from sqlalchemy.dialects.mssql import DATETIME2
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.config import Settings

logger = logging.getLogger(__name__)

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


def build_engine(settings: Settings) -> Engine | None:
    """Engine de Azure SQL con el driver mssql-python. None si no hay base configurada.

    No abre ninguna conexión: eso ocurre en el primer uso (ver `check_database`).
    """
    if not (settings.db_server and settings.db_name):
        return None
    url = URL.create(
        "mssql+mssqlpython",
        host=settings.db_server,
        port=1433,
        database=settings.db_name,
        query={"authentication": settings.db_authentication, "Encrypt": "yes"},
    )
    return create_engine(url, pool_pre_ping=True)


def check_database(engine: Engine | None) -> bool:
    """Prueba la conexión al arrancar y deja el resultado en los logs.

    No detiene la app si falla: los endpoints actuales no usan la base de datos todavía.
    """
    if engine is None:
        logger.warning("Database not configured (APP_DB_SERVER / APP_DB_NAME): skipping check")
        return False
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except Exception:
        logger.exception("Database connection FAILED (%s)", engine.url.render_as_string())
        return False
    logger.info("Database connection OK (%s)", engine.url.render_as_string())
    return True
