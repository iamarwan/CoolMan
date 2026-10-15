# media/router.py
#
# Serves uploaded photos. This replaces a plain "static files" folder, because a
# static folder would let anyone who knows a URL view photos that are still
# waiting for review.
#
# The URL stays /uploads/photos/<file>. The file is sent only if
#   - its photo AND its cooler are approved (public), or
#   - the caller is an admin, or the user who uploaded it.
# Otherwise the answer is 404.

import os

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.access import can_view_photo
from sabil.coolers.models import CoolerPhoto, WaterCooler
from sabil.core.config import PHOTO_DIR, PHOTO_URL_PREFIX
from sabil.core.database import get_db
from sabil.core.dependencies import Viewer, get_viewer

router = APIRouter(tags=["media"])


@router.get("/uploads/photos/{filename}")
async def get_photo_file(
    filename: str,
    db: AsyncSession = Depends(get_db),
    viewer: Viewer = Depends(get_viewer),
):
    if filename != os.path.basename(filename):  # no folders, no ".."
        raise HTTPException(status_code=404, detail="Photo not found")

    photo = (
        await db.execute(
            select(CoolerPhoto).where(CoolerPhoto.file_path == f"{PHOTO_URL_PREFIX}/{filename}")
        )
    ).scalars().first()
    cooler = await db.get(WaterCooler, photo.cooler_id) if photo else None
    path = os.path.join(PHOTO_DIR, filename)

    if photo is None or cooler is None or not can_view_photo(photo, cooler, viewer) or not os.path.isfile(path):
        raise HTTPException(status_code=404, detail="Photo not found")

    public = photo.is_approved and cooler.is_approved
    return FileResponse(
        path,
        headers={"Cache-Control": "public, max-age=86400" if public else "private, no-store"},
    )
