import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.errors import not_found
from app.models import Sponsor, WaterCooler
from app.schemas import SponsorRead, SponsorReadWithCount

router = APIRouter(prefix="/sponsors", tags=["sponsors"])


def _count_subquery():
    return (
        select(WaterCooler.sponsor_id, func.count(WaterCooler.id).label("n"))
        .where(WaterCooler.is_approved, WaterCooler.sponsor_id.is_not(None))
        .group_by(WaterCooler.sponsor_id)
        .subquery()
    )


def _with_count(sponsor: Sponsor, n: int) -> SponsorReadWithCount:
    return SponsorReadWithCount(**SponsorRead.model_validate(sponsor).model_dump(), cooler_count=n)


@router.get("", response_model=list[SponsorReadWithCount])
async def list_sponsors(db: AsyncSession = Depends(get_db)):
    counts = _count_subquery()
    rows = await db.execute(
        select(Sponsor, func.coalesce(counts.c.n, 0))
        .outerjoin(counts, Sponsor.id == counts.c.sponsor_id)
        .order_by(Sponsor.verified.desc(), Sponsor.name)
    )
    return [_with_count(s, n) for s, n in rows.all()]


@router.get("/{sponsor_id}", response_model=SponsorReadWithCount)
async def get_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    sponsor = await db.get(Sponsor, sponsor_id)
    if sponsor is None:
        raise not_found("sponsor")
    n = await db.scalar(
        select(func.count()).where(WaterCooler.sponsor_id == sponsor.id, WaterCooler.is_approved)
    )
    return _with_count(sponsor, n or 0)
