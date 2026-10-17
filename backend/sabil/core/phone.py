# core/phone.py
#
# Turns the many ways Egyptians write a mobile number into one standard form.
#
#   01012345678, 1012345678, +201012345678, 201012345678, 00201012345678,
#   "010 1234 5678", and numbers typed with Arabic digits (٠١٠١٢٣٤٥٦٧٨)
#       -->  +201012345678
#
# Only Egyptian mobile numbers are accepted (prefixes 010, 011, 012, 015).
# Knows nothing about the rest of the app, so it can be copied elsewhere.

import re

_ARABIC_DIGITS = str.maketrans(
    "٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹",
    "01234567890123456789",
)
_EG_MOBILE = re.compile(r"^\+201[0125]\d{8}$")


def normalize_egyptian_mobile(raw: str) -> str | None:
    """Return the number as +20XXXXXXXXXX, or None if it is not an Egyptian mobile."""
    s = re.sub(r"[\s\-().]", "", raw.translate(_ARABIC_DIGITS))
    if s.startswith("0020"):
        s = "+" + s[2:]
    elif s.startswith("20"):
        s = "+" + s
    elif s.startswith("01"):
        s = "+20" + s[1:]
    elif s.startswith("1"):
        s = "+20" + s
    return s if _EG_MOBILE.fullmatch(s) else None


def normalize_digits(raw: str) -> str:
    """Turn Arabic-Indic digits (٠١٢٣) into 0-9 (used for typed one-time codes)."""
    return raw.translate(_ARABIC_DIGITS).strip()
