"""The 50 m rule: a contribution only counts when the user is at the place."""

import math

from app.config import get_settings
from app.errors import ApiError
from app.schemas import UserLocation


def distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in metres (haversine)."""
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def enforce_near(location: UserLocation | None, lat: float, lng: float) -> None:
    """Raises unless the user's reported position is within the allowed
    distance of (lat, lng). Setting max_action_distance_m to 0 switches the
    rule off (emulators and browsers have no real GPS)."""
    s = get_settings()
    if s.max_action_distance_m <= 0:
        return
    if location is None:
        raise ApiError(400, "location_required", "Turn on location to do this.")
    if location.accuracy is not None and location.accuracy > s.max_gps_accuracy_m:
        raise ApiError(
            400,
            "location_inaccurate",
            "Your location is not accurate enough yet. Wait a few seconds in the open and try again.",
            accuracy_m=round(location.accuracy),
        )
    d = distance_m(location.lat, location.lng, float(lat), float(lng))
    if d > s.max_action_distance_m:
        raise ApiError(
            403,
            "too_far",
            f"You need to be within {s.max_action_distance_m} m of this spot.",
            distance_m=round(d),
            max_distance_m=s.max_action_distance_m,
        )
