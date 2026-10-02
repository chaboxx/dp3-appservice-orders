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
  Con `APP_DB_*` configuradas se usan repositorios SQL; sin ellas (tests), repositorios en memoria.

## Stack

| Pieza | Elección |
|---|---|
| Lenguaje | Python **3.14** (`.python-version`) |
| Gestor | **uv** (`pyproject.toml` + `uv.lock`, que se commitea) |
| Web | FastAPI (`fastapi run` / `fastapi dev`) |
| Configuración | pydantic-settings, **solo variables de entorno** con prefijo `APP_` |
| ORM | SQLAlchemy 2.1 (modelos tipados `Mapped[...]`) |
| Driver SQL | **pyodbc** + **Microsoft ODBC Driver 18** (`mssql+pyodbc`). Se dejó mssql-python porque no soporta Always Encrypted |
| JWT | PyJWT[crypto] (`PyJWKClient` con caché de claves) |
| Tests / lint | pytest + pytest-cov (mínimo **90%**), ruff (line-length 100) |
| Imagen | `python:3.14-slim` (Debian 13) + `msodbcsql18` del repo de Microsoft, `libcurl4t64` (proveedor de Key Vault) y `libgssapi-krb5-2` |

## Estructura: package by feature

Cada dominio vive en su paquete con la misma forma; en la raíz de `app/` solo hay cosas
transversales. **No crear carpetas o archivos vacíos "por si acaso"**: se agregan cuando hacen falta.

```
app/
  main.py          create_app(): arma la app (logging, handlers, lifespan, routers). Sin lógica
  config.py        Settings global (APP_ENV, APP_LOG_LEVEL, APP_DOCS_ENABLED, APP_DB_*)
  database.py      Base ORM, TimestampMixin, DateTime2, utcnow(), build_engine(),
                   build_session_factory(), check_database(), DbSession (transacción por request)
  errors.py        Problem Details (RFC 9457) + DomainError (base de errores de negocio)
  auth/            ¿el token es válido? ¿quién es? (NO usa la base de datos)
    config.py        AuthSettings: APP_AUTH_ISSUER / APP_AUTH_JWKS_URI / APP_AUTH_AUDIENCE
    validator.py     TokenValidator (un solo emisor) + build_token_validator()
    dependencies.py  CurrentPrincipal, require_scope("...")
    schemas.py       Principal (tid, oid, email, name, given_name, family_name, city, scopes)
    exceptions.py    NotAuthenticated / InvalidToken (401) y Forbidden (403)
  users/           alta automática (service), CurrentUser (dependencies), GET /me, tabla Users
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
  (`db_engine`, `session_factory`, `token_validator` y los repositorios en memoria
  `order_repository`, `product_repository`, `user_repository`), nunca como globales de módulo:
  así cada test arranca limpio y se pueden reemplazar.
- Repositorios: un `Protocol` + versión en memoria + versión SQL. El `get_*` de `dependencies.py`
  elige: si `DbSession` es `None` (sin base) usa el de memoria de `app.state`; si no, crea el SQL
  con la sesión del request.
- **Una transacción por request** (`DbSession`, `Depends(..., scope="function")`): commit al
  terminar el endpoint y **antes** de enviar la respuesta; rollback ante cualquier excepción,
  incluidos los `DomainError`. Por eso el service puede lanzar un error a mitad de camino (p. ej.
  después de descontar stock) sin dejar datos a medias.
- Rutas versionadas con prefijo `/api/v1` al registrar el router (no con carpetas `v1/`).
- Un dominio nuevo = carpeta hermana de `orders/` con la misma forma, registrada en `main.py`.

## Endpoints actuales

| Método | Ruta | Auth | Notas |
|---|---|---|---|
| GET | `/` | no | `{"message", "env"}` |
| GET | `/health` | no | Lo usa el probe de App Service; debe seguir público |
| POST | `/api/v1/orders` | token + `Orders.ReadWrite` | 201. Body `{payment_type?, items: [{product_id, quantity}]}` |
| GET | `/api/v1/orders?page=&page_size=` | token + `Orders.ReadWrite` | `{items, page, page_size, total}`, más nueva primero |
| PATCH | `/api/v1/orders/{id}` | token + `Orders.ReadWrite` | `{payment_type?, status?: "cancelled"}` |
| DELETE | `/api/v1/orders/{id}` | token + `Orders.ReadWrite` | 204, soft delete |
| GET | `/api/v1/me` | **sí** (token válido) | Usuario de la base (`id`) + datos del token; no exige scope |

`/docs`, `/redoc` y `/openapi.json` solo existen con `APP_DOCS_ENABLED=true` (dev).
`GET /api/v1/orders/{id}` se quitó a propósito: se agregará cuando se pida.

### Reglas de órdenes

- El dueño es `Users.id` del usuario del token. Una orden de otro usuario o borrada responde
  **404** (no se revela que existe).
- **Crear**: rechaza campos fuera del contrato (`user_id`, `status`, `unit_price`, `total` → 422).
  1–50 ítems sin productos repetidos, `quantity` > 0. `unit_price` sale de `Products.price` y
  `total = Σ unit_price × quantity` (debe caber en `DECIMAL(12,2)`). Producto inexistente → 422;
  sin stock → 409. El stock se descuenta con un `UPDATE ... WHERE stock >= q` (atómico).
- **PATCH**: solo órdenes `pending` (si no, 409). Se puede cambiar `payment_type` y cancelar;
  cancelar devuelve el stock. `confirmed` queda para un futuro flujo de pago.
- **DELETE**: llena `deleted_at`. `pending` se cancela primero (devuelve stock); `cancelled` se
  borra tal cual; `confirmed` → 409.
- PATCH y DELETE leen la orden con `WITH (UPDLOCK, ROWLOCK)` para que dos requests simultáneos
  no devuelvan el stock dos veces.

### Alta automática de usuarios (`CurrentUser`)

En cada request autenticado que use `CurrentUser` (órdenes y `/me`): busca `Users` por
(`tid`, `oid`); si no existe lo crea (`email`, `given_name` → `first_name`, `family_name` →
`last_name`, `city`); si existe, rechaza inactivos (403), sincroniza email/nombres/ciudad y actualiza
`last_login_at` como máximo cada 15 minutos. Sin claim `email` → 403 (`Users.email` es NOT NULL).
Dos primeros requests simultáneos: el segundo choca con `ux_users_entra_identity`, se captura en un
savepoint y se devuelve el usuario ya creado.

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
| `APP_DB_AUTHENTICATION` | Keyword `Authentication` de ODBC. `ActiveDirectoryMsi` (default; `ActiveDirectoryMSI` también vale). Ya no hay modo local: la base solo funciona dentro de Azure |
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
- Migraciones en `migrations/`, numeradas y aplicadas **a mano por el usuario** (Query Editor):
  `01-dp3ddl.sql` (esquema), `02-orders-soft-delete.sql` (`Orders.deleted_at`),
  `03-seed-products.sql` (productos de prueba, opcional), `04-always-encrypted-keys.sql` (CMK,
  CEK y permisos), `05-users-names-encrypted.sql` (cifra los nombres) y `06-users-city.sql`
  (`Users.city`, legible; la exige la app desde **0.7.0**: sin ella falla con `Invalid column
  name 'city'`). Todas aplicadas. Un cambio de esquema = un archivo nuevo, no editar los ya
  aplicados, y se aplica **antes** de desplegar la versión que lo usa.
- Scripts de datos para el ETL (opcionales, no cambian el esquema): `07-seed-synthetic-orders.sql`
  (12 meses de órdenes con estacionalidad; clientes del tenant ficticio
  `DA7A0000-5EED-4000-8000-000000000000`, email `@dp3-synthetic.test`, sin nombres; incluye cómo
  borrarlos), `08-simulate-scd-changes.sql` (cambia ciudad, precio y categoría con `updated_at`
  para probar el SCD2; repetible, después de cada carga) y `09-synthetic-names-ssms.sql` (nombres
  cifrados para esos clientes, con datos "sucios" a propósito; **solo SSMS** con Always Encrypted
  y parametrización: un `DECLARE ... = N'literal'` por fila; archivo generado).
- Fechas: `utcnow()` (UTC **sin** zona horaria, como `DATETIME2`); no mezclar con fechas aware.
- `Product`, `Order` y `OrderItem` viven en `app/orders/models.py`; `User` en `app/users/models.py`.
- IDs con `NEWSEQUENTIALID()` y timestamps con `SYSUTCDATETIME()` los genera la base; el
  repositorio en memoria los simula.
- Conexión sin contraseña: la managed identity **system-assigned** de la Web App tiene un usuario
  en la base (`CREATE USER [dp3-appservice-orders] FROM EXTERNAL PROVIDER` + `db_datareader` /
  `db_datawriter`).
- Al arrancar, `check_database()` hace `SELECT 1` **en un hilo en segundo plano** y escribe en los
  logs `Database connection OK`, `FAILED` (con el error completo) o `not configured`. Ojo:
  `SELECT 1` prueba la conexión, **no** el descifrado (eso se ve al leer `Users`).

### Lo que necesita saber el ETL (ADF + Databricks, proyecto aparte)

- Carga incremental por **`updated_at`** (UTC): lo pone el ORM (`onupdate`) en cada cambio de la
  app; un `UPDATE` a mano tiene que ponerlo él mismo o la carga no lo ve. Los borrados de órdenes
  son soft delete (`deleted_at` + `updated_at`), así que llegan como cambios; un borrado físico no.
  Los ítems no cambian después de crear la orden.
- Dimensiones: `Users.city` (legible) es el atributo SCD2 de clientes; `Products.price` y
  `category` el de productos. Los nombres son SCD1 (se sobrescriben desde el token).
- `first_name` / `last_name` llegan como **binario** salvo que el linked service de ADF tenga
  Always Encrypted (managed identity). Para eso la identity de ADF necesita usuario en la base +
  `db_datareader` + `VIEW ANY COLUMN … DEFINITION`, *Key Vault Crypto User* y un managed private
  endpoint a `dp3-kv-crypto` (firewall `Deny`). Descifrados quedan **en claro en el lake**:
  protegerlos ahí (p. ej. column masks de Unity Catalog) o no descifrarlos si no hacen falta.
- Los datos sintéticos (07–09) se distinguen por `entra_tenant_id = DA7A0000-5EED-4000-8000-000000000000`.

### Always Encrypted (`Users.first_name`, `Users.last_name`)

- Objetivo: que quien consulte la base sin acceso a la llave (Query Editor, admins de SQL) vea los
  nombres como binario. `Users.email` queda **legible** a propósito (se consulta en SQL).
- Cifrado **aleatorizado**, sin enclaves: sobre esas columnas no hay `WHERE`, `ORDER BY`, `LIKE`,
  índices ni estadísticas. La app no los necesita (busca por `tid` + `oid`). Collation
  `Latin1_General_BIN2` solo en esas dos columnas (Always Encrypted la exige; el modelo la refleja).
- Llaves: CMK `CMK_Orders` → RSA 3072 `orders-pii-kek` en `dp3-kv-crypto` (Standard, RBAC; la
  llave permite `wrapKey/unwrapKey/encrypt/decrypt/sign/verify`); CEK `CEK_UsersNames` (AES-256,
  guardada cifrada en la base). La identity de la Web App tiene *Key Vault Crypto User* sobre el
  vault y `VIEW ANY COLUMN … DEFINITION` en la base. Sin enclaves (`allow_enclave_computations = 0`),
  aunque la base tiene el enclave VBS habilitado.
- Cómo se cifró: las dos columnas se **recrearon vacías y cifradas** (migrations/05) en vez de
  cifrar los datos con SSMS, porque los nombres salen del token de Entra: `_sync_profile` los
  vuelve a escribir (cifrados) en el siguiente request de cada usuario.
- Todo lo hace el driver (`ColumnEncryption=Enabled`, `KeyStoreAuthentication=KeyVaultManagedIdentity`):
  el código sigue usando `str`. Reglas: valores siempre como **parámetros** (nunca literales en
  SQL) y `hide_parameters=True` en el engine para que los nombres no lleguen a los logs.
- Lo que necesita la llave (crear una CEK, cifrar o descifrar columnas con datos) se hace con
  **SSMS** o PowerShell (`SqlServer`), nunca con el Query Editor. Lo que es solo metadato (CMK,
  `CREATE TABLE … ENCRYPTED WITH` vacío, permisos) sí va en el Query Editor.
- La llave vence el **2028-10-01**: rotarla antes (nueva versión + re-proteger la CEK con SSMS).

## Infraestructura relevante (Azure)

- Web App `dp3-appservice-orders` (RG `dp3`, Central US, plan Basic o superior, modelo
  *sitecontainers*), imagen `159123007/dp3-appservice-orders:latest` en Docker Hub.
- VNet integration (solo **salida**) con `dp3-vnet-orders/appservice` (la VNet está en el RG
  `data`), *route all* activo. Private endpoint de SQL en `dp3-vnet-orders/default` (10.0.0.4),
  zona `privatelink.database.windows.net` vinculada a la VNet. Sin NSGs por ahora.
- Servidor `dp3-mssql-orders-server`, base `dp3-mssql-orders`, política de conexión **Redirect**
  (configurada explícitamente después de crear el private endpoint). Acceso público habilitado
  solo para la IP del dueño (Query Editor / SSMS).
- Key Vault `dp3-kv-crypto` (RG `dp3`, Standard, RBAC, firewall `Deny` salvo la IP del dueño):
  private endpoint `dp3-privateendpoint-kvsecret` en `dp3-vnet-common` (10.4.0.4). La zona
  `privatelink.vaultcore.azure.net` (RG `dp3`) está vinculada a `dp3-vnet-common` **y** a
  `dp3-vnet-orders` (`link-dp3-vnet-orders`); las dos VNets tienen peering (`common-orders`).
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
4. **El driver necesita paquetes del sistema** en la imagen slim (hoy `msodbcsql18` del repo de
   Microsoft). El proveedor de Key Vault de Always Encrypted además necesita `libcurl`, que **no**
   se instala como dependencia del driver.
5. Diagnóstico de red desde dentro del App Service: consola Kudu (`getent hosts`, prueba TCP con
   `bash -c echo>/dev/tcp/IP/PUERTO`) o el *Network troubleshooter* del portal.
6. En Git Bash, rutas que empiezan con `/` se reescriben (`C:/Program Files/Git/...`): usar
   `MSYS_NO_PATHCONV=1` con `docker run ... /app/...` o `az --ids /subscriptions/...`.
7. **`with_for_update()` no hace nada en SQL Server** (SQLAlchemy lo ignora en el dialecto
   mssql). Para bloquear filas usar `.with_hint(Model, "WITH (UPDLOCK, ROWLOCK)", dialect_name="mssql")`.
8. En Windows el reloj puede devolver el mismo valor en llamadas seguidas: en tests que dependen
   del orden por `created_at`, asignar fechas explícitas.
9. **SQLAlchemy + pyodbc:** el parámetro `authentication` va en **minúsculas** en la URL; si no,
   SQLAlchemy agrega `Trusted_Connection=Yes`, que choca con la managed identity.
10. **La app llega a Key Vault por el private endpoint** (`10.4.0.4`, en `dp3-vnet-common`): la
    zona `privatelink.vaultcore.azure.net` tiene que estar vinculada también a `dp3-vnet-orders`,
    o la app resuelve la IP pública y el firewall del vault la rechaza. Síntoma: `CE258 Error
    retrieving key information` al escribir o leer nombres. Ojo: la prueba TCP a 443 **pasa igual**
    contra la IP pública; lo que prueba la ruta correcta es `getent hosts dp3-kv-crypto.vault.azure.net`
    → `10.4.0.4`.
11. **mssql-python no soporta Always Encrypted** (1.15.0): su lista de parámetros de conexión
    permitidos descarta `ColumnEncryption` y `KeyStoreAuthentication` sin dar error.
12. **`NEWID()` dentro de `CHOOSE`/`CASE` se recalcula en cada rama** (y puede no caer en ninguna
    y devolver NULL). En scripts con azar, guardar primero el número en una tabla temporal y
    después usarlo en el `CASE`.
13. **Escribir columnas cifradas en lote:** SSMS solo cifra variables `DECLARE @x tipo = N'literal'`
    (misma línea, un literal, mismo tipo que la columna); no sirve `UPDATE … FROM otra_tabla`
    porque SQL Server no tiene la llave. Para muchas filas: un bloque por fila separado con `GO`
    (ver migrations/09).

## Tests

- `uv run pytest` (cobertura incluida, falla bajo 90%), `uv run ruff check .`, `uv run ruff format .`.
- Tests **simples y legibles**: no un test por cada caso posible; preferir `parametrize` cuando hay
  varias variantes del mismo comportamiento.
- Auth sin Entra ni red: `tests/auth/tokens.py` firma tokens con una clave RSA local
  (`make_token(**claims)`, `make_validator()`); en tests HTTP se asigna
  `app.state.token_validator = make_validator()`.
- Cada test usa una app nueva (`create_app(Settings())`) para no compartir estado. Los productos
  se cargan con `app.state.product_repository.add(Product(...))`.
- Los repositorios SQL **no tienen tests automáticos** todavía (la cobertura queda >90% sin
  ellos). Siguiente paso posible: tests de integración contra SQL Server en Docker.

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

- Key Vault `dp3-kv-crypto`: activar la **protección contra purga** (sigue apagada; irreversible,
  evita perder la llave y con ella los nombres). Opcional: limitar el rol *Crypto User* de la app
  a la llave `orders-pii-kek` en vez de a todo el vault.
- Rotar `orders-pii-kek` antes del **2028-10-01** (vence ese día).
- TDE con llave propia (CMK) en el servidor SQL: hoy es `ServiceManaged`. Requiere protección
  contra purga en el vault, identity en el servidor con *Key Vault Crypto Service Encryption User*
  y permitir "trusted Microsoft services" en el firewall del vault (hoy `bypass: None`). Usar una
  llave aparte de `orders-pii-kek`.
- `GET /api/v1/orders/{id}`; CRUD de productos; flujo de pago que pase órdenes a `confirmed`.
- Tests de integración de los repositorios SQL (SQL Server en Docker).
- CORS para `dp3-web-store` (solo su origen) cuando exista la SPA.
- Agregar OAuth 2.0 a la colección de Postman (Bruno es el cliente de pruebas actual).
- Seguridad: deshabilitar acceso público de SQL (`--enable-public-network false`) cuando ya no se
  use el Query Editor; en la Web App (HTTPS only y TLS 1.2 ya activos) falta apagar FTP/basic auth
  (hoy `FtpsOnly`) y restringir el sitio SCM.
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
