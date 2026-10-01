from typing import Annotated

from fastapi import Depends, Request

from app.auth.dependencies import CurrentPrincipal
from app.database import DbSession
from app.users.models import User
from app.users.repository import SqlUserRepository, UserRepository
from app.users.service import UserService


def get_user_repository(request: Request, session: DbSession) -> UserRepository:
    # Sin base configurada (tests) se usa el repositorio en memoria creado en create_app
    if session is None:
        return request.app.state.user_repository
    return SqlUserRepository(session)


def get_current_user(
    principal: CurrentPrincipal,
    repository: Annotated[UserRepository, Depends(get_user_repository)],
) -> User:
    """El usuario del token en la tabla Users; se crea en su primer request."""
    return UserService(repository).get_or_create(principal)


CurrentUser = Annotated[User, Depends(get_current_user)]
