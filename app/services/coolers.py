"""Shared cooler helpers."""

import uuid

from geoalchemy2 import Geography
from geoalchemy2.elements import WKTElement
from sqlalchemy import cast, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import not_found
from app.models import WaterCooler
from app.schemas import CoolerRead


def point(lat: float, lng: float) -> WKTElement:
    return WKTElement(f"POINT({lng} {lat})", srid=4326)


def within_meters(lat: float, lng: float, meters: float):
    """Index-friendly distance filter: a cheap bounding-box test (uses the GiST
    index) followed by an exact geodesic distance check."""
    p = func.ST_SetSRID(func.ST_MakePoint(lng, lat), 4326)
    deg = meters / 100_000 * 1.5  # generous box in degrees (works up to ~60° latitude)
    return (
        WaterCooler.geom.op("&&")(func.ST_Expand(p, deg))
        & func.ST_DWithin(
            cast(WaterCooler.geom, Geography(srid=4326)),
            cast(p, Geography(srid=4326)),
            meters,
        )
    )


def distance_to(lat: float, lng: float):
    p = func.ST_SetSRID(func.ST_MakePoint(lng, lat), 4326)
    return func.ST_Distance(
        cast(WaterCooler.geom, Geography(srid=4326)), cast(p, Geography(srid=4326))
    )


async def get_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> WaterCooler:
    cooler = await db.get(WaterCooler, cooler_id)
    if cooler is None:
        raise not_found("cooler")
    return cooler


async def get_public_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> WaterCooler:
    cooler = await get_cooler(db, cooler_id)
    if not cooler.is_approved:
        raise not_found("cooler")
    return cooler


async def get_visible_cooler(
    db: AsyncSession, cooler_id: uuid.UUID, viewer_id: uuid.UUID | None
) -> WaterCooler:
    """An approved cooler, or the viewer's own cooler that is still in review."""
    cooler = await get_cooler(db, cooler_id)
    own_pending = (
        viewer_id is not None and cooler.user_id == viewer_id and not cooler.is_rejected
    )
    if not cooler.is_approved and not own_pending:
        raise not_found("cooler")
    return cooler


def to_public(cooler: WaterCooler, viewer_id: uuid.UUID | None = None) -> CoolerRead:
    """Serialize for the public: approved photos, plus the viewer's own."""
    visible = {
        p.id for p in cooler.photos if p.is_approved or (viewer_id and p.user_id == viewer_id)
    }
    data = CoolerRead.model_validate(cooler)
    data.photos = [p for p in data.photos if p.id in visible]
    return data


async def confirmations_count(db: AsyncSession, cooler_id: uuid.UUID) -> int:
    from app.models import ActionType, UserAction

    return (
        await db.scalar(
            select(func.count(UserAction.id)).where(
                UserAction.cooler_id == cooler_id, UserAction.action == ActionType.confirm
            )
        )
    ) or 0


async def load_fresh(db: AsyncSession, cooler_id: uuid.UUID) -> WaterCooler:
    """Re-read a cooler with relationships after a commit."""
    result = await db.execute(
        select(WaterCooler).where(WaterCooler.id == cooler_id).execution_options(populate_existing=True)
    )
    return result.scalar_one()
