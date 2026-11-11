from tests.conftest import admin_post, add_cooler, admin_login, auth, register, set_trust

BBOX = {"min_lat": 29.9, "min_lng": 31.2, "max_lat": 30.0, "max_lng": 31.3}


async def test_map_returns_only_approved_pins_inside_bbox(client):
    inside = await add_cooler("Inside", 29.96, 31.25)
    await add_cooler("Outside", 30.5, 31.25)
    await add_cooler("Pending", 29.95, 31.24, approved=False)

    r = await client.get("/coolers/map", params=BBOX)
    assert r.status_code == 200
    body = r.json()
    assert [p["id"] for p in body["pins"]] == [inside]
    assert body["truncated"] is False
    assert set(body["pins"][0]) == {"id", "lat", "lng", "status", "has_cups", "sponsored", "pending"}


async def test_map_truncation_and_invalid_bbox(client):
    for i in range(3):
        await add_cooler(f"C{i}", 29.96 + i * 0.001, 31.25)
    r = await client.get("/coolers/map", params={**BBOX, "limit": 2})
    assert len(r.json()["pins"]) == 2 and r.json()["truncated"] is True

    r = await client.get("/coolers/map", params={**BBOX, "min_lat": 31})
    assert r.status_code == 422


async def test_new_user_submission_is_pending_and_hidden(client):
    user = await register(client, "newbie")
    r = await client.post(
        "/coolers",
        json={"name": "Road 9 / Street & Co", "latitude": 29.96, "longitude": 31.25},
        headers=auth(user["access_token"]),
    )
    assert r.status_code == 201, r.text
    cooler = r.json()
    assert cooler["is_approved"] is False

    assert (await client.get("/coolers/map", params=BBOX)).json()["pins"] == []
    assert (await client.get(f"/coolers/{cooler['id']}")).status_code == 404

    mine = await client.get("/coolers/my", headers=auth(user["access_token"]))
    assert [c["id"] for c in mine.json()] == [cooler["id"]]


async def test_duplicate_guard_15m(client):
    user = await register(client, "dup")
    h = auth(user["access_token"])
    await add_cooler("Existing", 29.96, 31.25)

    near = await client.post("/coolers", json={"name": "Near", "latitude": 29.96005, "longitude": 31.25}, headers=h)
    assert near.status_code == 409 and near.json()["code"] == "cooler_duplicate"

    far = await client.post("/coolers", json={"name": "Far", "latitude": 29.9604, "longitude": 31.25}, headers=h)
    assert far.status_code == 201  # ~44 m away


async def test_trusted_user_auto_approved_and_rewarded(client):
    user = await register(client, "pro")
    await set_trust("pro", 500)
    r = await client.post(
        "/coolers",
        json={"name": "بجوار مسجد التوحيد", "latitude": 29.97, "longitude": 31.26},
        headers=auth(user["access_token"]),
    )
    assert r.status_code == 201 and r.json()["is_approved"] is True
    me = await client.get("/auth/me", headers=auth(user["access_token"]))
    assert me.json()["trust_score"] == 550


async def test_name_validation(client):
    user = await register(client, "val")
    r = await client.post(
        "/coolers",
        json={"name": "<script>alert(1)</script>", "latitude": 29.96, "longitude": 31.25},
        headers=auth(user["access_token"]),
    )
    assert r.status_code == 422


async def test_admin_approve_rewards_and_reject_penalizes(client):
    await admin_login(client)
    good = await register(client, "good")
    bad = await register(client, "bad")
    c1 = (await client.post("/coolers", json={"name": "A", "latitude": 29.96, "longitude": 31.25}, headers=auth(good["access_token"]))).json()
    c2 = (await client.post("/coolers", json={"name": "B", "latitude": 29.97, "longitude": 31.25}, headers=auth(bad["access_token"]))).json()

    queue = await client.get("/admin/queue")
    assert queue.status_code == 200 and "New coolers (2)" in queue.text

    assert (await admin_post(client, f"/admin/coolers/{c1['id']}/approve")).status_code == 303
    assert (await admin_post(client, f"/admin/coolers/{c2['id']}/reject")).status_code == 303

    assert (await client.get("/auth/me", headers=auth(good["access_token"]))).json()["trust_score"] == 50
    assert (await client.get("/auth/me", headers=auth(bad["access_token"]))).json()["trust_score"] == 0
    assert (await client.get(f"/coolers/{c1['id']}")).status_code == 200


async def test_search_escapes_wildcards(client):
    await add_cooler("Maadi Metro", 29.96, 31.25)
    await add_cooler("100% Pure", 29.97, 31.25)
    r = await client.get("/coolers/search", params={"q": "%"})
    assert [c["name"] for c in r.json()] == ["100% Pure"]
    r = await client.get("/coolers/search", params={"q": "metro", "lat": 29.96, "lng": 31.25})
    assert [c["name"] for c in r.json()] == ["Maadi Metro"]


async def test_unknown_or_malformed_id(client):
    assert (await client.get("/coolers/00000000-0000-0000-0000-000000000000")).status_code == 404
    assert (await client.get("/coolers/not-a-uuid")).status_code == 422
