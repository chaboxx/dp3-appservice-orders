import logging

from fastapi import FastAPI

from app.config import Settings, get_settings
from app.errors import register_exception_handlers


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    # Librerías en INFO; APP_LOG_LEVEL solo controla los logs de nuestro código (app.*)
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("app").setLevel(settings.log_level)

    app = FastAPI(
        title="dp3-appservice-orders",
        version="0.1.0",
        docs_url="/docs" if settings.docs_enabled else None,
        redoc_url="/redoc" if settings.docs_enabled else None,
        openapi_url="/openapi.json" if settings.docs_enabled else None,
    )
    register_exception_handlers(app)

    @app.get("/")
    def read_root() -> dict[str, str]:
        return {"message": "Hola desde dp3-appservice-orders", "env": settings.env}

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
