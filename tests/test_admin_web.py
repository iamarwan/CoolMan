"""Web admin panel: login, CSRF, pages and actions."""

from app.admin_web.auth import COOKIE
from tests.conftest import add_cooler, admin_login, admin_post, auth, jpeg_bytes, register


async def test_login_required_and_redirects_back(client):
    r = await client.get("/admin/coolers?q=metro")
    assert r.status_code == 303
    assert r.headers["location"] == "/admin/login?next=/admin/coolers%3Fq%3Dmetro"


async def test_wrong_password_is_rejected(client):
    r = await client.post("/admin/login", data={"username": "admin", "password": "nope"})
    assert r.status_code == 401 and "Wrong username or password" in r.text
    assert COOKIE not in client.cookies


async def test_login_sets_strict_httponly_cookie_and_blocks_open_redirect(client):
    r = await client.post(
        "/admin/login",
        data={"username": "admin", "password": "admin123", "next": "//evil.example/x"},
    )
    assert r.status_code == 303 and r.headers["location"] == "/admin/queue"
    cookie = r.headers["set-cookie"].lower()
    assert "httponly" in cookie and "samesite=strict" in cookie and "path=/admin" in cookie


async def test_actions_require_csrf_token(client):
    cid = await add_cooler(approved=False)
    await admin_login(client)
    r = await client.post(f"/admin/coolers/{cid}/approve", data={"csrf": "forged"})
    assert r.status_code == 403
    assert (await client.get(f"/coolers/{cid}")).status_code == 404  # still not approved


async def test_pages_render_with_security_headers(client):
    cid = await add_cooler("Maadi Metro Station")
    await admin_login(client)
    for path in ["/admin/queue", "/admin/coolers", f"/admin/coolers/{cid}", "/admin/sponsors"]:
        r = await client.get(path)
        assert r.status_code == 200, path
        assert r.headers["x-frame-options"] == "DENY"
        assert "frame-ancestors 'none'" in r.headers["content-security-policy"]
    assert "Maadi Metro Station" in (await client.get("/admin/coolers?q=metro")).text


async def test_queue_shows_submitter_and_photos(client):
    user = await register(client, "reporter1")
    h = auth(user["access_token"])
    c = (await client.post("/coolers", json={"name": "Road 9", "latitude": 29.96, "longitude": 31.25}, headers=h)).json()
    await client.post(f"/coolers/{c['id']}/photos", files={"file": ("a.jpg", jpeg_bytes((200, 200)), "image/jpeg")}, headers=h)
    await admin_login(client)
    page = (await client.get("/admin/queue")).text
    assert "Road 9" in page and "reporter1" in page and "_t.jpg" in page


async def test_status_sponsor_and_photo_management(client):
    cid = await add_cooler("Corniche")
    await admin_login(client)

    r = await admin_post(client, "/admin/sponsors", {"name": "El-Borg Pharmacy", "sponsor_type": "Business", "contact": "+20 2 1234"})
    assert r.status_code == 303
    sponsors = (await client.get("/sponsors")).json()
    sid = sponsors[0]["id"]

    await admin_post(client, f"/admin/sponsors/{sid}/verify", {"verified": "true"})
    await admin_post(client, f"/admin/coolers/{cid}/sponsor", {"sponsor_id": sid})
    await admin_post(client, f"/admin/coolers/{cid}/status", {"status": "Broken"})
    r = await admin_post(
        client, f"/admin/coolers/{cid}/photos",
        {"photo_category": "Cooler"},
        files={"file": ("p.jpg", jpeg_bytes((300, 300)), "image/jpeg")},
    )
    assert r.status_code == 303 and "Photo+added" in r.headers["location"]

    detail = (await client.get(f"/coolers/{cid}")).json()
    assert detail["status"] == "Broken"
    assert detail["sponsor"]["name"] == "El-Borg Pharmacy" and detail["sponsor"]["verified"] is True
    assert len(detail["photos"]) == 1  # admin uploads are public immediately

    # Removing the sponsor, then deleting it and the cooler.
    await admin_post(client, f"/admin/coolers/{cid}/sponsor", {"sponsor_id": ""})
    assert (await client.get(f"/coolers/{cid}")).json()["sponsor"] is None
    await admin_post(client, f"/admin/sponsors/{sid}/delete")
    assert (await client.get("/sponsors")).json() == []
    await admin_post(client, f"/admin/coolers/{cid}/delete")
    assert (await client.get(f"/coolers/{cid}")).status_code == 404


async def test_invalid_upload_shows_error_message(client):
    cid = await add_cooler()
    await admin_login(client)
    r = await admin_post(
        client, f"/admin/coolers/{cid}/photos", files={"file": ("x.jpg", b"nope", "image/jpeg")}
    )
    assert r.status_code == 303 and "error=1" in r.headers["location"]


async def test_reject_then_restore(client):
    cid = await add_cooler()
    await admin_login(client)
    await admin_post(client, f"/admin/coolers/{cid}/reject")
    assert (await client.get(f"/coolers/{cid}")).status_code == 404
    await admin_post(client, f"/admin/coolers/{cid}/restore")
    assert (await client.get(f"/coolers/{cid}")).status_code == 200


async def test_logout_clears_session(client):
    await admin_login(client)
    r = await admin_post(client, "/admin/logout")
    assert r.status_code == 303
    assert (await client.get("/admin/queue")).status_code == 303
