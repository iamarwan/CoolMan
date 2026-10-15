# core/config.py
#
# Every setting and tunable number lives in THIS file, so you never have to
# hunt through the code to find "where is the timeout / secret / limit set?".
#
# Values that differ between your laptop and a real server are read from
# environment variables (os.getenv). The second argument is the default that is
# used when the variable is not set.

import os
import logging

# SABIL_ENV=production makes the server REFUSE to start with unsafe settings
# (see check_settings at the bottom). Anything else counts as development.
ENVIRONMENT = os.getenv("SABIL_ENV", "development").strip().lower()
IS_PRODUCTION = ENVIRONMENT == "production"

# ─────────────────────────────────────────────
# DATABASE
# ─────────────────────────────────────────────

DATABASE_URL = os.getenv(
    "SABIL_DATABASE_URL",
    "postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable",
)

# ─────────────────────────────────────────────
# LOGIN TOKENS (JWT)
# ─────────────────────────────────────────────

# WARNING: the defaults below are for local development only.
# Set SABIL_JWT_SECRET / SABIL_ADMIN_PASSWORD in any real deployment.
DEFAULT_JWT_SECRET = "change-me-in-production"
JWT_SECRET = os.getenv("SABIL_JWT_SECRET", DEFAULT_JWT_SECRET)
JWT_ISSUER = "sabil-api"

JWT_AUDIENCE_ADMIN = "sabil-admin"
JWT_EXPIRES_ADMIN_MINUTES = int(os.getenv("SABIL_ADMIN_TOKEN_MIN", "480"))        # 8 hours

JWT_AUDIENCE_USER = "sabil-user"
JWT_EXPIRES_USER_MINUTES = int(os.getenv("SABIL_USER_TOKEN_MIN", "10080"))        # 7 days

ADMIN_USERNAME = os.getenv("SABIL_ADMIN_USERNAME", "admin")
DEFAULT_ADMIN_PASSWORD = "admin123"
ADMIN_PASSWORD = os.getenv("SABIL_ADMIN_PASSWORD", DEFAULT_ADMIN_PASSWORD)

PASSWORD_HASH_ITERATIONS = 260_000

# ─────────────────────────────────────────────
# FILE UPLOADS
# ─────────────────────────────────────────────

# Folders are relative to the directory you start the server from (backend/).
UPLOAD_ROOT = "uploads"                       # served publicly at /uploads
PHOTO_DIR = os.path.join(UPLOAD_ROOT, "photos")
PHOTO_URL_PREFIX = "/uploads/photos"          # what gets stored in the database

# Browser/phone-reported content type -> file extension we save it with.
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}

# ─────────────────────────────────────────────
# ABUSE PROTECTION
# ─────────────────────────────────────────────

# Submission rate limit: at most N create/upload requests per IP per window.
RATE_LIMIT_MAX_REQUESTS = 3
RATE_LIMIT_WINDOW_SECONDS = 60.0

# Login protection: at most N login/register attempts per IP per window.
# Counted separately from the submission limit above.
AUTH_RATE_LIMIT_MAX_ATTEMPTS = int(os.getenv("SABIL_AUTH_MAX_ATTEMPTS", "10"))
AUTH_RATE_LIMIT_WINDOW_SECONDS = 60.0

# A user may press "Still working" on the same cooler once per this many seconds.
CONFIRM_COOLDOWN_SECONDS = 3600.0             # 1 hour


# ─────────────────────────────────────────────
# STARTUP SAFETY CHECK
# ─────────────────────────────────────────────

MIN_SECRET_LENGTH = 32


def settings_problems() -> list[str]:
    """Return a list of unsafe settings (empty list = all good)."""
    problems = []
    if JWT_SECRET == DEFAULT_JWT_SECRET or len(JWT_SECRET) < MIN_SECRET_LENGTH:
        problems.append(
            f"SABIL_JWT_SECRET must be set to a random value of at least "
            f"{MIN_SECRET_LENGTH} characters."
        )
    if ADMIN_PASSWORD == DEFAULT_ADMIN_PASSWORD:
        problems.append("SABIL_ADMIN_PASSWORD must be set (the default is public).")
    return problems


def check_settings() -> None:
    """Called once at startup. Production: refuse to start. Development: warn."""
    problems = settings_problems()
    if not problems:
        return
    if IS_PRODUCTION:
        raise RuntimeError(
            "Refusing to start with unsafe settings:\n  - " + "\n  - ".join(problems)
        )
    logging.getLogger("sabil").warning(
        "Unsafe default settings (fine for local development only): %s",
        " ".join(problems),
    )
