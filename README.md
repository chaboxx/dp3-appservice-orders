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

## Estructura

```
app/config.py       # configuración (variables de entorno)
app/main.py         # aplicación FastAPI
tests/              # tests con pytest
.env.*.example      # plantillas de variables por entorno
pyproject.toml      # dependencias y configuración de herramientas
uv.lock             # versiones exactas (se commitea)
Dockerfile          # imagen para App Service
```
