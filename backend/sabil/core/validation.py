# core/validation.py
#
# Input cleaning shared by every schema that accepts free text.

import re

# Basic text sanitization regex to prevent basic XSS or script injections.
# Only allows letters, numbers, spaces, and basic punctuation.
STRICT_TEXT_PATTERN = re.compile(r"^[\w\s.,!?'\"()-]*$")


def sanitize_text(v: str) -> str:
    if not v:
        return v
    v = v.strip()
    if not STRICT_TEXT_PATTERN.match(v):
        raise ValueError("Input contains invalid characters.")
    return v
