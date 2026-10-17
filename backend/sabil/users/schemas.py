# users/schemas.py
#
# Schemas describe the JSON the API accepts and returns. They are NOT database
# tables (those are in models.py).

from typing import Optional

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
    phone: Optional[str] = None   # the linked mobile number, if any


class UserAuthResponse(BaseModel):
    """Response of register/login: the user plus their login token."""
    id: str
    username: str
    trust_score: int
    access_token: str


class PhoneRequest(BaseModel):
    """Body of POST /auth/phone/request: ask for a code to be texted."""
    phone: str = Field(..., min_length=7, max_length=32)


class PhoneVerify(BaseModel):
    """Body of POST /auth/phone/verify and POST /auth/phone/attach."""
    phone: str = Field(..., min_length=7, max_length=32)
    code: str = Field(..., min_length=4, max_length=10, pattern=r"^[0-9٠-٩]+$")
    # Only needed the first time a number signs in (it creates the account).
    username: Optional[str] = Field(None, min_length=3, max_length=64, pattern=r"^[a-zA-Z0-9_]+$")


class PhoneAuthResponse(UserAuthResponse):
    """Like a normal login response, plus whether this call created the account."""
    is_new: bool
