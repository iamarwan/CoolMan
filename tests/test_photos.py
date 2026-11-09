import os
from pathlib import Path

from tests.conftest import admin_post, add_cooler, admin_login, auth, jpeg_bytes, register


def _upload_dir() -> Path:
    return Path(os.environ["SABIL_UPLOAD_DIR"])


async def test_photo_resized_thumbnailed_and_hidden_until_approved(client):
    cid = await add_cooler()
    user = await register(client, "snap")
    r = await client.post(
        f"/coolers/{cid}/photos",
        files={"file": ("big.jpg", jpeg_bytes(), "image/jpeg")},
        data={"photo_category": "Cups"},
        headers=auth(user["access_token"]),
    )
    assert r.status_code == 201, r.text
    photo = r.json()
    assert photo["is_approved"] is False and photo["photo_category"] == "Cups"
    assert photo["thumb_path"].endswith("_t.jpg")

    from PIL import Image

    full = Image.open(_upload_dir() / photo["file_path"].removeprefix("/uploads/"))
    thumb = Image.open(_upload_dir() / photo["thumb_path"].removeprefix("/uploads/"))
    assert max(full.size) == 1600 and max(thumb.size) == 400

    # Not visible publicly until approved.
    assert (await client.get(f"/coolers/{cid}")).json()["photos"] == []
    await admin_login(client)
    await admin_post(client, f"/admin/photos/{photo['id']}/approve")
    assert len((await client.get(f"/coolers/{cid}")).json()["photos"]) == 1

    # Deleting removes the files from disk.
    await admin_post(client, f"/admin/photos/{photo['id']}/delete")
    assert not (_upload_dir() / photo["file_path"].removeprefix("/uploads/")).exists()


async def test_non_image_rejected(client):
    cid = await add_cooler()
    user = await register(client, "fake")
    r = await client.post(
        f"/coolers/{cid}/photos",
        files={"file": ("x.jpg", b"definitely not an image", "image/jpeg")},
        headers=auth(user["access_token"]),
    )
    assert r.status_code == 400 and r.json()["code"] == "photo_invalid"
