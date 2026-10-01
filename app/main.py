import logging
import sys
import threading
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.auth.config import AuthSettings
from app.auth.validator import build_token_validator
from app.config import Settings, get_settings
from app.database import build_engine, build_session_factory, check_database
from app.errors import register_exception_handlers
from app.health.router import router as health_router
from app.orders.repository import InMemoryOrderRepository, InMemoryProductRepository
from app.orders.router import router as orders_router
from app.users.repository import InMemoryUserRepository
from app.users.router import router as users_router


def create_app(settings: Settings | None = None) -> FastAPI:
    """Arma la app: configuración, handlers de errores y routers de cada módulo.

    Aquí no va lógica de negocio: cada dominio vive en su paquete (app/orders, app/health...).
    """
    settings = settings or get_settings()
    # Logs a stdout: es lo que muestra el log stream de App Service (stderr no aparece ahí).
    # Librerías en INFO; APP_LOG_LEVEL solo controla los logs de nuestro código (app.*)
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    logging.getLogger("app").setLevel(settings.log_level)
    # El driver de SQL registra cada pedido de token de la managed identity: solo avisos
    logging.getLogger("azure").setLevel(logging.WARNING)

    engine = build_engine(settings)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        # La prueba de conexión corre en segundo plano y su resultado queda en los logs.
        # No puede bloquear el arranque: si la red a la base no responde, el driver espera
        # su timeout y App Service mataría el contenedor por no abrir el puerto a tiempo.
        app.state.db_check = threading.Thread(
            target=check_database, args=(engine,), name="db-check", daemon=True
        )
        app.state.db_check.start()
        yield
        if engine is not None:
            engine.dispose()

    app = FastAPI(
        title="dp3-appservice-orders",
        version="0.5.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.docs_enabled else None,
        redoc_url="/redoc" if settings.docs_enabled else None,
        openapi_url="/openapi.json" if settings.docs_enabled else None,
    )
    register_exception_handlers(app)

    # Dependencias compartidas por request (ver app/*/dependencies.py). Con base configurada
    # cada request usa repositorios SQL con su propia sesión; sin base (tests), los de memoria.
    app.state.db_engine = engine
    app.state.session_factory = build_session_factory(engine)
    app.state.order_repository = InMemoryOrderRepository()
    app.state.product_repository = InMemoryProductRepository()
    app.state.user_repository = InMemoryUserRepository()
    app.state.token_validator = build_token_validator(AuthSettings())

    @app.get("/")
    def read_root() -> dict[str, str]:
        return {"message": "Hola desde dp3-appservice-orders", "env": settings.env}

    app.include_router(health_router)
    app.include_router(orders_router, prefix="/api/v1")
    app.include_router(users_router, prefix="/api/v1")

    return app


app = create_app()
