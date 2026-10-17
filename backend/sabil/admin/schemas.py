# admin/schemas.py

from typing import Optional

from pydantic import BaseModel, Field, field_validator

from sabil.core.validation import sanitize_text


class AdminLoginRequest(BaseModel):
    username: str
    password: str


class DedicationSet(BaseModel):
    """Body of PUT /admin/coolers/{id}/dedication."""
    dedicated_to: str = Field(..., min_length=1, max_length=120)
    message: Optional[str] = Field(None, max_length=280)

    @field_validator("dedicated_to", "message")
    def clean_text(cls, v):
        if v is None:
            return v
        v = sanitize_text(v)
        return v or None
