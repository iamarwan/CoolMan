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

# Largest accepted upload. The app shrinks photos to about 1920 px before
# sending, which is far below this.
MAX_UPLOAD_BYTES = 8 * 1024 * 1024  # 8 MB

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

# Photo uploads have their own, higher limit: adding one cooler with 5 photos
# is 1 create + 5 uploads, and the photos must not be refused halfway.
PHOTO_RATE_LIMIT_MAX_REQUESTS = 20
PHOTO_RATE_LIMIT_WINDOW_SECONDS = 60.0

# Login protection: at most N login/register attempts per IP per window.
# Counted separately from the submission limit above.
AUTH_RATE_LIMIT_MAX_ATTEMPTS = int(os.getenv("SABIL_AUTH_MAX_ATTEMPTS", "10"))
AUTH_RATE_LIMIT_WINDOW_SECONDS = 60.0

# ─────────────────────────────────────────────
# PHONE SIGN-IN (SMS one-time codes)
# ─────────────────────────────────────────────

# Which SMS service sends the codes (see core/sms.py):
#   console  development only: the code is printed in the server log, nothing is sent
#   none     phone sign-in is switched off (the default in production until a real
#            provider is added to core/sms.py and named here)
SMS_PROVIDER = os.getenv("SABIL_SMS_PROVIDER", "none" if IS_PRODUCTION else "console").strip().lower()

PHONE_CODE_LENGTH = 6
PHONE_CODE_TTL_SECONDS = 300          # a code works for 5 minutes
PHONE_CODE_MAX_WRONG_TRIES = 5        # then the code is burned and a new one is needed
PHONE_CODE_RESEND_SECONDS = 60        # minimum gap between two codes for one number
PHONE_CODES_PER_HOUR = 5              # most codes one number can request per hour (SMS costs money)

# A user may report a status change on the same cooler once per this many
# seconds (stops point-farming by repeating the same report).
STATUS_REPORT_COOLDOWN_SECONDS = 600.0        # 10 minutes

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
    if IS_PRODUCTION and SMS_PROVIDER == "console":
        problems.append(
            "SABIL_SMS_PROVIDER=console only prints codes in the log; use a real provider or none."
        )
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
