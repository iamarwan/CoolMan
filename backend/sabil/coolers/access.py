# coolers/access.py
#
# Who may SEE a cooler or a photo. The rule is the same everywhere:
#   - approved things are public
#   - unapproved things are visible only to admins and to the person who
#     submitted them
# Anyone else gets "404 not found" (not 403), so ids cannot be probed.

from sabil.coolers.models import CoolerPhoto, WaterCooler
from sabil.core.dependencies import Viewer


def can_view_cooler(cooler: WaterCooler, viewer: Viewer) -> bool:
    if cooler.is_approved or viewer.is_admin:
        return True
    return viewer.user_id is not None and viewer.user_id == cooler.user_id


def can_view_photo(photo: CoolerPhoto, cooler: WaterCooler, viewer: Viewer) -> bool:
    """A photo is public only when BOTH the photo and its cooler are approved."""
    if photo.is_approved and cooler.is_approved:
        return True
    if viewer.is_admin:
        return True
    return viewer.user_id is not None and viewer.user_id == photo.user_id
