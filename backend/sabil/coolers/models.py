# coolers/models.py
#
# The `water_coolers` and `cooler_photos` tables, plus the choice lists (enums)
# they use.

import enum
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from geoalchemy2 import Geometry
from sqlalchemy import Boolean, DateTime, Enum as SAEnum, ForeignKey, Index, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from sabil.core.database import Base

if TYPE_CHECKING:
    from sabil.sponsors.models import Sponsor
    from sabil.users.models import User


# ─────────────────────────────────────────────
# ENUMS  (a fixed list of allowed values)
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


# ─────────────────────────────────────────────
# MODELS
# ─────────────────────────────────────────────

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

    # "Sadaka Jariya in memory of ..." (set by an admin only, see admin/dedications.py).
    dedicated_to: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    dedication_message: Mapped[Optional[str]] = mapped_column(String(280), nullable=True)

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
    # cascade: deleting a cooler also deletes its photo rows (the files on disk
    # are removed by the admin delete route).
    photos: Mapped[list["CoolerPhoto"]] = relationship(
        "CoolerPhoto",
        back_populates="cooler",
        lazy="selectin",
        cascade="all, delete-orphan",
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
