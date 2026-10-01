"""Conexión a Azure SQL y base común de los modelos ORM (SQLAlchemy).

La fuente de verdad del esquema es el DDL de SQL Server: los modelos lo reflejan
(nombres de tablas, constraints e índices) pero no crean tablas.
"""

import logging
from collections.abc import Iterator
from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy import URL, DateTime, Engine, create_engine, func, text
from sqlalchemy.dialects.mssql import DATETIME2
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker

from app.config import Settings

logger = logging.getLogger(__name__)

# DATETIME2 en SQL Server (DateTime genérico sería DATETIME, con precisión de ~3 ms)
DateTime2 = DateTime().with_variant(DATETIME2(), "mssql")


def utcnow() -> datetime:
    """Hora UTC sin zona horaria, igual que SYSUTCDATETIME() en un DATETIME2."""
    return datetime.now(UTC).replace(tzinfo=None)


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


def build_session_factory(engine: Engine | None) -> sessionmaker[Session] | None:
    """Fábrica de sesiones. None sin base: los módulos usan entonces sus repositorios en memoria."""
    if engine is None:
        return None
    return sessionmaker(engine, expire_on_commit=False)


def check_database(engine: Engine | None) -> bool:
    """Prueba la conexión al arrancar y deja el resultado en los logs.

    No detiene la app si falla: el error aparece igual en el primer request que use la base.
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


def get_session(request: Request) -> Iterator[Session | None]:
    """Una transacción por request: commit si todo sale bien, rollback ante cualquier error
    (incluidos los DomainError de los services). None si no hay base configurada."""
    factory: sessionmaker[Session] | None = request.app.state.session_factory
    if factory is None:
        yield None
        return
    with factory.begin() as session:
        yield session


# scope="function": el commit ocurre al terminar el endpoint y ANTES de enviar la respuesta;
# así nunca se responde 201 si el commit falla.
DbSession = Annotated[Session | None, Depends(get_session, scope="function")]
