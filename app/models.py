"""SQLAlchemy models."""

import enum
import uuid
from datetime import datetime, timezone
from typing import Optional

from geoalchemy2 import Geometry
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SAEnum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class CoolerStatus(str, enum.Enum):
    Working = "Working"
    Empty = "Empty"
    Broken = "Broken"


class CupsType(str, enum.Enum):
    Communal = "Communal"
    Disposable = "Disposable"


class PhotoCategory(str, enum.Enum):
    Cooler = "Cooler"
    Cups = "Cups"


class SponsorType(str, enum.Enum):
    Business = "Business"
    Mosque = "Mosque"
    Individual = "Individual"
    NGO = "NGO"


class ActionType(str, enum.Enum):
    """User actions that carry a cooldown and/or reward."""

    confirm = "confirm"
    status_report = "status_report"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(256))
    trust_score: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Sponsor(Base):
    __tablename__ = "sponsors"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255))
    sponsor_type: Mapped[SponsorType] = mapped_column(SAEnum(SponsorType, name="sponsortype"))
    contact: Mapped[Optional[str]] = mapped_column(String(255))
    verified: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class WaterCooler(Base):
    __tablename__ = "water_coolers"
    __table_args__ = (
        Index("ix_wc_approved_status", "is_approved", "status"),
        Index("ix_wc_user_id", "user_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255))
    latitude: Mapped[float] = mapped_column(Numeric(10, 7))
    longitude: Mapped[float] = mapped_column(Numeric(10, 7))
    # spatial_index=True creates a GiST index (used by bbox and distance queries).
    geom: Mapped[object] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326, spatial_index=True)
    )
    status: Mapped[CoolerStatus] = mapped_column(
        SAEnum(CoolerStatus, name="coolerstatus"), default=CoolerStatus.Working
    )
    last_verified_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    is_approved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    is_rejected: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    pending_status: Mapped[Optional[CoolerStatus]] = mapped_column(
        SAEnum(CoolerStatus, name="coolerstatus")
    )
    has_cups: Mapped[Optional[bool]] = mapped_column(Boolean)
    cups_type: Mapped[Optional[CupsType]] = mapped_column(SAEnum(CupsType, name="cupstype"))
    is_wheelchair_accessible: Mapped[Optional[bool]] = mapped_column(Boolean)

    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    pending_status_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    sponsor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("sponsors.id", ondelete="SET NULL"), index=True
    )

    sponsor: Mapped[Optional[Sponsor]] = relationship(lazy="selectin")
    photos: Mapped[list["CoolerPhoto"]] = relationship(
        back_populates="cooler",
        lazy="selectin",
        cascade="all, delete-orphan",
        order_by="CoolerPhoto.uploaded_at.desc()",
    )


class CoolerPhoto(Base):
    __tablename__ = "cooler_photos"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    cooler_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("water_coolers.id", ondelete="CASCADE"), index=True
    )
    file_path: Mapped[str] = mapped_column(String(512))
    thumb_path: Mapped[Optional[str]] = mapped_column(String(512))
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    is_approved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    photo_category: Mapped[PhotoCategory] = mapped_column(
        SAEnum(PhotoCategory, name="photocategory"), default=PhotoCategory.Cooler
    )
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True
    )

    cooler: Mapped[WaterCooler] = relationship(back_populates="photos")


class UserAction(Base):
    """Log of rewarded actions. Replaces the old in-memory cooldown store, so
    cooldowns survive restarts and work with several server processes."""

    __tablename__ = "user_actions"
    __table_args__ = (
        Index("ix_ua_lookup", "user_id", "cooler_id", "action", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    cooler_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("water_coolers.id", ondelete="CASCADE")
    )
    action: Mapped[ActionType] = mapped_column(SAEnum(ActionType, name="actiontype"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
