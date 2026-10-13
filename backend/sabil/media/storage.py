# media/storage.py
#
# Saving and deleting uploaded image files on disk. Knows nothing about coolers
# or the database, so it can be reused in any project.

import os
import shutil
import uuid

from fastapi import UploadFile

from sabil.core.config import ALLOWED_IMAGE_TYPES, PHOTO_DIR, PHOTO_URL_PREFIX


def ensure_upload_dirs() -> None:
    os.makedirs(PHOTO_DIR, exist_ok=True)


def save_image(file: UploadFile, name_prefix: str) -> str:
    """Write an uploaded image to disk and return the URL path it is served at.

    Raises ValueError if the file is not a JPEG, PNG or WebP image.

    The file extension comes from the validated content type, never from the
    user-supplied filename (a crafted filename could otherwise write outside the
    upload folder), and the name contains a random id so two uploads can never
    overwrite each other.
    """
    ext = ALLOWED_IMAGE_TYPES.get(file.content_type)
    if ext is None:
        raise ValueError("Invalid file type. Use JPEG, PNG, or WebP.")

    filename = f"{name_prefix}_{uuid.uuid4().hex}.{ext}"
    with open(os.path.join(PHOTO_DIR, filename), "wb") as buf:
        shutil.copyfileobj(file.file, buf)
    return f"{PHOTO_URL_PREFIX}/{filename}"


def delete_image(url_path: str) -> None:
    """Delete a previously saved image, given the path returned by save_image()."""
    full_path = url_path.lstrip("/")
    if os.path.exists(full_path):
        os.remove(full_path)
