"""Tests unitarios del alta automática de usuarios, con el repositorio en memoria."""

from dataclasses import replace
from datetime import timedelta
from uuid import UUID

import pytest

from app.auth.schemas import Principal
from app.users.exceptions import EmailClaimRequired, UserInactive
from app.users.repository import InMemoryUserRepository
from app.users.service import LAST_LOGIN_REFRESH, UserService

PRINCIPAL = Principal(
    tenant_id=UUID("11111111-1111-1111-1111-111111111111"),
    object_id=UUID("22222222-2222-2222-2222-222222222222"),
    email="ana@example.com",
    given_name="Ana",
    family_name="Pérez",
    city="Lima",
)


@pytest.fixture
def service() -> UserService:
    return UserService(InMemoryUserRepository())


def test_first_request_creates_the_user(service: UserService) -> None:
    user = service.get_or_create(PRINCIPAL)

    assert user.id is not None
    assert (user.entra_tenant_id, user.entra_object_id) == (
        PRINCIPAL.tenant_id,
        PRINCIPAL.object_id,
    )
    assert (user.email, user.first_name, user.last_name) == ("ana@example.com", "Ana", "Pérez")
    assert user.city == "Lima"
    assert user.is_active is True
    assert user.last_login_at is not None


def test_next_requests_return_the_same_user(service: UserService) -> None:
    first = service.get_or_create(PRINCIPAL)

    assert service.get_or_create(PRINCIPAL) is first


def test_profile_changes_in_entra_are_synced(service: UserService) -> None:
    user = service.get_or_create(PRINCIPAL)

    service.get_or_create(
        replace(PRINCIPAL, email="ana.perez@example.com", family_name=None, city="Arequipa")
    )

    assert user.email == "ana.perez@example.com"
    assert user.last_name is None
    assert user.city == "Arequipa"


def test_last_login_is_refreshed_only_after_the_interval(service: UserService) -> None:
    user = service.get_or_create(PRINCIPAL)
    recent = user.last_login_at

    service.get_or_create(PRINCIPAL)
    assert user.last_login_at == recent

    user.last_login_at = recent - LAST_LOGIN_REFRESH - timedelta(seconds=1)
    service.get_or_create(PRINCIPAL)
    assert user.last_login_at > recent - LAST_LOGIN_REFRESH


def test_inactive_user_is_rejected(service: UserService) -> None:
    service.get_or_create(PRINCIPAL).is_active = False

    with pytest.raises(UserInactive):
        service.get_or_create(PRINCIPAL)


def test_email_claim_is_required(service: UserService) -> None:
    with pytest.raises(EmailClaimRequired):
        service.get_or_create(replace(PRINCIPAL, email=None))
