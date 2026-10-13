# users/models.py
#
# The `users` table. One row per person who registered in the app.

import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from sabil.core.database import Base

if TYPE_CHECKING:  # only for editors/type-checkers; avoids circular imports at runtime
    from sabil.coolers.models import CoolerPhoto, WaterCooler


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(256), nullable=False)
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
