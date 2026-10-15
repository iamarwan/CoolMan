# tests/test_visibility_and_limits.py
#
# Covers findings BE-01 (photos not lost to the rate limit), BE-03 (unapproved
# photos are private), BE-04 (unapproved coolers are private), BE-07 (login
# limit) and the cooler-with-photos delete fix.

import os
import random

from tests.conftest import reset_limits, tiny_png


def _new_cooler(client, headers, name="Test cooler"):
    lat = 29.0 + random.random() * 0.8
    r = client.post("/coolers", headers=headers,
                    json={"name": name, "latitude": lat, "longitude": 31.0 + random.random() * 0.8})
    assert r.status_code == 201, r.text
    return r.json()["id"]


def _upload(client, headers, cooler_id):
    return client.post(f"/coolers/{cooler_id}/photos", headers=headers,
                       files={"file": ("a.png", tiny_png(), "image/png")},
                       data={"photo_category": "Cooler"})


def test_unapproved_cooler_is_private(client, make_user, admin):
    owner, other = make_user("own"), make_user("oth")
    cid = _new_cooler(client, owner)
    assert client.get(f"/coolers/{cid}").status_code == 404                   # anonymous
    assert client.get(f"/coolers/{cid}", headers=other).status_code == 404    # someone else
    assert client.get(f"/coolers/{cid}", headers=owner).status_code == 200    # submitter
    assert client.get(f"/coolers/{cid}", headers=admin).status_code == 200    # admin
    assert client.get(f"/coolers/{cid}/photos").status_code == 404
    client.patch(f"/admin/coolers/{cid}/approve", headers=admin)
    assert client.get(f"/coolers/{cid}").status_code == 200                   # now public


def test_unapproved_photo_file_is_private(client, make_user, admin):
    owner, other = make_user("own"), make_user("oth")
    cid = _new_cooler(client, owner)
    assert _upload(client, owner, cid).status_code == 201
    photo = client.get(f"/admin/coolers/{cid}/photos", headers=admin).json()[0]
    url = photo["file_path"]

    assert client.get(url).status_code == 404
    assert client.get(url, headers=other).status_code == 404
    r = client.get(url, headers=owner)
    assert r.status_code == 200 and "no-store" in r.headers["cache-control"]
    assert client.get(url, headers=admin).status_code == 200
    assert client.get("/uploads/photos/..%2Fphotos%2Fx.png").status_code == 404

    client.patch(f"/admin/photos/{photo['id']}/approve", headers=admin)
    assert client.get(url).status_code == 404          # photo approved, cooler is not
    client.patch(f"/admin/coolers/{cid}/approve", headers=admin)
    r = client.get(url)
    assert r.status_code == 200 and "max-age" in r.headers["cache-control"]


def test_adding_photos_is_not_blocked_by_the_create_limit(client, make_user):
    owner = make_user()
    cid = _new_cooler(client, owner)
    codes = [_upload(client, owner, cid).status_code for _ in range(6)]
    assert codes == [201] * 6
    # creating coolers is still limited to 3 per minute
    results = [client.post("/coolers", headers=owner,
                           json={"name": f"x{i}", "latitude": 28.0 + i * 0.01, "longitude": 30.5}).status_code
               for i in range(3)]
    assert results[-1] == 429


def test_login_attempts_are_limited(client):
    codes = [client.post("/auth/login", json={"username": "nobody_x", "password": "wrongpass1"}).status_code
             for _ in range(12)]
    assert codes[:10] == [401] * 10 and codes[10:] == [429, 429]
    assert client.post("/auth/admin/login", json={"username": "admin", "password": "x"}).status_code == 429
    reset_limits()
    assert client.post("/auth/admin/login", json={"username": "admin", "password": "admin123"}).status_code == 200


def test_deleting_a_cooler_removes_its_photos_and_files(client, make_user, admin):
    owner = make_user()
    cid = _new_cooler(client, owner)
    _upload(client, owner, cid)
    url = client.get(f"/admin/coolers/{cid}/photos", headers=admin).json()[0]["file_path"]
    assert os.path.isfile(url.lstrip("/"))
    assert client.delete(f"/admin/coolers/{cid}", headers=admin).status_code == 200
    assert not os.path.exists(url.lstrip("/"))
