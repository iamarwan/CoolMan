"""50 m rule: contributions only count when the user is at the cooler."""

import pytest

from app.config import get_settings
from tests.conftest import add_cooler, auth, jpeg_bytes, register

COOLER = (29.9600, 31.2500)
NEAR = {"lat": 29.96010, "lng": 31.25005, "accuracy": 12}   # ~12 m away
FAR = {"lat": 29.96200, "lng": 31.25000, "accuracy": 12}    # ~220 m away
BLURRY = {"lat": 29.96010, "lng": 31.25005, "accuracy": 90}  # close, but GPS unsure


@pytest.fixture(autouse=True)
def distance_rule_on(monkeypatch):
    monkeypatch.setattr(get_settings(), "max_action_distance_m", 50)


async def _user(client, name):
    return auth((await register(client, name))["access_token"])


async def test_confirm_requires_being_near(client):
    cid = await add_cooler("C", *COOLER)
    h = await _user(client, "walker")

    r = await client.post(f"/coolers/{cid}/confirm", headers=h)
    assert r.status_code == 400 and r.json()["code"] == "location_required"

    r = await client.post(f"/coolers/{cid}/confirm", json=FAR, headers=h)
    assert r.status_code == 403 and r.json()["code"] == "too_far"
    assert 200 <= r.json()["distance_m"] <= 240 and r.json()["max_distance_m"] == 50

    r = await client.post(f"/coolers/{cid}/confirm", json=BLURRY, headers=h)
    assert r.status_code == 400 and r.json()["code"] == "location_inaccurate"

    # None of the refused attempts earned points or started the cooldown.
    r = await client.post(f"/coolers/{cid}/confirm", json=NEAR, headers=h)
    assert r.status_code == 200 and r.json()["trust_score"] == 5


async def test_status_report_requires_being_near(client):
    cid = await add_cooler("C", *COOLER)
    h = await _user(client, "reporter")
    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Empty", "location": FAR}, headers=h)
    assert r.status_code == 403 and r.json()["code"] == "too_far"
    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Empty", "location": NEAR}, headers=h)
    assert r.status_code == 200 and r.json()["pending_status"] == "Empty"


async def test_photo_requires_being_near(client):
    cid = await add_cooler("C", *COOLER)
    h = await _user(client, "snapper")
    files = {"file": ("a.jpg", jpeg_bytes((200, 200)), "image/jpeg")}
    r = await client.post(f"/coolers/{cid}/photos", files=files, data={"lat": FAR["lat"], "lng": FAR["lng"], "accuracy": 10}, headers=h)
    assert r.status_code == 403 and r.json()["code"] == "too_far"
    r = await client.post(f"/coolers/{cid}/photos", files=files, data={"lat": NEAR["lat"], "lng": NEAR["lng"], "accuracy": 10}, headers=h)
    assert r.status_code == 201


async def test_new_cooler_must_be_placed_where_the_user_stands(client):
    h = await _user(client, "adder")
    body = {"name": "New one", "latitude": COOLER[0], "longitude": COOLER[1]}
    r = await client.post("/coolers", json={**body, "user_location": FAR}, headers=h)
    assert r.status_code == 403 and r.json()["code"] == "too_far"
    r = await client.post("/coolers", json=body, headers=h)
    assert r.status_code == 400 and r.json()["code"] == "location_required"
    r = await client.post("/coolers", json={**body, "user_location": NEAR}, headers=h)
    assert r.status_code == 201


async def test_rule_can_be_switched_off_for_development(client, monkeypatch):
    monkeypatch.setattr(get_settings(), "max_action_distance_m", 0)
    cid = await add_cooler("C", *COOLER)
    h = await _user(client, "devuser")
    assert (await client.post(f"/coolers/{cid}/confirm", headers=h)).status_code == 200


# ── A user sees their own cooler while it waits for review ───────────────────

BBOX = {"min_lat": 29.9, "min_lng": 31.2, "max_lat": 30.0, "max_lng": 31.3}


async def test_own_pending_cooler_is_visible_only_to_its_author(client):
    h = await _user(client, "author")
    other = await _user(client, "stranger")
    c = (await client.post("/coolers", json={"name": "Mine", "latitude": COOLER[0], "longitude": COOLER[1], "user_location": NEAR}, headers=h)).json()

    mine = (await client.get("/coolers/map", params=BBOX, headers=h)).json()["pins"]
    assert [(p["id"], p["pending"]) for p in mine] == [(c["id"], True)]
    assert (await client.get(f"/coolers/{c['id']}", headers=h)).status_code == 200

    assert (await client.get("/coolers/map", params=BBOX, headers=other)).json()["pins"] == []
    assert (await client.get("/coolers/map", params=BBOX)).json()["pins"] == []
    assert (await client.get(f"/coolers/{c['id']}", headers=other)).status_code == 404
    assert (await client.get(f"/coolers/{c['id']}")).status_code == 404

    # A pending cooler cannot be confirmed, even by its author.
    assert (await client.post(f"/coolers/{c['id']}/confirm", json=NEAR, headers=h)).status_code == 404


async def test_detail_reports_how_often_a_cooler_was_confirmed(client):
    cid = await add_cooler("C", *COOLER)
    for name in ("one", "two", "three"):
        await client.post(f"/coolers/{cid}/confirm", json=NEAR, headers=await _user(client, f"user_{name}"))
    assert (await client.get(f"/coolers/{cid}")).json()["confirmations_count"] == 3


async def test_stats_include_my_rank(client):
    a = await _user(client, "first")
    b = await _user(client, "second")
    cid = await add_cooler("C", *COOLER)
    await client.post(f"/coolers/{cid}/confirm", json=NEAR, headers=a)
    assert (await client.get("/users/me/stats", headers=a)).json()["rank"] == 1
    assert (await client.get("/users/me/stats", headers=b)).json()["rank"] == 2
