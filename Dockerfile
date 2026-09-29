FROM python:3.14-slim

# uv como binario, copiado desde su imagen oficial
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Primero solo las dependencias: esta capa se cachea mientras no cambie el lock
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY app ./app

# No correr como root
RUN useradd --create-home appuser
USER appuser

# Una sola imagen para ambos entornos: el puerto sale de la variable PORT.
# Por defecto prod (80); dev lo cambia a 8080 con su archivo de variables.
ENV PORT=80 \
    APP_ENV=prod \
    APP_DOCS_ENABLED=false
EXPOSE 80 8080

CMD ["/app/.venv/bin/fastapi", "run", "app/main.py"]
