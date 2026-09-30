"""Los modelos ORM deben reflejar el DDL de SQL Server (la fuente de verdad del esquema)."""

import logging

import pytest
from sqlalchemy import create_engine
from sqlalchemy.dialects import mssql
from sqlalchemy.orm import configure_mappers
from sqlalchemy.schema import CreateTable

import app.orders.models
import app.users.models  # noqa: F401
from app.config import Settings
from app.database import Base, build_engine, check_database


def test_models_cover_all_ddl_tables() -> None:
    configure_mappers()  # falla si alguna relación o foreign key está mal definida

    assert set(Base.metadata.tables) == {"Users", "Products", "Orders", "OrderItem"}


def test_timestamps_are_datetime2_in_sql_server() -> None:
    ddl = str(CreateTable(Base.metadata.tables["Users"]).compile(dialect=mssql.dialect()))

    assert "created_at DATETIME2 NOT NULL" in ddl


def test_engine_uses_managed_identity_without_password() -> None:
    settings = Settings(db_server="dp3-sql.database.windows.net", db_name="orders")

    url = build_engine(settings).url

    assert url.drivername == "mssql+mssqlpython"
    assert url.query["authentication"] == "ActiveDirectoryMSI"
    assert url.password is None


def test_no_engine_without_database_config() -> None:
    assert build_engine(Settings()) is None
    assert check_database(None) is False


def test_check_database_logs_success_and_failure(caplog: pytest.LogCaptureFixture) -> None:
    caplog.set_level(logging.INFO, logger="app.database")

    ok_engine = create_engine("sqlite://")
    failing_engine = create_engine("sqlite:///carpeta-que-no-existe/x.db")

    assert check_database(ok_engine) is True
    assert check_database(failing_engine) is False
    ok_engine.dispose()
    failing_engine.dispose()

    assert "Database connection OK" in caplog.text
    assert "Database connection FAILED" in caplog.text
