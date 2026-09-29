# dp3-appservice-orders

API de órdenes con FastAPI, pensada para desplegarse como contenedor en Azure App Service (Linux).

## Requisitos

- [uv](https://docs.astral.sh/uv/) (instala Python 3.14 automáticamente si no lo tienes)
- Docker (solo para correr la imagen)

## Entornos

Hay dos entornos, `dev` y `prod`. La app lee su configuración **solo de variables de entorno**
(ver [app/config.py](app/config.py)); quien la ejecuta decide qué variables cargar.

| Variable           | dev     | prod    | Descripción                          |
|--------------------|---------|---------|--------------------------------------|
| `PORT`             | `8080`  | `80`    | Puerto en el que escucha el servidor |
| `APP_ENV`          | `dev`   | `prod`  | Nombre del entorno                   |
| `APP_LOG_LEVEL`    | `DEBUG` | `INFO`  | Nivel de logs                        |
| `APP_DOCS_ENABLED` | `true`  | `false` | Expone `/docs` y `/openapi.json`     |

Las plantillas `.env.dev.example` y `.env.prod.example` se suben a git. Las copias reales
(`.env.dev`, `.env.prod`) no, porque ahí podrían terminar secretos:

```bash
cp .env.dev.example .env.dev
cp .env.prod.example .env.prod
```

En Azure no se usan archivos: las variables se configuran como **App Settings** de la Web App
(y los secretos como referencias a Key Vault).

## Desarrollo local

```bash
uv sync
uv run --env-file .env.dev fastapi dev app/main.py
```

- API: http://localhost:8080
- Documentación OpenAPI (Swagger): http://localhost:8080/docs
- Health check: http://localhost:8080/health

## Tests y lint

```bash
uv run pytest
uv run ruff check .
uv run ruff format .
```

`pytest` mide la cobertura de `app/` en cada ejecución y muestra las líneas sin probar
(columna `Missing`). Falla si la cobertura baja del 90% (se ajusta en `pyproject.toml`).
Para verla en el navegador:

```bash
uv run pytest --cov-report=html   # abre htmlcov/index.html
```

## Docker

Se construye **una sola imagen** para ambos entornos; lo que cambia son las variables al ejecutarla.
Por defecto la imagen arranca como prod en el puerto 80.

```bash
docker build -t dp3-appservice-orders .

# dev (puerto 8080)
docker run --rm --env-file .env.dev -p 8080:8080 dp3-appservice-orders

# prod (puerto 80)
docker run --rm --env-file .env.prod -p 80:80 dp3-appservice-orders
```

En App Service configura `WEBSITES_PORT` con el mismo valor que `PORT` (`80` en prod, `8080` en dev).

## Endpoints

| Método | Ruta                      | Descripción          |
|--------|---------------------------|----------------------|
| GET    | `/health`                 | Health check         |
| POST   | `/api/v1/orders`          | Crea una orden       |
| GET    | `/api/v1/orders`          | Lista las órdenes    |
| GET    | `/api/v1/orders/{id}`     | Obtiene una orden    |

Por ahora las órdenes se guardan **en memoria** (se pierden al reiniciar).

## Estructura

El código se organiza **por dominio** (*package by feature*): todo lo de un dominio vive en su
propio paquete, y en la raíz de `app/` solo queda lo transversal.

```
app/
  main.py              # create_app(): arma la app (handlers, routers). Sin lógica de negocio
  config.py            # configuración global (variables de entorno)
  errors.py            # Problem Details (RFC 9457) + DomainError, base de los errores de negocio
  health/
    router.py          # GET /health
  orders/
    router.py          # endpoints HTTP: traducen HTTP ↔ service
    schemas.py         # contrato de la API (Pydantic): OrderCreate, OrderRead
    service.py         # reglas de negocio; no importa FastAPI
    repository.py      # acceso a datos: Protocol + implementación en memoria
    models.py          # cómo se guarda una orden (hoy dataclass; mañana tabla ORM)
    dependencies.py    # inyección: service, validar que la orden exista (404)
    exceptions.py      # errores de negocio (OrderNotFound → 404)
    constants.py       # OrderStatus
tests/                 # sigue la misma estructura que app/
  conftest.py          # fixture `client` con una app nueva por test
  health/
  orders/              # test_router.py (HTTP) y test_service.py (unitarios, sin HTTP)
.env.*.example         # plantillas de variables por entorno
pyproject.toml         # dependencias y configuración de herramientas
uv.lock                # versiones exactas (se commitea)
Dockerfile             # imagen para App Service
```

Reglas:

- Las dependencias van en un sentido: `router → service → repository`.
- El service lanza excepciones de dominio (subclases de `DomainError`); `app/errors.py` las
  convierte en respuestas HTTP. El service nunca usa `HTTPException`.
- Un dominio nuevo (p. ej. `customers/`) es una carpeta hermana de `orders/` con la misma forma,
  y su router se registra en `app/main.py`.
- Los archivos se crean cuando se necesitan: no hay carpetas vacías "por si acaso".
