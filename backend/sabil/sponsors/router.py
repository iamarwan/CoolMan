# sponsors/router.py
#
# Public sponsor pages. (Creating, verifying and assigning sponsors is
# admin-only and lives in admin/sponsors.py.)

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import WaterCooler
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404
from sabil.sponsors.models import Sponsor
from sabil.sponsors.schemas import SponsorRead, SponsorReadWithCount

router = APIRouter(prefix="/sponsors", tags=["sponsors"])


def _with_count(sponsor: Sponsor, cooler_count: int) -> SponsorReadWithCount:
    return SponsorReadWithCount(
        **SponsorRead.model_validate(sponsor).model_dump(),
        cooler_count=cooler_count,
    )


@router.get("", response_model=list[SponsorReadWithCount])
async def list_sponsors(db: AsyncSession = Depends(get_db)):
    """Every sponsor with the number of approved coolers they sponsor."""
    count_subq = (
        select(
            WaterCooler.sponsor_id,
            func.count(WaterCooler.id).label("cooler_count"),
        )
        .where(WaterCooler.is_approved == True, WaterCooler.sponsor_id.is_not(None))  # noqa: E712
        .group_by(WaterCooler.sponsor_id)
        .subquery()
    )

    stmt = (
        select(Sponsor, func.coalesce(count_subq.c.cooler_count, 0).label("cooler_count"))
        .outerjoin(count_subq, Sponsor.id == count_subq.c.sponsor_id)
        .order_by(Sponsor.name)
    )
    rows = (await db.execute(stmt)).all()
    return [_with_count(sponsor, count) for sponsor, count in rows]


@router.get("/{sponsor_id}", response_model=SponsorReadWithCount)
async def get_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    sponsor = await get_or_404(db, Sponsor, sponsor_id, "Sponsor")

    count = (
        await db.execute(
            select(func.count(WaterCooler.id)).where(
                WaterCooler.sponsor_id == sponsor.id,
                WaterCooler.is_approved == True,  # noqa: E712
            )
        )
    ).scalar() or 0
    return _with_count(sponsor, count)
