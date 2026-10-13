# sponsors/models.py
#
# The `sponsors` table: people/organisations who sponsor one or more coolers.

import enum
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, DateTime, Enum as SAEnum, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from sabil.core.database import Base

if TYPE_CHECKING:
    from sabil.coolers.models import WaterCooler


class SponsorType(str, enum.Enum):
    Business = "Business"
    Mosque = "Mosque"
    Individual = "Individual"
    NGO = "NGO"


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
