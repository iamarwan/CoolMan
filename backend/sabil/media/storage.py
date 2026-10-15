# media/storage.py
#
# Saving and deleting uploaded image files on disk. Knows nothing about coolers
# or the database, so it can be reused in any project.

import os
import uuid

from fastapi import UploadFile

from sabil.core.config import ALLOWED_IMAGE_TYPES, MAX_UPLOAD_BYTES, PHOTO_DIR, PHOTO_URL_PREFIX


def ensure_upload_dirs() -> None:
    os.makedirs(PHOTO_DIR, exist_ok=True)


def _looks_like(head: bytes) -> str | None:
    """Return 'jpg', 'png' or 'webp' from the file's first bytes (its real type), else None."""
    if head.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if head.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return "webp"
    return None


def save_image(file: UploadFile, name_prefix: str) -> str:
    """Write an uploaded image to disk and return the URL path it is served at.

    Raises ValueError if the file is not a JPEG, PNG or WebP image (checked by the
    file's real first bytes, not just the type the client claims) or is too large.

    The file extension comes from the validated content type, never from the
    user-supplied filename (a crafted filename could otherwise write outside the
    upload folder), and the name contains a random id so two uploads can never
    overwrite each other.
    """
    ext = ALLOWED_IMAGE_TYPES.get(file.content_type)
    if ext is None:
        raise ValueError("Invalid file type. Use JPEG, PNG, or WebP.")

    chunk_size = 64 * 1024
    head = file.file.read(12)
    if _looks_like(head) != ext:
        raise ValueError("The file is not a real JPEG, PNG, or WebP image.")

    filename = f"{name_prefix}_{uuid.uuid4().hex}.{ext}"
    full_path = os.path.join(PHOTO_DIR, filename)
    written = len(head)
    try:
        with open(full_path, "wb") as buf:
            buf.write(head)
            while chunk := file.file.read(chunk_size):
                written += len(chunk)
                if written > MAX_UPLOAD_BYTES:
                    raise ValueError(
                        f"Image is too large (maximum {MAX_UPLOAD_BYTES // (1024 * 1024)} MB)."
                    )
                buf.write(chunk)
    except ValueError:
        if os.path.exists(full_path):
            os.remove(full_path)  # never keep a partial file
        raise
    return f"{PHOTO_URL_PREFIX}/{filename}"


def delete_image(url_path: str) -> None:
    """Delete a previously saved image, given the path returned by save_image()."""
    full_path = url_path.lstrip("/")
    if os.path.exists(full_path):
        os.remove(full_path)
