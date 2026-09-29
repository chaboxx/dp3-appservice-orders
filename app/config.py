from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración de la app, leída de variables de entorno con prefijo APP_.

    La app no sabe de archivos .env: quien la ejecuta (uv, Docker o App Service)
    es responsable de cargar las variables del entorno que corresponda.
    """

    model_config = SettingsConfigDict(env_prefix="APP_", env_ignore_empty=True)

    env: Literal["dev", "prod"] = "dev"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
    docs_enabled: bool = True

    # Azure SQL. Sin server/name la app arranca sin base de datos (solo lo avisa en los logs).
    # No hay contraseña: en Azure se usa la managed identity de la Web App (ActiveDirectoryMSI);
    # en local, ActiveDirectoryDefault usa la sesión de `az login`.
    db_server: str | None = None  # p. ej. dp3-mssql-orders-server.database.windows.net
    db_name: str | None = None
    db_authentication: str = "ActiveDirectoryMSI"


@lru_cache
def get_settings() -> Settings:
    return Settings()
