# admin/cups.py
#
# Admin: switch cup information on or off for one cooler.
# Mounted under /admin by admin/router.py (so an admin token is always required).
#
# Cup information is hidden in the app by default. A cooler only shows it after an
# admin switches it on here (for example, a sponsor pays for cups at that cooler).
# Sponsoring a cooler does NOT switch it on by itself: sponsors can sponsor in
# several ways (a banner, cups, more).
#
#   PUT /admin/coolers/{id}/cups     body {"enabled": true | false}

import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.admin.schemas import CupsEnabledSet
from sabil.coolers.models import WaterCooler
from sabil.coolers.schemas import WaterCoolerRead
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404

router = APIRouter()


@router.put("/coolers/{cooler_id}/cups", response_model=WaterCoolerRead)
async def set_cups_enabled(
    cooler_id: uuid.UUID,
    payload: CupsEnabledSet,
    db: AsyncSession = Depends(get_db),
):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.cups_enabled = payload.enabled
    if payload.enabled and cooler.has_cups is None:
        cooler.has_cups = True  # switching cups on means this cooler supplies them
    await db.commit()
    await db.refresh(cooler)
    return cooler
