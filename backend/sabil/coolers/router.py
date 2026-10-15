# coolers/router.py
#
# The public cooler API: find coolers, add one, report its status, add photos.
# (Admin-only cooler actions are in admin/coolers.py.)
#
# IMPORTANT: FastAPI matches routes top to bottom. "/coolers/my", "/nearby" and
# "/search" must stay ABOVE "/coolers/{cooler_id}", otherwise "{cooler_id}"
# would swallow them.

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from geoalchemy2 import Geography
from geoalchemy2.elements import WKTElement
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
from sqlalchemy import cast, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import CoolerPhoto, WaterCooler
from sabil.coolers.photos import add_photo
from sabil.coolers.schemas import (
    CoolerPhotoRead,
    StatusUpdate,
    WaterCoolerCreate,
    WaterCoolerRead,
)
from sabil.core.database import get_db
from sabil.coolers.access import can_view_cooler
from sabil.core.dependencies import Viewer, get_current_user, get_viewer
from sabil.core.lookup import get_or_404
from sabil.core.rate_limit import (
    check_status_cooldown,
    record_status_report,
    check_confirm_cooldown,
    photo_rate_limiter,
    rate_limiter,
    record_confirm,
    reset_confirm_cooldown,
)
from sabil.users.models import User
from sabil.users.trust import (
    APPROVE_REWARD,
    CONFIRM_REWARD,
    STATUS_UPDATE_REWARD,
    is_trusted,
    reward,
)

router = APIRouter(prefix="/coolers", tags=["coolers"])


def _within_meters(lat: float, lng: float, meters: float):
    """SQL condition: the cooler is within `meters` of this point (true distance on the globe)."""
    point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    return ST_DWithin(
        cast(WaterCooler.geom, Geography(geometry_type="POINT", srid=4326)),
        cast(point, Geography(geometry_type="POINT", srid=4326)),
        meters,
        use_spheroid=True,
    )


# ─────────────────────────────────────────────
# FINDING COOLERS
# ─────────────────────────────────────────────

@router.get("/my", response_model=list[WaterCoolerRead])
async def get_my_coolers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Coolers I submitted, or where I proposed a status change (My Submissions screen)."""
    stmt = (
        select(WaterCooler)
        .where(
            or_(
                WaterCooler.user_id == current_user.id,
                WaterCooler.pending_status_user_id == current_user.id,
            )
        )
        .order_by(WaterCooler.last_verified_at.desc())
    )
    return (await db.execute(stmt)).scalars().all()


@router.get("/nearby", response_model=list[WaterCoolerRead])
async def get_nearby_coolers(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, gt=0, le=50),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(WaterCooler).where(
        WaterCooler.is_approved == True,  # noqa: E712  (SQLAlchemy needs == here)
        _within_meters(lat, lng, radius_km * 1000),
    )
    return (await db.execute(stmt)).scalars().all()


@router.get("/search", response_model=list[WaterCoolerRead])
async def search_coolers(
    q: str = Query(..., min_length=1, max_length=100),
    db: AsyncSession = Depends(get_db),
):
    term = f"%{q.strip()}%"
    stmt = (
        select(WaterCooler)
        .where(WaterCooler.is_approved == True, WaterCooler.name.ilike(term))  # noqa: E712
        .limit(30)
    )
    return (await db.execute(stmt)).scalars().all()


@router.get("/{cooler_id}", response_model=WaterCoolerRead)
async def get_cooler(
    cooler_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    viewer: Viewer = Depends(get_viewer),
):
    """Public for approved coolers; unapproved ones only for admins and the submitter."""
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    if not can_view_cooler(cooler, viewer):
        raise HTTPException(status_code=404, detail="Cooler not found")
    return cooler


@router.get("/{cooler_id}/photos", response_model=list[CoolerPhotoRead])
async def get_cooler_photos_public(
    cooler_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    viewer: Viewer = Depends(get_viewer),
):
    """Approved photos only. Used by the app to show a cooler's gallery."""
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    if not can_view_cooler(cooler, viewer):
        raise HTTPException(status_code=404, detail="Cooler not found")
    stmt = select(CoolerPhoto).where(
        CoolerPhoto.cooler_id == cooler_id,
        CoolerPhoto.is_approved == True,  # noqa: E712
    )
    return (await db.execute(stmt)).scalars().all()


# ─────────────────────────────────────────────
# REPORTING ON A COOLER
# ─────────────────────────────────────────────

@router.patch("/{cooler_id}/status", response_model=WaterCoolerRead)
async def update_cooler_status(
    cooler_id: uuid.UUID,
    payload: StatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Report a new status. Trusted users change it at once; others wait for an admin."""
    check_status_cooldown(current_user.id, cooler_id)

    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    if not cooler.is_approved:
        raise HTTPException(status_code=400, detail="Cooler is not yet approved.")
    if payload.status == cooler.status and not cooler.pending_status:
        raise HTTPException(
            status_code=400,
            detail="The cooler already has this status. Use \"Still working\" to confirm it.",
        )

    if is_trusted(current_user):
        cooler.status = payload.status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        cooler.last_verified_at = datetime.now(timezone.utc)
        reset_confirm_cooldown(cooler_id)
        reward(current_user, STATUS_UPDATE_REWARD)  # applied at once, so paid at once
    else:
        # Points for this are paid when an admin approves it (admin/coolers.py).
        cooler.pending_status = payload.status.value
        cooler.pending_status_user_id = current_user.id

    record_status_report(current_user.id, cooler_id)
    await db.commit()
    await db.refresh(cooler)
    return cooler


@router.post("/{cooler_id}/confirm")
async def confirm_cooler_working(
    cooler_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """The 'Still working' button: refreshes the cooler's last-verified time."""
    check_confirm_cooldown(current_user.id, cooler_id)

    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    if not cooler.is_approved:
        raise HTTPException(status_code=400, detail="Cooler is not yet approved.")

    cooler.last_verified_at = datetime.now(timezone.utc)
    reward(current_user, CONFIRM_REWARD)

    await db.commit()
    record_confirm(current_user.id, cooler_id)
    await db.refresh(current_user)
    return {"message": "Confirmed", "trust_score": current_user.trust_score}


# ─────────────────────────────────────────────
# ADDING COOLERS AND PHOTOS
# ─────────────────────────────────────────────

@router.post(
    "",
    response_model=WaterCoolerRead,
    status_code=201,
    dependencies=[Depends(rate_limiter)],
)
async def create_cooler(
    payload: WaterCoolerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Submit a new cooler. Refuses a spot that already has one within 15 metres."""
    already_there = await db.execute(
        select(WaterCooler.id).where(_within_meters(payload.latitude, payload.longitude, 15.0)).limit(1)
    )
    if already_there.first() is not None:
        raise HTTPException(
            status_code=400,
            detail="A water cooler has already been reported at this exact location.",
        )

    auto_approved = is_trusted(current_user)

    cooler = WaterCooler(
        name=payload.name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        geom=WKTElement(f"POINT({payload.longitude} {payload.latitude})", srid=4326),
        status=payload.status,
        is_approved=auto_approved,
        has_cups=payload.has_cups,
        cups_type=payload.cups_type,
        user_id=current_user.id,
    )
    db.add(cooler)

    if auto_approved:
        reward(current_user, APPROVE_REWARD)

    await db.commit()
    await db.refresh(cooler)
    return cooler


@router.post(
    "/{cooler_id}/photos",
    response_model=CoolerPhotoRead,
    status_code=201,
    dependencies=[Depends(photo_rate_limiter)],
)
async def upload_cooler_photo(
    cooler_id: uuid.UUID,
    file: UploadFile = File(...),
    photo_category: str = Form("Cooler"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a photo. It stays hidden until an admin approves it."""
    return await add_photo(db, cooler_id, file, photo_category, user_id=current_user.id)
