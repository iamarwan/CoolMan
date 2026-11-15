"""Security regression tests: each test is an attack that used to work."""

import asyncio

from sqlalchemy import text

from app.db import SessionLocal
from tests.conftest import add_cooler, admin_login, admin_post, auth, jpeg_bytes, register, set_trust


# ── Accounts ─────────────────────────────────────────────────────────────────

async def test_login_is_locked_after_repeated_wrong_passwords(client):
    await register(client, "victim")
    for _ in range(10):
        r = await client.post("/auth/login", json={"username": "victim", "password": "wrong-pass-1"})
        assert r.status_code == 401
    # Guessing continues to be refused, even with the right password, until the window passes.
    r = await client.post("/auth/login", json={"username": "victim", "password": "password123"})
    assert r.status_code == 429 and r.json()["code"] == "too_many_attempts"
    assert r.json()["retry_after_minutes"] >= 1


async def test_usernames_are_case_insensitive(client):
    await register(client, "Alice")
    r = await client.post("/auth/register", json={"username": "alice", "password": "password123"})
    assert r.status_code == 409  # no look-alike "alice" next to "Alice"
    r = await client.post("/auth/login", json={"username": "ALICE", "password": "password123"})
    assert r.status_code == 200 and r.json()["username"] == "Alice"


async def test_mass_registration_from_one_address_is_limited(client):
    codes = []
    for i in range(22):
        r = await client.post("/auth/register", json={"username": f"bot_{i}", "password": "password123"})
        codes.append(r.status_code)
    assert codes[:20] == [201] * 20
    assert codes[20:] == [429, 429]


async def test_password_hashes_are_versioned_and_old_ones_upgrade_on_login(client):
    from app.security import _hash_legacy_for_tests

    await register(client, "olduser")
    async with SessionLocal() as db:
        await db.execute(
            text("UPDATE users SET hashed_password = :h WHERE username = 'olduser'"),
            {"h": _hash_legacy_for_tests("password123")},
        )
        await db.commit()

    r = await client.post("/auth/login", json={"username": "olduser", "password": "password123"})
    assert r.status_code == 200
    async with SessionLocal() as db:
        stored = await db.scalar(text("SELECT hashed_password FROM users WHERE username = 'olduser'"))
    assert stored.startswith("pbkdf2_sha256$")


async def test_delete_account_requires_password_and_removes_the_user(client):
    user = await register(client, "leaver")
    h = auth(user["access_token"])
    cooler = (await client.post("/coolers", json={"name": "Mine", "latitude": 29.96, "longitude": 31.25}, headers=h)).json()

    r = await client.request("DELETE", "/auth/me", json={"password": "not-my-password"}, headers=h)
    assert r.status_code == 403 and r.json()["code"] == "wrong_password"

    r = await client.request("DELETE", "/auth/me", json={"password": "password123"}, headers=h)
    assert r.status_code == 204
    assert (await client.get("/auth/me", headers=h)).status_code == 401
    assert (await client.post("/auth/login", json={"username": "leaver", "password": "password123"})).status_code == 401

    # Their contributions stay, without a link to the deleted account.
    async with SessionLocal() as db:
        owner = await db.scalar(text("SELECT user_id FROM water_coolers WHERE id = :i"), {"i": cooler["id"]})
        users = await db.scalar(text("SELECT count(*) FROM users WHERE username = 'leaver'"))
    assert owner is None and users == 0


async def test_public_account_deletion_and_privacy_pages_exist(client):
    assert (await client.get("/privacy")).status_code == 200
    page = await client.get("/account/delete")
    assert page.status_code == 200 and "password" in page.text.lower()

    await register(client, "webleaver")
    r = await client.post("/account/delete", data={"username": "webleaver", "password": "password123"})
    assert r.status_code == 200 and "deleted" in r.text.lower()
    assert (await client.post("/auth/login", json={"username": "webleaver", "password": "password123"})).status_code == 401


# ── Trust points cannot be farmed ────────────────────────────────────────────

async def test_status_report_points_only_after_admin_accepts(client):
    cid = await add_cooler()
    user = await register(client, "reporter")
    h = auth(user["access_token"])

    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Empty"}, headers=h)
    assert r.status_code == 200
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 0  # was +10 immediately

    await admin_login(client)
    await admin_post(client, f"/admin/coolers/{cid}/approve")
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 10


async def test_dismissed_status_report_earns_nothing(client):
    cid = await add_cooler()
    user = await register(client, "wrongreport")
    h = auth(user["access_token"])
    await client.patch(f"/coolers/{cid}/status", json={"status": "Broken"}, headers=h)
    await admin_login(client)
    await admin_post(client, f"/admin/coolers/{cid}/reject-status")
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 0


async def test_reporting_the_current_status_is_rejected(client):
    cid = await add_cooler()
    user = await register(client, "samestatus")
    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Working"}, headers=auth(user["access_token"]))
    assert r.status_code == 400 and r.json()["code"] == "status_unchanged"


async def test_daily_cap_on_rewarded_actions(client):
    user = await register(client, "farmer")
    h = auth(user["access_token"])
    awarded = []
    for i in range(23):
        cid = await add_cooler(f"C{i}", 29.90 + i * 0.002, 31.25)
        r = await client.post(f"/coolers/{cid}/confirm", headers=h)
        assert r.status_code == 200
        awarded.append(r.json()["points_awarded"])
    assert awarded == [5] * 20 + [0] * 3
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 100


async def test_two_simultaneous_confirms_reward_once(client):
    cid = await add_cooler()
    user = await register(client, "racer")
    h = auth(user["access_token"])
    results = await asyncio.gather(*[client.post(f"/coolers/{cid}/confirm", headers=h) for _ in range(5)])
    assert sorted(r.status_code for r in results) == [200, 429, 429, 429, 429]
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 5


async def test_confirmation_count_survives_a_status_change(client):
    cid = await add_cooler()
    user = await register(client, "counter")
    h = auth(user["access_token"])
    await client.post(f"/coolers/{cid}/confirm", headers=h)
    await admin_login(client)
    await admin_post(client, f"/admin/coolers/{cid}/status", {"status": "Empty"})
    await admin_post(client, f"/admin/coolers/{cid}/status", {"status": "Working"})

    stats = (await client.get("/users/me/stats", headers=h)).json()
    assert stats["confirmations"] == 1  # used to drop to 0
    # ...and the status change still lets them confirm again right away.
    assert (await client.post(f"/coolers/{cid}/confirm", headers=h)).status_code == 200


# ── Data exposure ────────────────────────────────────────────────────────────

async def test_my_coolers_does_not_show_other_peoples_unapproved_photos(client):
    owner = await register(client, "owner")
    other = await register(client, "other")
    await set_trust("owner", 600)  # owner's cooler goes live at once
    cooler = (await client.post("/coolers", json={"name": "Shared", "latitude": 29.96, "longitude": 31.25},
                                headers=auth(owner["access_token"]))).json()
    await client.post(f"/coolers/{cooler['id']}/photos",
                      files={"file": ("a.jpg", jpeg_bytes((200, 200)), "image/jpeg")},
                      headers=auth(other["access_token"]))

    mine = (await client.get("/coolers/my", headers=auth(owner["access_token"]))).json()
    assert mine[0]["photos"] == []


async def test_responses_forbid_content_sniffing(client):
    r = await client.get("/health")
    assert r.headers["x-content-type-options"] == "nosniff"


# ── Admin ────────────────────────────────────────────────────────────────────

async def test_admin_login_is_locked_after_repeated_failures(client, monkeypatch):
    import app.admin_web.routes as routes

    async def no_sleep(_):
        return None

    monkeypatch.setattr(routes.asyncio, "sleep", no_sleep)
    for _ in range(5):
        r = await client.post("/admin/login", data={"username": "admin", "password": "guess"})
        assert r.status_code == 401
    r = await client.post("/admin/login", data={"username": "admin", "password": "admin123"})
    assert r.status_code == 429
