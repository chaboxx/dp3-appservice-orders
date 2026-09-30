from pydantic_settings import BaseSettings, SettingsConfigDict


class AuthSettings(BaseSettings):
    """Tenant de Entra External ID en el que confía la API, leído de variables APP_AUTH_*.

    Ninguno de los 3 valores es secreto: issuer y jwks_uri se copian del documento
    .well-known/openid-configuration del tenant, y audience es el client ID de la
    app registration de la API.
    """

    model_config = SettingsConfigDict(env_prefix="APP_AUTH_", env_ignore_empty=True)

    issuer: str | None = None
    jwks_uri: str | None = None
    audience: str | None = None
