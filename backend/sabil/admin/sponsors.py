# admin/sponsors.py
#
# Admin: create, verify and delete sponsors, and attach them to coolers.
# Mounted under /admin by admin/router.py.

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import WaterCooler
from sabil.coolers.schemas import WaterCoolerRead
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404
from sabil.sponsors.models import Sponsor
from sabil.sponsors.schemas import SponsorAssign, SponsorCreate, SponsorRead

router = APIRouter()


@router.post("/sponsors", response_model=SponsorRead, status_code=201)
async def create_sponsor(payload: SponsorCreate, db: AsyncSession = Depends(get_db)):
    sponsor = Sponsor(
        name=payload.name,
        sponsor_type=payload.sponsor_type,
        contact=payload.contact,
    )
    db.add(sponsor)
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.patch("/sponsors/{sponsor_id}/verify", response_model=SponsorRead)
async def verify_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    sponsor = await get_or_404(db, Sponsor, sponsor_id, "Sponsor")
    sponsor.verified = True
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.delete("/sponsors/{sponsor_id}")
async def delete_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Delete a sponsor; the coolers they sponsored stay, just without a sponsor."""
    sponsor = await get_or_404(db, Sponsor, sponsor_id, "Sponsor")
    sponsored = await db.execute(select(WaterCooler).where(WaterCooler.sponsor_id == sponsor.id))
    for cooler in sponsored.scalars().all():
        cooler.sponsor_id = None
    await db.delete(sponsor)
    await db.commit()
    return {"message": "Sponsor deleted"}


@router.patch("/coolers/{cooler_id}/assign-sponsor", response_model=WaterCoolerRead)
async def assign_sponsor(
    cooler_id: uuid.UUID,
    payload: SponsorAssign,
    db: AsyncSession = Depends(get_db),
):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    sponsor = await get_or_404(db, Sponsor, payload.sponsor_id, "Sponsor")
    cooler.sponsor_id = sponsor.id
    await db.commit()
    await db.refresh(cooler)
    return cooler


@router.delete("/coolers/{cooler_id}/assign-sponsor", response_model=WaterCoolerRead)
async def remove_sponsor(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.sponsor_id = None
    await db.commit()
    await db.refresh(cooler)
    return cooler
