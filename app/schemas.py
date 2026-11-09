"""Request/response schemas."""

import re
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models import CoolerStatus, CupsType, PhotoCategory, SponsorType

# Reject control characters and angle brackets; allow everything else, including
# Arabic and normal punctuation such as / & # :
_FORBIDDEN = re.compile(r"[<>\x00-\x1f\x7f]")


def clean_text(v: Optional[str]) -> Optional[str]:
    if v is None:
        return v
    v = " ".join(v.split())  # trim + collapse whitespace
    if _FORBIDDEN.search(v):
        raise ValueError("Text contains characters that are not allowed.")
    return v


# ── Auth / users ─────────────────────────────────────────────────────────────

class Credentials(BaseModel):
    username: str = Field(..., min_length=3, max_length=64, pattern=r"^[A-Za-z0-9_]+$")
    password: str = Field(..., min_length=8, max_length=128)


class UserRead(BaseModel):
    id: uuid.UUID
    username: str
    trust_score: int

    model_config = ConfigDict(from_attributes=True)


class AuthResponse(UserRead):
    access_token: str


class LeaderboardEntry(BaseModel):
    rank: int
    username: str
    trust_score: int


# ── Sponsors ─────────────────────────────────────────────────────────────────

class SponsorCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    sponsor_type: SponsorType
    contact: Optional[str] = Field(None, max_length=255)

    @field_validator("name", "contact")
    @classmethod
    def _clean(cls, v: Optional[str]) -> Optional[str]:
        return clean_text(v)


class SponsorRead(BaseModel):
    id: uuid.UUID
    name: str
    sponsor_type: SponsorType
    contact: Optional[str] = None
    verified: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SponsorReadWithCount(SponsorRead):
    cooler_count: int = 0


# ── Photos ───────────────────────────────────────────────────────────────────

class PhotoRead(BaseModel):
    id: uuid.UUID
    cooler_id: uuid.UUID
    file_path: str
    thumb_path: Optional[str] = None
    uploaded_at: datetime
    is_approved: bool
    photo_category: PhotoCategory

    model_config = ConfigDict(from_attributes=True)


# ── Coolers ──────────────────────────────────────────────────────────────────

class CoolerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: CoolerStatus = CoolerStatus.Working
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None
    is_wheelchair_accessible: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def _clean(cls, v: str) -> str:
        return clean_text(v)


class StatusUpdate(BaseModel):
    status: CoolerStatus


class CoolerPin(BaseModel):
    """Minimal data for drawing a map marker."""

    id: uuid.UUID
    lat: float
    lng: float
    status: CoolerStatus
    has_cups: Optional[bool] = None
    sponsored: bool = False


class PinsResponse(BaseModel):
    pins: list[CoolerPin]
    truncated: bool  # True if the area held more coolers than `limit`


class CoolerRead(BaseModel):
    """Full cooler. Public endpoints only include approved photos."""

    id: uuid.UUID
    name: str
    latitude: float
    longitude: float
    status: CoolerStatus
    last_verified_at: datetime
    created_at: datetime
    is_approved: bool
    is_rejected: bool
    pending_status: Optional[CoolerStatus] = None
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None
    is_wheelchair_accessible: Optional[bool] = None
    user_id: Optional[uuid.UUID] = None
    sponsor: Optional[SponsorRead] = None
    photos: list[PhotoRead] = []

    model_config = ConfigDict(from_attributes=True)


class ConfirmResponse(BaseModel):
    message: str
    trust_score: int
    last_verified_at: datetime
