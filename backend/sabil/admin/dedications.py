# admin/dedications.py
#
# Admin: "Sadaka Jariya in memory of ..." dedications on coolers.
# Mounted under /admin by admin/router.py (so an admin token is always required).
#
# A dedication is arranged outside the app (the person asks, pays, or has a
# cooler built in someone's name), so only an admin can set or clear one. It is
# shown to everybody on the cooler's card.
#
#   GET    /admin/dedications                   every dedicated cooler
#   PUT    /admin/coolers/{id}/dedication       set or change it
#   DELETE /admin/coolers/{id}/dedication       remove it

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.admin.schemas import DedicationSet
from sabil.coolers.models import WaterCooler
from sabil.coolers.schemas import WaterCoolerRead
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404

router = APIRouter()


@router.get("/dedications", response_model=list[WaterCoolerRead])
async def list_dedications(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(WaterCooler)
        .where(WaterCooler.dedicated_to.is_not(None))
        .order_by(WaterCooler.name)
    )
    return result.scalars().all()


@router.put("/coolers/{cooler_id}/dedication", response_model=WaterCoolerRead)
async def set_dedication(
    cooler_id: uuid.UUID,
    payload: DedicationSet,
    db: AsyncSession = Depends(get_db),
):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.dedicated_to = payload.dedicated_to
    cooler.dedication_message = payload.message
    await db.commit()
    await db.refresh(cooler)
    return cooler


@router.delete("/coolers/{cooler_id}/dedication", response_model=WaterCoolerRead)
async def clear_dedication(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.dedicated_to = None
    cooler.dedication_message = None
    await db.commit()
    await db.refresh(cooler)
    return cooler
