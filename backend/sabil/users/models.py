# users/models.py
#
# The `users` table. One row per person who registered in the app.

import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from sabil.core.database import Base

if TYPE_CHECKING:  # only for editors/type-checkers; avoids circular imports at runtime
    from sabil.coolers.models import CoolerPhoto, WaterCooler


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(256), nullable=False)
    # Mobile number in the form +201012345678 (see core/phone.py). Optional: people
    # who sign in with a password may never add one. Used for phone sign-in.
    phone: Mapped[Optional[str]] = mapped_column(String(16), nullable=True, unique=True, index=True)
    trust_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    badges: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)  # JSON array string of badges

    coolers: Mapped[list["WaterCooler"]] = relationship(
        "WaterCooler",
        back_populates="user",
        foreign_keys="[WaterCooler.user_id]",
    )
    photos: Mapped[list["CoolerPhoto"]] = relationship("CoolerPhoto", back_populates="user")


class PhoneCode(Base):
    """A one-time SMS code waiting to be entered. Only a keyed hash is stored."""

    __tablename__ = "phone_codes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    phone: Mapped[str] = mapped_column(String(16), nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    wrong_tries: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    used: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
