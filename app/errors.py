"""Manejo global de errores con el formato Problem Details (RFC 9457).

Todas las respuestas de error tienen la misma forma:

    {"type": "about:blank", "title": "Not Found", "status": 404,
     "detail": "...", "instance": "/ruta"}
"""

import logging
from http import HTTPStatus

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException

logger = logging.getLogger(__name__)


def problem(
    request: Request,
    status: int,
    detail: str,
    headers: dict[str, str] | None = None,
    **extra: object,
) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        media_type="application/problem+json",
        headers=headers,
        content={
            "type": "about:blank",
            "title": HTTPStatus(status).phrase,
            "status": status,
            "detail": detail,
            "instance": request.url.path,
            **extra,
        },
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Errores controlados: los que lanzamos con `raise HTTPException(...)` (y los 404/405)."""
    return problem(request, exc.status_code, str(exc.detail), headers=exc.headers)


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Errores controlados: el request no cumple el esquema (body, query, path...)."""
    return problem(request, 422, "Request validation failed", errors=jsonable_encoder(exc.errors()))


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Errores no controlados: se registran completos en logs, pero al cliente no se le
    devuelve ningún detalle interno."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return problem(request, 500, "An unexpected error occurred.")


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)
