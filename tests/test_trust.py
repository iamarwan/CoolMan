from tests.conftest import admin_post, add_cooler, admin_login, auth, register, set_trust


async def test_confirm_rewards_once_per_hour(client):
    cid = await add_cooler()
    user = await register(client, "conf")
    h = auth(user["access_token"])

    r = await client.post(f"/coolers/{cid}/confirm", headers=h)
    assert r.status_code == 200 and r.json()["trust_score"] == 5

    r = await client.post(f"/coolers/{cid}/confirm", headers=h)
    assert r.status_code == 429
    assert r.json()["code"] == "confirm_cooldown" and r.json()["retry_after_minutes"] >= 1


async def test_status_report_untrusted_is_pending_and_cooled_down(client):
    cid = await add_cooler()
    user = await register(client, "rep")
    h = auth(user["access_token"])

    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Empty"}, headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "Working" and r.json()["pending_status"] == "Empty"

    # Previously this could be repeated forever for +10 each time.
    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Broken"}, headers=h)
    assert r.status_code == 429 and r.json()["code"] == "status_report_cooldown"
    assert (await client.get("/auth/me", headers=h)).json()["trust_score"] == 10


async def test_admin_approves_pending_status_and_resets_confirmations(client):
    await admin_login(client)
    cid = await add_cooler()
    confirmer = await register(client, "confirmer")
    reporter = await register(client, "reporter")
    await client.post(f"/coolers/{cid}/confirm", headers=auth(confirmer["access_token"]))
    await client.patch(f"/coolers/{cid}/status", json={"status": "Empty"}, headers=auth(reporter["access_token"]))

    assert (await admin_post(client, f"/admin/coolers/{cid}/approve")).status_code == 303
    detail = (await client.get(f"/coolers/{cid}")).json()
    assert detail["status"] == "Empty" and detail["pending_status"] is None

    # Status changed, so the earlier confirmer may confirm again.
    r = await client.post(f"/coolers/{cid}/confirm", headers=auth(confirmer["access_token"]))
    assert r.status_code == 200


async def test_trusted_status_report_applies_instantly(client):
    cid = await add_cooler()
    user = await register(client, "trusty")
    await set_trust("trusty", 600)
    r = await client.patch(f"/coolers/{cid}/status", json={"status": "Broken"}, headers=auth(user["access_token"]))
    assert r.json()["status"] == "Broken" and r.json()["pending_status"] is None


async def test_my_stats(client):
    cid = await add_cooler()
    user = await register(client, "stats")
    h = auth(user["access_token"])
    await client.post(f"/coolers/{cid}/confirm", headers=h)
    s = (await client.get("/users/me/stats", headers=h)).json()
    assert s["confirmations"] == 1 and s["trust_score"] == 5 and s["trusted_threshold"] == 500


async def test_leaderboard_order(client):
    await register(client, "low")
    await register(client, "high")
    await set_trust("high", 99)
    r = await client.get("/users/leaderboard")
    assert [e["username"] for e in r.json()] == ["high", "low"]
