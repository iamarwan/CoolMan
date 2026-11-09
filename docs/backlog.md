# Backlog: feedback from first phone test (2026-11-09)

Status: **parked until the Google Stitch designs are ready**. Each item lists
the agreed behaviour, the files involved and the planned change, so work can
start without re-investigating. Items marked *Open question* need a quick
answer from the owner before coding.

---

## 1. Sponsors must not appear in the user's profile

**Agreed behaviour:** sponsors are only visible on the cooler they sponsor
(the "Maintained by …" card in the cooler sheet, which opens the sponsor page).
There is no general sponsors list in the app.

**Planned change**
- `mobile/lib/features/profile/profile_screen.dart`: remove the "Sponsors" row.
- Delete `mobile/lib/features/sponsors/sponsors_list_screen.dart` and
  `sponsorsProvider` in `mobile/lib/features/profile/profile_repository.dart`.
- Keep `sponsor_screen.dart` (opened from the cooler sheet's sponsor card).
- Remove `CoolerRepository.sponsors()` if nothing else uses it, and the now
  unused ARB keys (`sponsors`, `sponsorsEmpty`, `sponsorCoolerCount`) from both
  `app_en.arb` and `app_ar.arb`.
- Backend `GET /sponsors` (list) can stay for the admin, or be removed if unused.
  `GET /sponsors/{id}` stays.
- Update the Stitch prompt (`docs/prompts/google-stitch-prompt.md`): remove
  screen 11 "Sponsors list" and the Sponsors row from the Profile screen.

---

## 2. Only allow confirming (and reporting) when the user is near the cooler

**Agreed behaviour:** "Still working" only counts if the user is physically
close to the cooler.

**Planned change**
- **Backend is the source of truth** (the app alone can be bypassed):
  - `POST /coolers/{id}/confirm` and `PATCH /coolers/{id}/status` accept the
    user's `lat`, `lng` and GPS `accuracy` (metres) in the request body.
  - Reject with code `too_far` (HTTP 403) if the distance between the user and
    the cooler is more than `MAX_ACTION_DISTANCE_M` (proposed **150 m**), and
    code `location_required` if no location is sent.
  - Constant in `app/services/trust.py`; distance check with PostGIS
    (`ST_DWithin` on geography, as in `app/services/coolers.py:within_meters`).
  - Tests in `tests/test_trust.py`: near → ok, far → 403 `too_far`,
    missing location → `location_required`.
- **App** (`mobile/lib/features/cooler/cooler_sheet.dart`):
  - Before confirming/reporting, get a fresh GPS fix via
    `userLocationProvider.notifier.locate()`; send it with the request.
  - If the user is too far: disable the button and show
    "Get within 150 m of this cooler to confirm it" (+ distance), instead of
    letting them tap and fail.
  - If location is off/denied: show the existing location messages with a
    Settings action.
  - New ARB strings (EN + AR): `tooFarToConfirm(distance)`,
    `locationNeededToConfirm`, error codes `too_far`, `location_required` in
    `core/error_text.dart`.
- Note: GPS can be spoofed by determined users; this stops casual far-away
  confirmations. Admin review of suspicious patterns can come later.

**Decided (owner)**
- Radius as tight as practical: **50 m**, with the 40 m GPS-accuracy guard above.
- Applies to **all** contributions: confirm, status reports, photo uploads,
  and adding a new cooler (user must be within 50 m of the pin they drop).
- App copy: "Get closer to this cooler to confirm it (you are 230 m away)".

---

## 3. ~~Admin: per-photo review of new submissions~~

**Dropped by owner** — will be handled in the redesign rework.

---

## 4. Admin: more context for photos added to an existing cooler

**Current:** the Photos section shows only `Cooler · <name>`, the uploader and
Approve/Delete.

**Agreed behaviour:** make it clear this is an **extra photo for an existing,
live cooler**, with enough context to decide without clicking around, while
keeping the link to the cooler page.

**Planned change** (`app/admin_web/routes.py:queue` + `queue.html`)
- Label: **"New photo for a live cooler"**, with the photo category
  ("shows the cooler" / "shows the cups").
- Show alongside the new photo:
  - Cooler name (link to the cooler page), current status, last confirmed,
    map link.
  - The cooler's **existing approved photos** (small thumbnails) to compare.
  - Uploader: username, trust points, how many of their photos were
    approved/deleted before (needs a count query).
  - Upload time.
- Larger preview: click opens the full-size photo.
- Group several pending photos for the same cooler into one card.
- Optional: "Approve all from this user" for trusted uploaders.

---

## 5. Sponsors: needs more work

**Status:** owner wants to improve sponsors; details to be agreed.

**Already known**
- Sponsors show only on their coolers (item 1).
- Admin can add / verify / delete sponsors and assign one per cooler.

**To discuss (Phase 6 + business plan in BUSINESS_STRATEGY.md)**
- What a sponsor card shows on a cooler (logo, short message, offer, contact,
  opening hours, "10 m away" store location).
- Sponsor logos/photos (upload in admin, shown in the app).
- One sponsor for many coolers (bulk assign in admin).
- Sponsor stats for the sponsor (views/taps) — the earlier code had unused
  `views_count`/`clicks_count` columns that were removed; can be re-added.
- Sponsor types and Arabic names (bilingual sponsor name/description).
- Whether sponsors pay (SaaS) and an expiry date for sponsorships.

**Next step:** owner describes what sponsors should look like/do (ideally in
the Stitch designs), then this item gets a concrete plan.

---

## Suggested order after the Stitch designs

1. Item 1 (small, removes a screen before redesign).
2. Item 2 (backend + app; decisions made).
3. Item 4 (admin panel queue context).
4. Item 5 with Phase 6 (needs the sponsor design).
