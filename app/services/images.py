"""Photo upload handling: validate, auto-rotate, strip metadata (including GPS),
resize, and write a full-size image plus a small thumbnail as JPEG."""

import io
import os
import uuid
from pathlib import Path

from fastapi import UploadFile
from fastapi.concurrency import run_in_threadpool
from PIL import Image, ImageOps, UnidentifiedImageError

from app.config import get_settings
from app.errors import ApiError

FULL_MAX_PX = 1600
THUMB_MAX_PX = 400
Image.MAX_IMAGE_PIXELS = 40_000_000  # refuse "decompression bomb" images

URL_PREFIX = "/uploads"


def _photos_dir() -> Path:
    d = Path(get_settings().upload_dir) / "photos"
    d.mkdir(parents=True, exist_ok=True)
    return d


async def read_limited(file: UploadFile) -> bytes:
    limit = get_settings().max_upload_mb * 1024 * 1024
    data = await file.read(limit + 1)
    if len(data) > limit:
        raise ApiError(413, "photo_too_large", f"Photo is larger than {get_settings().max_upload_mb} MB.")
    if not data:
        raise ApiError(400, "photo_invalid", "Empty file.")
    return data


def _process(data: bytes) -> tuple[str, str]:
    try:
        img = Image.open(io.BytesIO(data))
        img.load()
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError):
        raise ApiError(400, "photo_invalid", "This file is not a supported image.")

    img = ImageOps.exif_transpose(img).convert("RGB")  # rotation fixed, metadata dropped
    stem = uuid.uuid4().hex
    out = _photos_dir()

    full = img.copy()
    full.thumbnail((FULL_MAX_PX, FULL_MAX_PX))
    full.save(out / f"{stem}.jpg", "JPEG", quality=82, optimize=True, progressive=True)

    thumb = img.copy()
    thumb.thumbnail((THUMB_MAX_PX, THUMB_MAX_PX))
    thumb.save(out / f"{stem}_t.jpg", "JPEG", quality=75, optimize=True)

    return f"{URL_PREFIX}/photos/{stem}.jpg", f"{URL_PREFIX}/photos/{stem}_t.jpg"


async def save_photo(file: UploadFile) -> tuple[str, str]:
    """Returns (file_url_path, thumb_url_path)."""
    data = await read_limited(file)
    return await run_in_threadpool(_process, data)


def delete_photo_files(*url_paths: str | None) -> None:
    base = Path(get_settings().upload_dir).resolve()
    for url_path in url_paths:
        if not url_path or not url_path.startswith(URL_PREFIX + "/"):
            continue
        target = (base / url_path[len(URL_PREFIX) + 1 :]).resolve()
        if base in target.parents and target.is_file():
            os.remove(target)
