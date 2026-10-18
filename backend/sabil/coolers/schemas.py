# coolers/schemas.py

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from sabil.coolers.models import CoolerStatus, CupsType, PhotoCategory
from sabil.core.validation import sanitize_text
from sabil.sponsors.schemas import SponsorRead


class WaterCoolerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: CoolerStatus = CoolerStatus.Working
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None

    @field_validator("name")
    def validate_name(cls, v):
        return sanitize_text(v)


class StatusUpdate(BaseModel):
    """Body of PATCH /coolers/{id}/status and PATCH /admin/coolers/{id}/force-status."""
    status: CoolerStatus


class CoolerPhotoRead(BaseModel):
    id: uuid.UUID
    cooler_id: uuid.UUID
    file_path: str
    uploaded_at: datetime
    is_approved: bool
    photo_category: PhotoCategory

    model_config = ConfigDict(from_attributes=True)


class WaterCoolerRead(BaseModel):
    id: uuid.UUID
    name: str
    latitude: float
    longitude: float
    status: CoolerStatus
    last_verified_at: datetime
    created_at: datetime
    is_approved: bool
    is_rejected: bool
    pending_status: str | None = None
    has_cups: bool | None = None
    cups_type: CupsType | None = None

    dedicated_to: str | None = None           # "in memory of ..." (public)
    dedication_message: str | None = None

    user_id: uuid.UUID | None = None          # who submitted it
    pending_status_user_id: uuid.UUID | None = None
    sponsor: SponsorRead | None = None
    photos: list[CoolerPhotoRead] = []

    model_config = ConfigDict(from_attributes=True)
