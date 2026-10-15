# Findings Log

Everything found while cleaning up and splitting the project, so it can be worked
through AFTER the restructuring is finished. Nothing in the "Open" sections has
been changed yet unless the Status says so.

**Status values:** `FIXED` (done, in a commit) · `OPEN` (confirmed, not fixed) ·
`VERIFY` (seen in earlier analysis, must be re-confirmed in the real code) ·
`DECIDE` (needs a product decision from you) · `APPROVAL` (a deletion; needs your yes)

**Severity:** High = security or data loss · Medium = wrong behaviour users can hit ·
Low = clutter or polish

Last updated after **Phase 2 (mobile foundations)**. Branch: `restructure`.

---

## 1. Fixed during Phase 1 (backend restructure)

| ID | Sev | Finding | Status |
|---|---|---|---|
| FX-01 | Medium | `PATCH /admin/coolers/{id}/force-status` accepted any text and crashed with a 500 (database enum error) on a bad value. The status is now validated against the `CoolerStatus` enum (returns 422). | FIXED |
| FX-02 | High | Photo upload built the saved filename from the client-supplied filename (`rsplit(".")`), so a crafted name could write outside the upload folder (path traversal). The extension now comes from the validated content type. | FIXED |
| FX-03 | Medium | Photo filenames were `<cooler>_<unix-second>.<ext>`: two uploads to one cooler in the same second overwrote each other's file while both database rows pointed at it. Names now contain a random id. | FIXED |
| FX-04 | Low | User and admin photo upload routes were near-copies with different error text. Now one shared helper (`coolers/photos.py` + `media/storage.py`). | FIXED |
| FX-05 | Low | ~15 lookups used `cast(id, String) == text` (defeats the index, hides typos). Route ids are now typed `UUID` and looked up with one `get_or_404` helper. | FIXED |
| FX-06 | Low | Removed the unused fields `taste_reports`, `is_wheelchair_accessible`, `needs_urgent_refill` (your request). | FIXED |
| FX-07 | Low | Inline schemas in `main.py` merged into the feature `schemas.py` files; settings/constants gathered into `core/config.py` and `users/trust.py`. | FIXED |

**Intended behaviour differences from the old code** (everything else matched in a
100-step end-to-end comparison on a real PostGIS database):
- Invalid status on `PATCH /coolers/{id}/status`: was `400` with a custom message, now `422` (FastAPI validation). The mobile app only ever sends valid values and never branches on 400/404/422, so it is unaffected.
- A malformed (non-UUID) id in a URL: was `404`, now `422`. Expected from the UUID typing; not exercised in the comparison run.
- Admin photo upload with a bad file type: error text now matches the user route ("Invalid file type. Use JPEG, PNG, or WebP.").

---

## 2. Open: backend

| ID | Sev | Finding | Evidence | Status | Suggested fix |
|---|---|---|---|---|---|
| BE-01 | Medium | **Photos can be silently lost.** Create-cooler and upload-photo share one rate limit (3 per minute per IP), and the failed requests still count. Adding a cooler with 3 photos is 4 requests, so the last is refused with 429. | Reproduced in the comparison run ("rate limit 5 uploads"). Whether the app shows an error is **VERIFY** (see MB-01). | OPEN | Separate buckets (or a higher photo limit), and make the app surface the 429. |
| BE-02 | High | **Unsafe defaults.** Without environment variables the admin login is `admin` / `admin123` and tokens are signed with `change-me-in-production`; anyone who knows this can forge tokens. | `core/config.py` | OPEN | In production mode, refuse to start unless real values are set. |
| BE-03 | High | **Unapproved photos are public.** `/uploads` is served as static files, so anyone with a URL can view photos still waiting for review. | `main.py` mounts `StaticFiles` | OPEN | Serve approved photos only (via a route that checks `is_approved`), or store unapproved files in a private folder. |
| BE-04 | Medium | **Unapproved and rejected coolers are readable by anyone** who has the id (`GET /coolers/{id}` has no approval check). | Reproduced ("get unapproved cooler" returned 200) | OPEN | Return 404 unless approved, or the viewer is the submitter or an admin. |
| BE-05 | Medium | **Trust points can be farmed.** A status report gives +10 immediately, even while it is only pending review, with no cooldown, so repeating it climbs toward the 500-point auto-approve level. | `coolers/router.py` `update_cooler_status` | OPEN | Award the points only when the change is approved; add a per-cooler cooldown. |
| BE-06 | Medium | **Sponsor contact cannot hold an email or a `+20…` phone number.** The shared text sanitizer rejects `@` and `+`. Same behaviour in the old code. | Reproduced (`a@b.com` returned 422) | OPEN | Give `contact` its own validator that allows `@ + . -`. |
| BE-07 | Medium | **No brute-force protection on login.** `/auth/login`, `/auth/register` and `/auth/admin/login` have no rate limit. | Only create-cooler and upload-photo use `rate_limiter` | OPEN | Add a per-IP limit to the auth routes. |
| BE-08 | Medium | **No upload size limit, and file type is trusted from the client header.** A very large file is written to disk in full; a non-image can be sent labelled `image/png`. | `media/storage.py` | OPEN | Cap the size and check the file's magic bytes. |
| BE-09 | Medium | **Confirm cooldown and rate limiter live in memory.** They reset on every restart and are not shared if you run more than one server process. | `core/rate_limit.py` | OPEN | Move to the database or Redis if you scale beyond one process. |
| BE-10 | Low | **CORS allows every origin with credentials** (`allow_origins=["*"]`). | `main.py` | OPEN | List the real origins before deploying. |
| BE-11 | Low | **Sponsor `views_count` / `clicks_count` are never incremented**, so the API always returns 0. | No code touches them | DECIDE | Build the counting, or remove the columns. |
| BE-12 | Low | **`WaterCoolerUpdate` is unused.** No route edits a cooler's name, cups info or location, so a typo can only be fixed by delete and re-add. | `coolers/schemas.py` (marked unused) | DECIDE | Build one admin edit route (name, cups; location needs `geom` + duplicate check) or delete the class. |
| BE-13 | Low | **`iot_weight_kg` is unused** (IoT roadmap only). `badges` is unused too, but you chose to keep it. | grep | DECIDE | Keep as roadmap, or remove. |
| BE-14 | Low | **No real migrations.** `create_all` never alters existing tables, so changes need hand-written SQL (`db_fix.py` is exactly that). Your existing database still has the 3 removed columns. | `db_fix.py`, `core/database.py` `init_db` | OPEN | Adopt Alembic; until then run the `ALTER TABLE ... DROP COLUMN` from `GETTING_STARTED`/the Phase 1 notes. |
| BE-15 | Low | **There are no tests in the repo.** The 100-step comparison I used lives only in my scratch workspace. | no `tests/` folder | OPEN | Save the scenario as `backend/tests/` so every later phase has a safety net. |
| BE-16 | Low | **Blocking file write inside an async route** (`shutil.copyfileobj`). Fine at low traffic. | `media/storage.py` | OPEN | Use a thread or `aiofiles` later. |
| BE-17 | Low | **Three overlapping ways to update a cooler's status** (Confirm, Change status, Add photo), plus the pending/approve flow. Hard to reason about and to explain to users. | Code + UI | DECIDE | Decide what each flow is for during the "behaviour clutter" phase. |
| BE-18 | Low | **`cups_type` is never set by the app** (so it is always null); only `has_cups` is used. | Earlier analysis | VERIFY | Check in the Flutter add-cooler dialog (Phase 3); keep or remove. |

---

## 3. Open: mobile (from the earlier analysis; re-confirm in the real code during Phases 2-4)

| ID | Sev | Finding | Status |
|---|---|---|---|
| MB-01 | Medium | Add-cooler flow swallows photo-upload failures (`catch (_) {}`) and shows "submitted successfully" even when a photo was refused (pairs with BE-01). Confirmed in `map_screen.dart` (`catch (_) {}` in the add-cooler flow). | CONFIRMED, not yet fixed |
| MB-02 | Low | `_statusColor` / `_statusIcon` copy-pasted in `map_screen.dart` and the admin screens. | FIXED in Phase 2 (one `statusColor`/`statusIcon` in `widgets/status_style.dart`) |
| MB-03 | Low | Photo-category sheet and camera/gallery sheet copy-pasted in map and admin screens. | FIXED in Phase 2 (`widgets/photo_pickers.dart`). The admin screen now shows the map screen's wording instead of its own. |
| MB-04 | Low | Two snackbar helpers (`_snack`, `_showSnackbar`) and a duplicated `_StatusPill`. | FIXED in Phase 2 (`widgets/app_snackbar.dart`, `StatusPill`). Admin errors are now the shared red instead of `red.shade700`. |
| MB-05 | Low | Base URL `http://10.0.2.2:8000` hard-coded in two files; teal `0xFF0F766E` and other colours typed out hundreds of times. | FIXED in Phase 2 (`ApiConfig.baseUrl`, `AppColors`). 9 one-off colours were left as literals (trust-level colours in `profile_screen.dart`, two onboarding gradient shades, `34D399` and `4F46E5` in `admin_widgets.dart`). Still needs one `baseUrl` change for a real phone or release build. |
| MB-06 | Low | `map_screen.dart` (1,713 lines) and `admin_widgets.dart` (1,431) + `admin_screen.dart` (695) are too big to navigate. | Planned (Phases 3-4) |
| MB-07 | Medium | "Still working" availability is decided in the app from the cooler's shared `last_verified_at`, but the server uses a per-user cooldown, so the button can disagree with the server. | VERIFY |
| MB-08 | Low | Hard-coded "+50 Trust" on submissions and the "+50 / -100" chips in My Submissions are fixed text, not real data (wrong for trusted users, who get +50 immediately, and for pending items). | CONFIRMED (hard-coded "+50 Trust pending" in `map_screen.dart`), fix in Phase 4 |
| MB-09 | Low | Trust levels (Newcomer to Champion) exist only in the profile screen; the thresholds are not shared with the server's rules. | VERIFY |
| MB-10 | Low | Admin area is reached by tapping the title 5 times (hidden, not secured beyond the admin login). | VERIFY |

---

## 4. Repo cleanup: needs your approval before anything is deleted

Nothing below has been removed. Each is still in the repository exactly as it was.

| ID | Item | Why it is a candidate | Status |
|---|---|---|---|
| RC-01 | `__pycache__/` (5 `.pyc` files) at the repo root, and `routers/__pycache__/`, `services/__pycache__/` | Compiled Python committed by accident; now covered by `.gitignore` but still tracked. | APPROVAL |
| RC-02 | `routers/auth.py`, `services/dependencies.py` | An abandoned earlier split. Nothing imports them, and the new `backend/sabil/` code replaces them. `routers/__pycache__` also holds compiled `admin`/`coolers` files whose source is gone. | APPROVAL |
| RC-03 | `db_fix.py` | One-off `ALTER TABLE` patches for two columns; superseded by BE-14 (migrations). | APPROVAL |
| RC-04 | `package.json`, `tsconfig.json`, `vite.config.ts`, `metadata.json` | Leftovers from the AI Studio web template; the app has no web frontend and they have no dependencies. | APPROVAL |
| RC-05 | `README.md` (AI Studio text) and `.env.example` (Gemini key placeholders) | Describe the template, not Sabil. Suggest replacing them with a real README rather than just deleting. | APPROVAL |
| RC-06 | `coolman_dump_20260705_061337.txt` (289 KB) | Stale snapshot of the code from July; the git history already keeps every version. | APPROVAL |
| RC-07 | `packer.py.txt` | Developer tool for packing the code into one file; suggest moving it to `backend/scripts/` instead of deleting. | APPROVAL |
| RC-08 | `.vscode/settings.json` | Hard-codes a Windows venv path (`venv/Scripts/python.exe`); personal editor setting, not project config. | APPROVAL |
| RC-09 | Node-only lines in `.gitignore` (`node_modules/`, `dist/`, `coverage/`) | Only needed if RC-04 stays. | APPROVAL |
| RC-10 | Docs note `pydantic-settings` as installed but nothing uses it. | Cosmetic; already dropped from `requirements.txt`. | FIXED |

Other: GitHub reports the repository moved to `https://github.com/iamarwan/CoolMan.git`;
the local remote still points at the old URL (works, but update it when convenient).

---

## 5. Limits of what has been verified

- **Backend:** verified against a real PostGIS database (route list, table definitions, and a 100-step end-to-end comparison old vs new). 97/100 identical; the other 3 are listed in section 1.
- **Mobile:** the Flutter/Dart SDK cannot be downloaded in my workspace, so Dart code **cannot be compiled or analyzed here**. For every mobile phase I will check imports and names with a script, but **you need to run `flutter analyze` and `flutter run`** after each phase. Everything stays on the `restructure` branch so it is easy to revert.
- Not exercised: the Flutter app against the new backend, real photo uploads from a phone, and the in-memory limiters across a server restart.

---

## 6. Progress through the restructure

| Phase | Scope | State |
|---|---|---|
| 1 | Backend split, verify, docs | Done (commit `e582504`) |
| 2 | Mobile foundations: theme, config, shared widgets, split models and API files | Done, but **not compiled** (no Flutter SDK here): run `flutter analyze` |
| 3 | Mobile: split `map_screen.dart` | Not started |
| 4 | Mobile: split `admin_screen.dart`, `admin_widgets.dart`, other screens | Not started |
| 5 | Cleanup deletions (section 4, after your approval) and docs refresh | Not started |
| After | Work through sections 2 and 3 of this log | Not started |

### Temporary compatibility shims (remove in Phase 5)

- `mobile/lib/models/water_cooler.dart` re-exports `cooler_photo.dart` and `sponsor.dart`.
- `mobile/lib/services/api_service.dart` re-exports `user_profile.dart` and `leaderboard_entry.dart`.

They keep the old imports in the screens working. Once the screens import the specific files, the re-exports can go.

### Static check limits (Phase 2)

A script checked that every import, export and `part` resolves, that braces balance (`sponsor_screen.dart` was already off by one parenthesis before my changes, a quirk of the checker's string handling), and that shared names are imported. It is not a compiler, so `flutter analyze` is the real test.
