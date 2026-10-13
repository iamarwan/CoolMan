# users/schemas.py
#
# Schemas describe the JSON the API accepts and returns. They are NOT database
# tables (those are in models.py).

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    """Body of POST /auth/register and POST /auth/login."""
    username: str = Field(..., min_length=3, max_length=64, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(..., min_length=8, max_length=128)


class UserRead(BaseModel):
    """Response of GET /auth/me."""
    id: str
    username: str
    trust_score: int


class UserAuthResponse(BaseModel):
    """Response of register/login: the user plus their login token."""
    id: str
    username: str
    trust_score: int
    access_token: str
