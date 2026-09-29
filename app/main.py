import logging

from fastapi import FastAPI

from app.config import Settings, get_settings
from app.errors import register_exception_handlers
from app.health.router import router as health_router
from app.orders.repository import InMemoryOrderRepository
from app.orders.router import router as orders_router


def create_app(settings: Settings | None = None) -> FastAPI:
    """Arma la app: configuración, handlers de errores y routers de cada módulo.

    Aquí no va lógica de negocio: cada dominio vive en su paquete (app/orders, app/health...).
    """
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

    # Dependencias compartidas por request (ver app/orders/dependencies.py)
    app.state.order_repository = InMemoryOrderRepository()

    @app.get("/")
    def read_root() -> dict[str, str]:
        return {"message": "Hola desde dp3-appservice-orders", "env": settings.env}

    app.include_router(health_router)
    app.include_router(orders_router, prefix="/api/v1")

    return app


app = create_app()
