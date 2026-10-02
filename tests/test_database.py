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


def test_encrypted_names_use_bin2_collation() -> None:
    # Always Encrypted exige collation _BIN2 en las columnas de texto cifradas (migrations/05)
    ddl = str(CreateTable(Base.metadata.tables["Users"]).compile(dialect=mssql.dialect()))

    assert "first_name NVARCHAR(200) COLLATE Latin1_General_BIN2 NULL" in ddl
    assert "last_name NVARCHAR(200) COLLATE Latin1_General_BIN2 NULL" in ddl
    assert "email NVARCHAR(320) NOT NULL" in ddl  # el email queda legible y con su collation
    assert "city NVARCHAR(128) NULL" in ddl  # legible: el ETL agrupa por ciudad (migrations/06)


def test_engine_uses_managed_identity_and_always_encrypted() -> None:
    settings = Settings(db_server="dp3-sql.database.windows.net", db_name="orders")

    engine = build_engine(settings)
    connect_args, _ = engine.dialect.create_connect_args(engine.url)
    connection_string = connect_args[0]

    assert engine.url.drivername == "mssql+pyodbc"
    assert engine.url.password is None
    assert "DRIVER={ODBC Driver 18 for SQL Server}" in connection_string
    assert "Authentication=ActiveDirectoryMsi" in connection_string
    assert "Trusted_Connection" not in connection_string
    assert "ColumnEncryption=Enabled" in connection_string
    assert "KeyStoreAuthentication=KeyVaultManagedIdentity" in connection_string
    # los valores de los parámetros (nombres descifrados) no deben llegar a errores ni logs
    assert engine.hide_parameters is True


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
