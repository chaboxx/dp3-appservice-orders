from app.errors import DomainError


class EmailClaimRequired(DomainError):
    """Users.email es NOT NULL: sin el claim email (claim opcional del access token en Entra)
    no se puede dar de alta al usuario."""

    status_code = 403

    def __init__(self) -> None:
        super().__init__("The access token must include the email claim")


class UserInactive(DomainError):
    status_code = 403

    def __init__(self) -> None:
        super().__init__("User is inactive")
