# sponsors/schemas.py

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from sabil.core.validation import sanitize_contact, sanitize_text
from sabil.sponsors.models import SponsorType


class SponsorCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    sponsor_type: SponsorType
    contact: Optional[str] = Field(None, max_length=255)

    @field_validator("name")
    def validate_name(cls, v):
        return sanitize_text(v)

    @field_validator("contact")
    def validate_contact(cls, v):
        if v is not None:
            return sanitize_contact(v)
        return v


class SponsorRead(BaseModel):
    id: uuid.UUID
    name: str
    sponsor_type: SponsorType
    contact: Optional[str] = None
    verified: bool
    views_count: int = 0
    clicks_count: int = 0
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SponsorReadWithCount(SponsorRead):
    cooler_count: int = 0


class SponsorAssign(BaseModel):
    """Body of PATCH /admin/coolers/{id}/assign-sponsor."""
    sponsor_id: uuid.UUID
