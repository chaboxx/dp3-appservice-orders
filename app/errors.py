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


class DomainError(Exception):
    """Base de los errores de negocio de cada módulo (p. ej. `OrderNotFound`).

    Los services la lanzan sin saber de HTTP; cada subclase define su `status_code`
    (y `headers` si la respuesta los necesita, p. ej. WWW-Authenticate en un 401).
    """

    status_code: int = 400
    headers: dict[str, str] | None = None

    def __init__(self, detail: str) -> None:
        super().__init__(detail)
        self.detail = detail


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


async def domain_exception_handler(request: Request, exc: DomainError) -> JSONResponse:
    """Errores controlados: reglas de negocio que lanzan los services."""
    return problem(request, exc.status_code, exc.detail, headers=exc.headers)


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Errores no controlados: se registran completos en logs, pero al cliente no se le
    devuelve ningún detalle interno."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return problem(request, 500, "An unexpected error occurred.")


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(DomainError, domain_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)
