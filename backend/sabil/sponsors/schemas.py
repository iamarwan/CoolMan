# sponsors/schemas.py

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from sabil.core.validation import sanitize_text
from sabil.sponsors.models import SponsorType


class SponsorCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    sponsor_type: SponsorType
    contact: Optional[str] = Field(None, max_length=255)

    @field_validator("name", "contact")
    def validate_text(cls, v):
        if v is not None:
            return sanitize_text(v)
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
