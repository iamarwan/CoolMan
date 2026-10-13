# core/lookup.py
#
# One helper for the "find this row by id or answer 404" pattern that every
# route needs.

import uuid
from typing import TypeVar

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

T = TypeVar("T")


async def get_or_404(db: AsyncSession, model: type[T], row_id: uuid.UUID, label: str) -> T:
    """Return the row of `model` with this id, or raise "<label> not found" (404).

        cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    """
    row = await db.get(model, row_id)
    if row is None:
        raise HTTPException(status_code=404, detail=f"{label} not found")
    return row
