"""Request/response schemas."""

import re
import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.models import CoolerStatus, CupsType, PhotoCategory, RequestStatus, SponsorType

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

class UserLocation(BaseModel):
    """Where the user's phone says it is, sent with each contribution.
    It is checked and then discarded; it is never stored."""

    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = Field(None, ge=0, le=100_000)  # metres


class CoolerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    status: CoolerStatus = CoolerStatus.Working
    has_cups: Optional[bool] = None
    cups_type: Optional[CupsType] = None
    is_wheelchair_accessible: Optional[bool] = None
    user_location: Optional[UserLocation] = None

    @field_validator("name")
    @classmethod
    def _clean(cls, v: str) -> str:
        return clean_text(v)


class StatusUpdate(BaseModel):
    status: CoolerStatus
    location: Optional[UserLocation] = None


class CoolerPin(BaseModel):
    """Minimal data for drawing a map marker."""

    id: uuid.UUID
    lat: float
    lng: float
    status: CoolerStatus
    has_cups: Optional[bool] = None
    sponsored: bool = False
    pending: bool = False  # the caller's own cooler, still waiting for review


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
    confirmations_count: int = 0

    model_config = ConfigDict(from_attributes=True)


class ConfirmResponse(BaseModel):
    message: str
    trust_score: int
    points_awarded: int = 0
    last_verified_at: datetime


# ── Build-a-sabil requests ───────────────────────────────────────────────────
# The app sends these codes and translates them; the admin panel shows the
# English labels in app/admin_web/request_labels.py.

Package = Literal["full", "care_only", "company"]
Extra = Literal["filter", "shade", "cups", "lighting"]
Timing = Literal["asap", "month", "quarter", "flexible"]
Purpose = Literal["memorial", "charity", "business", "community", "other"]
PlaceType = Literal["street", "mosque", "school", "hospital", "shop", "workplace", "other"]
Permission = Literal["owner", "has_permission", "working_on_it", "not_yet"]
YesNo = Literal["yes", "no", "unsure"]
ContactMethod = Literal["call", "whatsapp"]
BestTime = Literal["morning", "afternoon", "evening", "any"]
Governorate = Literal[
    "cairo", "giza", "alexandria", "qalyubia", "sharqia", "dakahlia", "gharbia", "monufia",
    "beheira", "kafr_el_sheikh", "damietta", "port_said", "ismailia", "suez", "faiyum",
    "beni_suef", "minya", "asyut", "sohag", "qena", "luxor", "aswan", "red_sea",
    "new_valley", "matrouh", "north_sinai", "south_sinai",
]

# Egyptian mobile: 01x xxxx xxxx, optionally written with +20 / 0020.
_EG_MOBILE = re.compile(r"^(?:\+20|0020|0)?(1[0125]\d{8})$")


def normalize_eg_mobile(v: str) -> str:
    digits = re.sub(r"[\s\-()]", "", v)
    digits = digits.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))
    m = _EG_MOBILE.match(digits)
    if not m:
        raise ValueError("Enter an Egyptian mobile number, for example 010 1234 5678.")
    return "0" + m.group(1)


class SabilRequestCreate(BaseModel):
    package: Package
    quantity: int = Field(1, ge=1, le=50)
    taps: int = Field(2, ge=2, le=4)
    extras: list[Extra] = Field(default_factory=list, max_length=4)
    timing: Timing

    purpose: Purpose
    dedication_name: Optional[str] = Field(None, max_length=120)
    plaque_text: Optional[str] = Field(None, max_length=200)
    show_publicly: bool = True

    governorate: Governorate
    area: str = Field(..., min_length=2, max_length=120)
    address_notes: Optional[str] = Field(None, max_length=300)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    place_type: PlaceType
    permission: Permission
    electricity: YesNo
    water_line: YesNo

    contact_name: str = Field(..., min_length=2, max_length=120)
    phone: str = Field(..., max_length=20)
    contact_method: ContactMethod
    best_time: BestTime
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator("dedication_name", "plaque_text", "area", "address_notes", "contact_name", "notes")
    @classmethod
    def _clean(cls, v: Optional[str]) -> Optional[str]:
        return clean_text(v) or None

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str) -> str:
        return normalize_eg_mobile(v)

    @field_validator("extras")
    @classmethod
    def _unique(cls, v: list[str]) -> list[str]:
        return sorted(set(v))

    @model_validator(mode="after")
    def _checks(self):
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Send both latitude and longitude, or neither.")
        if not self.area or not self.contact_name:
            raise ValueError("Area and contact name are required.")
        if self.package != "company":
            self.quantity = 1
        return self


class SabilRequestRead(BaseModel):
    id: uuid.UUID
    status: RequestStatus
    created_at: datetime
    updated_at: datetime
    package: str
    quantity: int
    taps: int
    extras: list[str]
    timing: str
    purpose: str
    dedication_name: Optional[str] = None
    governorate: str
    area: str
    quote_egp: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

    @field_validator("extras", mode="before")
    @classmethod
    def _split(cls, v):
        return [e for e in v.split(",") if e] if isinstance(v, str) else v
