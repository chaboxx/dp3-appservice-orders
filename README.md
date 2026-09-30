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
| `APP_DB_SERVER`    | vacío   | `dp3-mssql-orders-server.database.windows.net` | Servidor de Azure SQL |
| `APP_DB_NAME`      | vacío   | `dp3-mssql-orders` | Base de datos                   |
| `APP_DB_AUTHENTICATION` | `ActiveDirectoryDefault` | `ActiveDirectoryMSI` | Autenticación con Entra (sin contraseña) |
| `APP_AUTH_*`       |         |         | Tenant de Entra External ID en el que confía la API (ver abajo) |

Las plantillas `.env.dev.example` y `.env.prod.example` se suben a git. Las copias reales
(`.env.dev`, `.env.prod`) no, porque ahí podrían terminar secretos:

```bash
cp .env.dev.example .env.dev
cp .env.prod.example .env.prod
```

### Base de datos (Azure SQL)

La app se conecta sin contraseña: en Azure con la **managed identity** de la Web App
(`ActiveDirectoryMSI`) y en local con tu sesión de `az login` (`ActiveDirectoryDefault`).
Al arrancar prueba la conexión (`SELECT 1`) y deja el resultado en los logs:

```
INFO:app.database:Database connection OK (mssql+mssqlpython://...)
ERROR:app.database:Database connection FAILED (...)      # + el error completo del driver
WARNING:app.database:Database not configured (...)        # sin APP_DB_SERVER / APP_DB_NAME
```

Si falla, la app **no se detiene**: los endpoints todavía no usan la base de datos.

### Autenticación (Entra ID / Entra External ID)

La API es pública y valida access tokens (JWT) de **Entra External ID** (el tenant externo de
clientes). Se configura con 3 variables, ninguna es secreta:

| Variable                          | De dónde sale                                                  |
|-----------------------------------|----------------------------------------------------------------|
| `APP_AUTH_ISSUER`                 | campo `issuer` del `.well-known/openid-configuration` del tenant |
| `APP_AUTH_JWKS_URI`               | campo `jwks_uri` del mismo documento                           |
| `APP_AUTH_AUDIENCE`               | client ID de la app registration de la API                     |

Sin configurar, la API arranca pero rechaza todos los tokens (401). Si faltan algunas, no arranca.

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
| GET    | `/api/v1/me`              | Usuario autenticado (requiere token de Entra External ID) |

Por ahora las órdenes se guardan **en memoria** (se pierden al reiniciar).

## Estructura

El código se organiza **por dominio** (*package by feature*): todo lo de un dominio vive en su
propio paquete, y en la raíz de `app/` solo queda lo transversal.

```
app/
  main.py              # create_app(): arma la app (handlers, routers). Sin lógica de negocio
  config.py            # configuración global (variables de entorno)
  errors.py            # Problem Details (RFC 9457) + DomainError, base de los errores de negocio
  database.py          # Base de SQLAlchemy + created_at/updated_at comunes
  auth/                # ¿el token es válido? ¿quién es según Entra? (no usa la base de datos)
    config.py          # tenant de Entra External ID (APP_AUTH_*)
    validator.py       # TokenValidator: firma (JWKS), iss, aud, exp, tid/oid
    dependencies.py    # CurrentPrincipal, require_scope(...)
    schemas.py         # Principal: tenant_id, object_id, email, name, scopes
    exceptions.py      # 401 (WWW-Authenticate: Bearer) y 403
  health/
    router.py          # GET /health
  orders/
    router.py          # endpoints HTTP: traducen HTTP ↔ service
    schemas.py         # contrato de la API (Pydantic): OrderCreate, OrderRead
    service.py         # reglas de negocio; no importa FastAPI
    repository.py      # acceso a datos: Protocol + implementación en memoria
    models.py          # tablas ORM Products, Orders y OrderItem (reflejan el DDL)
    dependencies.py    # inyección: service, validar que la orden exista (404)
    exceptions.py      # errores de negocio (OrderNotFound → 404)
    constants.py       # OrderStatus
  users/
    router.py          # GET /me: el usuario del token (protegido con CurrentPrincipal)
    schemas.py         # MeRead
    models.py          # tabla ORM Users (vinculada a Entra por tenant id + object id)
tests/                 # sigue la misma estructura que app/
  conftest.py          # fixture `client` con una app nueva por test
  test_database.py     # los modelos ORM siguen alineados con el DDL
  auth/                # tokens firmados con una clave RSA local: sin Entra ni red
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
