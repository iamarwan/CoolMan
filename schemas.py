# schemas.py

import uuid
import re
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator, ConfigDict

from models import CoolerStatus, CupsType, PhotoCategory, SponsorType

# Basic text sanitization regex to prevent basic XSS or script injections
# Only allows letters, numbers, spaces, and basic punctuation.
STRICT_TEXT_PATTERN = re.compile(r"^[\w\s.,!?'\"()-]*$")

def sanitize_text(v: str) -> str:
    if not v:
        return v
    v = v.strip()
    if not STRICT_TEXT_PATTERN.match(v):
        raise ValueError("Input contains invalid characters.")
    return v


class UserAuthResponse(BaseModel):
    id: str
    username: str
    trust_score: int
    access_token: str


class WaterCoolerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: CoolerStatus = CoolerStatus.Working
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None
    is_wheelchair_accessible: Optional[bool] = None

    @field_validator("name")
    def validate_name(cls, v):
        return sanitize_text(v)


class WaterCoolerUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    status: Optional[CoolerStatus] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None
    is_wheelchair_accessible: Optional[bool] = None

    @field_validator("name")
    def validate_name(cls, v):
        if v is not None:
            return sanitize_text(v)
        return v


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
    
    # New functionality fields
    is_wheelchair_accessible: bool | None = None
    iot_weight_kg: float | None = None
    needs_urgent_refill: bool = False
    taste_reports: int = 0

    user_id: uuid.UUID | None = None          # who submitted it
    pending_status_user_id: uuid.UUID | None = None
    sponsor: SponsorRead | None = None
    photos: list[CoolerPhotoRead] = []

    model_config = ConfigDict(from_attributes=True)
