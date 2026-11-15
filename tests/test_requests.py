"""Build-a-sabil requests: sent from the app, followed up in the admin panel."""

from app.admin_web.auth import COOKIE
from tests.conftest import admin_login, admin_post, auth, register


def form(**over) -> dict:
    body = {
        "package": "full",
        "taps": 3,
        "extras": ["filter", "shade", "filter"],
        "timing": "month",
        "purpose": "memorial",
        "dedication_name": "  Hagg Mahmoud   Saleh ",
        "plaque_text": "اشرب وادعيله",
        "show_publicly": True,
        "governorate": "cairo",
        "area": "Maadi",
        "address_notes": "Road 9, next to the bakery",
        "latitude": 29.96,
        "longitude": 31.25,
        "place_type": "street",
        "permission": "has_permission",
        "electricity": "yes",
        "water_line": "unsure",
        "contact_name": "Mona",
        "phone": "+20 101 234 5678",
        "contact_method": "whatsapp",
        "best_time": "evening",
        "notes": "In memory of my father.",
    }
    body.update(over)
    return body


async def test_login_is_required(client):
    r = await client.post("/sabil-requests", json=form())
    assert r.status_code == 401


async def test_create_and_list_my_requests(client):
    user = await register(client)
    r = await client.post("/sabil-requests", json=form(quantity=7), headers=auth(user["access_token"]))
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["status"] == "new"
    assert body["extras"] == ["filter", "shade"]  # de-duplicated
    assert body["dedication_name"] == "Hagg Mahmoud Saleh"  # whitespace tidied
    assert body["quantity"] == 1  # only the company package takes a number of coolers

    other = await register(client, "bob")
    await client.post("/sabil-requests", json=form(package="company", quantity=12), headers=auth(other["access_token"]))

    mine = (await client.get("/sabil-requests/mine", headers=auth(user["access_token"]))).json()
    assert [m["id"] for m in mine] == [body["id"]]
    assert "phone" not in mine[0]  # contact details are not sent back


async def test_phone_numbers_are_normalised_and_checked(client):
    token = (await register(client))["access_token"]
    for raw in ["01012345678", "+201012345678", "00201012345678", "010-1234-5678", "٠١٠١٢٣٤٥٦٧٨"]:
        r = await client.post("/sabil-requests", json=form(phone=raw), headers=auth(token))
        if r.status_code == 429:
            break
        assert r.status_code == 201, (raw, r.text)

    token2 = (await register(client, "carol"))["access_token"]
    for bad in ["12345", "0201234567", "01312345678", "+441012345678"]:
        r = await client.post("/sabil-requests", json=form(phone=bad), headers=auth(token2))
        assert r.status_code == 422, bad


async def test_unknown_options_and_bad_text_are_rejected(client):
    token = (await register(client))["access_token"]
    for over in [
        {"package": "gold"},
        {"extras": ["jacuzzi"]},
        {"governorate": "paris"},
        {"taps": 9},
        {"area": "   "},
        {"contact_name": "<script>"},
        {"latitude": 29.9, "longitude": None},
    ]:
        r = await client.post("/sabil-requests", json=form(**over), headers=auth(token))
        assert r.status_code == 422, over


async def test_requests_per_day_are_limited(client):
    token = (await register(client))["access_token"]
    codes = [(await client.post("/sabil-requests", json=form(), headers=auth(token))).status_code for _ in range(6)]
    assert codes == [201] * 5 + [429]


async def test_admin_sees_updates_and_deletes_a_request(client):
    token = (await register(client))["access_token"]
    rid = (await client.post("/sabil-requests", json=form(), headers=auth(token))).json()["id"]

    r = await client.get("/admin/requests")
    assert r.status_code == 303  # login required

    await admin_login(client)
    page = (await client.get("/admin/requests")).text
    assert "Mona" in page and "Maadi" in page and "In memory of someone" in page
    assert 'Requests <span class="badge">1</span>' in page

    detail = (await client.get(f"/admin/requests/{rid}")).text
    for text in ["01012345678", "wa.me/201012345678", "Water filter, Shade / cover", "اشرب وادعيله",
                 "Has the owner&#39;s permission", "Road 9, next to the bakery"]:
        assert text in detail, text

    r = await client.post(f"/admin/requests/{rid}", data={"csrf": "forged", "status": "quoted"})
    assert r.status_code == 403

    r = await admin_post(client, f"/admin/requests/{rid}",
                         {"status": "quoted", "quote_egp": "24,900", "admin_notes": "Visited, needs 10 m pipe"})
    assert r.status_code == 303 and "error" not in r.headers["location"]
    mine = (await client.get("/sabil-requests/mine", headers=auth(token))).json()
    assert mine[0]["status"] == "quoted" and mine[0]["quote_egp"] == 24900
    assert "admin_notes" not in mine[0]

    r = await admin_post(client, f"/admin/requests/{rid}", {"status": "won", "quote_egp": "abc"})
    assert "error=1" in r.headers["location"]

    assert "Quoted (1)" in (await client.get("/admin/requests?state=open")).text
    await admin_post(client, f"/admin/requests/{rid}/delete")
    assert (await client.get("/sabil-requests/mine", headers=auth(token))).json() == []
    assert client.cookies.get(COOKIE)


async def test_deleting_the_account_deletes_its_requests(client):
    token = (await register(client))["access_token"]
    await client.post("/sabil-requests", json=form(), headers=auth(token))
    r = await client.request("DELETE", "/auth/me", json={"password": "password123"}, headers=auth(token))
    assert r.status_code in (200, 204), r.text
    await admin_login(client)
    assert "No requests here." in (await client.get("/admin/requests?state=all")).text


async def test_privacy_page_mentions_request_contact_details(client):
    page = (await client.get("/privacy")).text
    assert "Build-a-sabil requests" in page and "طلبات بناء السبيل" in page
