# AGENTS.md — dp3-appservice-orders

Guía para agentes (y personas) que trabajen en este repositorio. Explica qué es el proyecto,
cómo está organizado, las decisiones ya tomadas y por qué, y las reglas para trabajar aquí.
Los comandos de uso diario están en [README.md](README.md).

## Qué es

API REST de **órdenes** de un e-commerce, hecha con **FastAPI**. Es una pieza del proyecto
**DP3** (curso/laboratorio en Azure) y se despliega como **contenedor en Azure App Service
(Linux)**. Es una API **pública**: la consumen clientes finales desde una SPA (`dp3-web-store`,
todavía no existe) y se prueba con Bruno/Postman.

- Autenticación: **solo** access tokens de **Microsoft Entra External ID** (tenant externo de
  clientes). No se aceptan tokens del tenant workforce (staff); esa opción se descartó.
- Datos: **Azure SQL** (privada, vía private endpoint) con **managed identity**, sin contraseñas.
  Hoy la app solo verifica la conexión al arrancar; las órdenes todavía viven **en memoria**.

## Stack

| Pieza | Elección |
|---|---|
| Lenguaje | Python **3.14** (`.python-version`) |
| Gestor | **uv** (`pyproject.toml` + `uv.lock`, que se commitea) |
| Web | FastAPI (`fastapi run` / `fastapi dev`) |
| Configuración | pydantic-settings, **solo variables de entorno** con prefijo `APP_` |
| ORM | SQLAlchemy 2.1 (modelos tipados `Mapped[...]`) |
| Driver SQL | **mssql-python** (driver oficial de Microsoft; ODBC incluido en el paquete) |
| JWT | PyJWT[crypto] (`PyJWKClient` con caché de claves) |
| Tests / lint | pytest + pytest-cov (mínimo **90%**), ruff (line-length 100) |
| Imagen | `python:3.14-slim` + libs del driver (`libltdl7`, `libkrb5-3`, `libgssapi-krb5-2`) |

## Estructura: package by feature

Cada dominio vive en su paquete con la misma forma; en la raíz de `app/` solo hay cosas
transversales. **No crear carpetas o archivos vacíos "por si acaso"**: se agregan cuando hacen falta.

```
app/
  main.py          create_app(): arma la app (logging, handlers, lifespan, routers). Sin lógica
  config.py        Settings global (APP_ENV, APP_LOG_LEVEL, APP_DOCS_ENABLED, APP_DB_*)
  database.py      Base ORM, TimestampMixin, DateTime2, build_engine(), check_database()
  errors.py        Problem Details (RFC 9457) + DomainError (base de errores de negocio)
  auth/            ¿el token es válido? ¿quién es? (NO usa la base de datos)
    config.py        AuthSettings: APP_AUTH_ISSUER / APP_AUTH_JWKS_URI / APP_AUTH_AUDIENCE
    validator.py     TokenValidator (un solo emisor) + build_token_validator()
    dependencies.py  CurrentPrincipal, require_scope("...")
    schemas.py       Principal (tid, oid, email, name, given_name, family_name, city, scopes)
    exceptions.py    NotAuthenticated / InvalidToken (401) y Forbidden (403)
  users/           router.py (GET /me), schemas.py (MeRead), models.py (tabla Users)
  orders/          router, schemas, service, repository, models, dependencies, exceptions, constants
  health/          router.py (GET /health)
tests/             misma estructura que app/ (tests/auth, tests/orders, tests/users, ...)
postman/           colección de Postman (sin OAuth todavía; ver "Pendiente")
```

### Reglas de la arquitectura

- Dependencias en un solo sentido: `router → service → repository`. El **service no importa
  FastAPI** ni usa `HTTPException`: lanza subclases de `DomainError` y `app/errors.py` las
  traduce a HTTP (Problem Details, con `headers` si hace falta, p. ej. `WWW-Authenticate`).
- `schemas.py` (Pydantic, contrato público) está separado de `models.py` (ORM).
- Inyección de dependencias con `Depends` en `dependencies.py` de cada módulo. Los objetos
  compartidos se crean **una vez por app** en `create_app` y se guardan en `app.state`
  (`order_repository`, `db_engine`, `token_validator`), nunca como globales de módulo: así cada
  test arranca limpio y se pueden reemplazar.
- Rutas versionadas con prefijo `/api/v1` al registrar el router (no con carpetas `v1/`).
- Un dominio nuevo = carpeta hermana de `orders/` con la misma forma, registrada en `main.py`.

## Endpoints actuales

| Método | Ruta | Auth | Notas |
|---|---|---|---|
| GET | `/` | no | `{"message", "env"}` |
| GET | `/health` | no | Lo usa el probe de App Service; debe seguir público |
| POST | `/api/v1/orders` | **no (pendiente)** | Hoy recibe `user_id` en el body |
| GET | `/api/v1/orders` | **no (pendiente)** | Lista **todas** las órdenes |
| GET | `/api/v1/orders/{id}` | **no (pendiente)** | 404 Problem Details si no existe |
| GET | `/api/v1/me` | **sí** (token válido) | Datos del usuario desde el token; no exige scope |

`/docs`, `/redoc` y `/openapi.json` solo existen con `APP_DOCS_ENABLED=true` (dev).

## Configuración (variables de entorno)

La app **no lee archivos `.env`**: quien la ejecuta carga las variables (`uv run --env-file`,
`docker --env-file`, o App Settings en Azure). Las plantillas `.env.*.example` se commitean; los
`.env.dev` / `.env.prod` reales no.

| Variable | Uso |
|---|---|
| `PORT` | Puerto de `fastapi run` (80 en prod, 8080 en dev) |
| `APP_ENV` | `dev` \| `prod` |
| `APP_LOG_LEVEL` | Nivel de los logs de `app.*` (las librerías van en INFO; `azure.*` en WARNING) |
| `APP_DOCS_ENABLED` | Expone `/docs` |
| `APP_DB_SERVER`, `APP_DB_NAME` | Azure SQL. Sin ellas la app arranca sin base (solo avisa en logs) |
| `APP_DB_AUTHENTICATION` | `ActiveDirectoryMSI` en Azure (default), `ActiveDirectoryDefault` o `ActiveDirectoryInteractive` en local |
| `APP_AUTH_ISSUER` | `issuer` del `.well-known/openid-configuration` del tenant externo (copiar exacto; usa el tenant ID como subdominio) |
| `APP_AUTH_JWKS_URI` | `jwks_uri` del mismo documento |
| `APP_AUTH_AUDIENCE` | Client ID de la app registration de la **API** (`orders`) |

Ninguna es secreta. Sin `APP_AUTH_*` la app arranca pero responde 401 a todo token; con una
configuración **incompleta** no arranca (falla rápido a propósito).

## Autenticación (Entra External ID)

- El login lo muestra Microsoft (user flow de sign-up/sign-in); **la API no tiene pantalla de
  login**: solo valida access tokens.
- `TokenValidator` verifica la firma RS256 con las claves públicas (JWKS, en caché) y los claims
  `iss`, `aud`, `exp` y la presencia de `tid` y `oid`. No llama a Entra por request ni usa secretos.
- El usuario se identifica por **`oid` (+ `tid`)**, nunca por email ni nombre: borrar y volver a
  registrar un usuario, o entrar con email y luego con Google, produce **otro `oid`**.
- App registrations en el tenant externo (se necesitan **dos tipos**):
  - **`orders`** (la API): *Expose an API* con el scope **`Orders.ReadWrite`**, manifest con
    `requestedAccessTokenVersion: 2`, claims opcionales de **access token** (`email`, `given_name`,
    `family_name`) y claim mapeado **`city`** (`user.city`, con `acceptMappedClaims: true`).
    Los claims del access token se configuran **en la API** (es el `aud`). No lleva redirect URI.
  - **Clientes** (uno por cliente): `dp3-bruno` para pruebas (plataforma *Mobile and desktop*,
    redirect `https://oauth.usebruno.com/callback`), y en el futuro `dp3-web-store` (plataforma
    *SPA*). Cada uno con el permiso delegado `Orders.ReadWrite` y **admin consent**.
- Pedir un token en Bruno/Postman: Authorization Code + **PKCE**, sin client secret, scope
  `api://<client-id-de-orders>/Orders.ReadWrite openid profile offline_access`, endpoints
  `https://<subdominio>.ciamlogin.com/<tenant-id>/oauth2/v2.0/{authorize,token}`.
- Un **ID token** (p. ej. el de "Run user flow"/quickstart, lleva `nonce` y no `scp`) **no** sirve
  para la API y se rechaza (falta `oid`/`aud` incorrecto). Es el comportamiento correcto.
- Entra manda `name: "unknown"` cuando el usuario no tiene Display Name; el validador lo
  reemplaza por `given_name + family_name` (o `null` si tampoco existen).

## Base de datos (Azure SQL)

- El DDL de SQL Server es la **fuente de verdad**; los modelos ORM lo reflejan (nombres de tablas
  `Users`, `Products`, `Orders`, `OrderItem`, constraints e índices) pero **no crean tablas**.
  `tests/test_database.py` verifica que sigan alineados (incluido `DATETIME2`).
- `Product`, `Order` y `OrderItem` viven en `app/orders/models.py`; `User` en `app/users/models.py`.
- IDs con `NEWSEQUENTIALID()` y timestamps con `SYSUTCDATETIME()` los genera la base; el
  repositorio en memoria los simula.
- Conexión sin contraseña: la managed identity **system-assigned** de la Web App tiene un usuario
  en la base (`CREATE USER [dp3-appservice-orders] FROM EXTERNAL PROVIDER` + `db_datareader` /
  `db_datawriter`).
- Al arrancar, `check_database()` hace `SELECT 1` **en un hilo en segundo plano** y escribe en los
  logs `Database connection OK`, `FAILED` (con el error completo) o `not configured`.

## Infraestructura relevante (Azure)

- Web App `dp3-appservice-orders` (RG `dp3`, Central US, plan Basic o superior, modelo
  *sitecontainers*), imagen `159123007/dp3-appservice-orders:latest` en Docker Hub.
- VNet integration (solo **salida**) con `dp3-vnet-orders/appservice` (la VNet está en el RG
  `data`), *route all* activo. Private endpoint de SQL en `dp3-vnet-orders/default` (10.0.0.4),
  zona `privatelink.database.windows.net` vinculada a la VNet. Sin NSGs por ahora.
- Servidor `dp3-mssql-orders-server`, base `dp3-mssql-orders`, política de conexión **Redirect**
  (configurada explícitamente después de crear el private endpoint).
- La entrada a la API es pública (front-ends de App Service); se protege con HTTPS + JWT, no con NSG.

## Lecciones aprendidas (no repetir)

1. **Logs a stdout.** El log stream de App Service muestra stdout, no stderr; por eso
   `logging.basicConfig(stream=sys.stdout)` y `PYTHONUNBUFFERED=1` en el Dockerfile.
2. **Nada lento antes de abrir el puerto.** Si el arranque espera a la base y la red no responde,
   el warmup probe de App Service mata el contenedor. Las verificaciones van en segundo plano.
3. **Política de conexión de SQL con private endpoint:** no dejarla en `Default`. Elegir
   `Redirect` (recomendada; requiere puertos 1433–65535 entre VNets) o `Proxy` (solo 1433) **y
   aplicarla después de crear el private endpoint**. Con `Default` daba `TCP Provider: Timeout
   error [258]`. (El rango 11000–11999 es para el endpoint público, no para private endpoint.)
4. **El driver necesita libs del sistema** en la imagen slim; sin ellas: `Failed to load the driver`.
5. Diagnóstico de red desde dentro del App Service: consola Kudu (`getent hosts`, prueba TCP con
   `bash -c echo>/dev/tcp/IP/PUERTO`) o el *Network troubleshooter* del portal.
6. En Git Bash, rutas que empiezan con `/` se reescriben (`C:/Program Files/Git/...`): usar
   `MSYS_NO_PATHCONV=1` con `docker run ... /app/...` o `az --ids /subscriptions/...`.

## Tests

- `uv run pytest` (cobertura incluida, falla bajo 90%), `uv run ruff check .`, `uv run ruff format .`.
- Tests **simples y legibles**: no un test por cada caso posible; preferir `parametrize` cuando hay
  varias variantes del mismo comportamiento.
- Auth sin Entra ni red: `tests/auth/tokens.py` firma tokens con una clave RSA local
  (`make_token(**claims)`, `make_validator()`); en tests HTTP se asigna
  `app.state.token_validator = make_validator()`.
- Cada test usa una app nueva (`create_app(Settings())`) para no compartir estado.

## Build, versión y despliegue

1. Tests + ruff en verde.
2. Subir `version` en `pyproject.toml` **y** en `FastAPI(version=...)` de `app/main.py`; `uv lock`.
3. Commit (mensaje en inglés, con línea `Co-Authored-By` cuando lo genera un agente) y tag
   anotado `vX.Y.Z`.
4. `docker build -t 159123007/dp3-appservice-orders:X.Y.Z -t 159123007/dp3-appservice-orders:latest .`
   desde el commit etiquetado (árbol limpio), prueba de humo del contenedor (`/health`, `/me` → 401),
   y `docker push` de ambos tags.
5. `git push --follow-tags origin main` (remoto: `git@github.com:chaboxx/dp3-appservice-orders.git`).
   El usuario despliega reiniciando la Web App (usa `latest`).

## Pendiente (siguiente trabajo)

- Proteger `orders` con `require_scope("Orders.ReadWrite")`, sacar `user_id` del token (hoy viene
  en el body) y filtrar por dueño (orden ajena → 404). Decidir: `user_id` = `oid` (simple) o
  `Users.id` con alta automática en el primer request (upsert por `tid`+`oid`).
- Repositorios SQL reales (`SqlOrderRepository`, usuarios) en lugar de los de memoria.
- CORS para `dp3-web-store` (solo su origen) cuando exista la SPA.
- Agregar OAuth 2.0 a la colección de Postman (Bruno es el cliente de pruebas actual).
- Seguridad: deshabilitar acceso público de SQL (`--enable-public-network false`) cuando ya no se
  use el Query Editor; HTTPS only, TLS 1.2, FTP/basic auth off y restringir el sitio SCM.
- Opcional: `ui_locales=es-ES` desde los clientes; branding y Google como proveedor se configuran
  solo en Entra (no tocan el código).

## Cómo trabajar con el dueño del proyecto

- Responder en **español**; explicar con ejemplos simples y cuadros cuando ayude.
- **Azure: solo diagnóstico de lectura.** El `az` local está en el tenant de Cibertec; se pueden
  correr comandos `show`/`list` para depurar, pero **cualquier cambio** (create/update/delete/
  restart) se entrega como comandos para que el usuario los ejecute.
- Hacer commits, tags y push de imágenes **solo cuando se pidan**; antes de cambiar algo que se
  pidió "revisar", explicar primero.
- No agregar archivos o cambios fuera de lo pedido sin justificarlos; si un cambio colateral es
  necesario (p. ej. `uv.lock`, `.gitignore`), decir por qué.
- Verificar en la documentación oficial (Microsoft Learn) antes de afirmar detalles de Azure/Entra.
