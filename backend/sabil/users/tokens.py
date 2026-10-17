# users/tokens.py
#
# The JSON that every sign-in route returns: the user's public details plus a
# fresh login token. Shared by password sign-in (router.py) and phone sign-in (phone.py).

from sabil.core.security import create_user_token
from sabil.users.models import User


def auth_response(user: User) -> dict:
    return {
        "id": str(user.id),
        "username": user.username,
        "trust_score": user.trust_score,
        "access_token": create_user_token(user.id),
    }
