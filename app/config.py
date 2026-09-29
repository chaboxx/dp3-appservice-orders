from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración de la app, leída de variables de entorno con prefijo APP_.

    La app no sabe de archivos .env: quien la ejecuta (uv, Docker o App Service)
    es responsable de cargar las variables del entorno que corresponda.
    """

    model_config = SettingsConfigDict(env_prefix="APP_")

    env: Literal["dev", "prod"] = "dev"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
    docs_enabled: bool = True


@lru_cache
def get_settings() -> Settings:
    return Settings()
