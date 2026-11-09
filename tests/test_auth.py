from tests.conftest import auth, register


async def test_register_login_me(client):
    user = await register(client, "alice")
    assert user["trust_score"] == 0 and user["access_token"]

    r = await client.post("/auth/login", json={"username": "alice", "password": "password123"})
    assert r.status_code == 200

    r = await client.get("/auth/me", headers=auth(user["access_token"]))
    assert r.status_code == 200 and r.json()["username"] == "alice"


async def test_duplicate_username(client):
    await register(client, "bob")
    r = await client.post("/auth/register", json={"username": "bob", "password": "password123"})
    assert r.status_code == 409 and r.json()["code"] == "username_taken"


async def test_bad_login_and_missing_token(client):
    await register(client, "carol")
    r = await client.post("/auth/login", json={"username": "carol", "password": "wrongpass1"})
    assert r.status_code == 401 and r.json()["code"] == "invalid_credentials"

    r = await client.get("/auth/me")
    assert r.status_code == 401 and r.json()["code"] == "auth_required"

    r = await client.get("/auth/me", headers=auth("not.a.token"))
    assert r.status_code == 401 and r.json()["code"] == "token_invalid"


async def test_user_token_cannot_access_admin(client):
    user = await register(client, "dave")
    r = await client.get("/admin/queue", headers=auth(user["access_token"]))
    assert r.status_code == 303 and r.headers["location"].startswith("/admin/login")


async def test_production_refuses_insecure_defaults():
    import pytest

    from app.config import Settings

    with pytest.raises(RuntimeError):
        Settings(env="production").validate_for_runtime()
    Settings(
        env="production",
        jwt_secret="x" * 40,
        admin_password="a-very-long-password",
        cors_origins="",
    ).validate_for_runtime()
