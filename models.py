# models.py

import uuid
import enum
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import String, Enum as SAEnum, DateTime, Numeric, Boolean, ForeignKey, Integer, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geometry

from database import Base


# ─────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────

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


# ─────────────────────────────────────────────
# MODELS
# ─────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(256), nullable=False)
    trust_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    badges: Mapped[Optional[str]] = mapped_column(String(512), nullable=True) # JSON array string of badges

    coolers: Mapped[list["WaterCooler"]] = relationship(
        "WaterCooler",
        back_populates="user",
        foreign_keys="[WaterCooler.user_id]",
    )
    photos: Mapped[list["CoolerPhoto"]] = relationship("CoolerPhoto", back_populates="user")


class Sponsor(Base):
    __tablename__ = "sponsors"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    sponsor_type: Mapped[SponsorType] = mapped_column(SAEnum(SponsorType), nullable=False)
    contact: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    verified: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    views_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    clicks_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    coolers: Mapped[list["WaterCooler"]] = relationship("WaterCooler", back_populates="sponsor")


class WaterCooler(Base):
    __tablename__ = "water_coolers"
    __table_args__ = (
        Index("ix_wc_approved_status", "is_approved", "status"),
        Index("ix_wc_geom", "geom", postgresql_using="gist"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(Numeric(10, 7), nullable=False)
    longitude: Mapped[float] = mapped_column(Numeric(10, 7), nullable=False)
    geom: Mapped[object] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326), nullable=False
    )
    status: Mapped[CoolerStatus] = mapped_column(
        SAEnum(CoolerStatus), nullable=False, default=CoolerStatus.Working
    )
    last_verified_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    is_approved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    is_rejected: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    pending_status: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    has_cups: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    cups_type: Mapped[Optional[CupsType]] = mapped_column(SAEnum(CupsType), nullable=True)
    
    # New functionality fields
    is_wheelchair_accessible: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    iot_weight_kg: Mapped[Optional[float]] = mapped_column(Numeric(5, 2), nullable=True)
    needs_urgent_refill: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    taste_reports: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    pending_status_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    sponsor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("sponsors.id", ondelete="SET NULL"), nullable=True
    )

    user: Mapped[Optional["User"]] = relationship(
        "User",
        back_populates="coolers",
        foreign_keys=[user_id],
    )
    pending_status_user: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[pending_status_user_id],
    )
    sponsor: Mapped[Optional["Sponsor"]] = relationship(
        "Sponsor", back_populates="coolers", lazy="selectin"
    )
    photos: Mapped[list["CoolerPhoto"]] = relationship(
        "CoolerPhoto", back_populates="cooler", lazy="selectin"
    )


class CoolerPhoto(Base):
    __tablename__ = "cooler_photos"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    cooler_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("water_coolers.id", ondelete="CASCADE"), nullable=False
    )
    file_path: Mapped[str] = mapped_column(String(512), nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    is_approved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    photo_category: Mapped[PhotoCategory] = mapped_column(
        SAEnum(PhotoCategory), nullable=False, default=PhotoCategory.Cooler
    )
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    cooler: Mapped["WaterCooler"] = relationship("WaterCooler", back_populates="photos")
    user: Mapped[Optional["User"]] = relationship("User", back_populates="photos")
