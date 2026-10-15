# users/trust.py
#
# The TRUST SYSTEM rules in one readable place.
#
# Every user has a trust_score. Good behaviour raises it and, once it is high
# enough, the user is "trusted": their new coolers and status changes go live
# immediately instead of waiting for an admin to review them.
#
#   +50   a cooler of yours is approved (by an admin, or automatically if you are trusted)
#   -100  a cooler of yours is rejected (the score never drops below 0)
#   +10   a status change you reported is approved (at once if you are trusted;
#         one report per cooler every 10 minutes)
#   +5    you press "Still working" on a cooler
#
# Change a number here and it changes everywhere.

from sabil.users.models import User

AUTO_APPROVE_THRESHOLD = 500
APPROVE_REWARD = 50
REJECT_PENALTY = -100
STATUS_UPDATE_REWARD = 10
CONFIRM_REWARD = 5


def is_trusted(user: User) -> bool:
    """True when the user has earned instant approval (no admin review needed)."""
    return user.trust_score >= AUTO_APPROVE_THRESHOLD


def reward(user: User, points: int) -> None:
    """Add points to the user's score. A negative number is a penalty (floor of 0)."""
    user.trust_score = max(0, user.trust_score + points)
