# Findings Log

Everything found while cleaning up and splitting the project, so it can be worked
through AFTER the restructuring is finished. Nothing in the "Open" sections has
been changed yet unless the Status says so.

**Status values:** `FIXED` (done, in a commit) · `OPEN` (confirmed, not fixed) ·
`VERIFY` (seen in earlier analysis, must be re-confirmed in the real code) ·
`DECIDE` (needs a product decision from you) · `APPROVAL` (a deletion; needs your yes)

**Severity:** High = security or data loss · Medium = wrong behaviour users can hit ·
Low = clutter or polish

Last updated after **Phase 4 (admin and profile splits) and the cross-check**. Branch: `restructure`.

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
| BE-01 | Medium | **Photos can be silently lost.** Create-cooler and upload-photo share one rate limit (3 per minute per IP), and the failed requests still count. Adding a cooler with 3 photos is 4 requests, so the last is refused with 429. | Reproduced in the comparison run ("rate limit 5 uploads"). Whether the app shows an error is **VERIFY** (see MB-01). | FIXED: photo uploads have their own limit (20/min per IP); creating coolers stays 3/min | Separate buckets (or a higher photo limit), and make the app surface the 429. |
| BE-02 | High | **Unsafe defaults.** Without environment variables the admin login is `admin` / `admin123` and tokens are signed with `change-me-in-production`; anyone who knows this can forge tokens. | `core/config.py` | FIXED: `SABIL_ENV=production` refuses to start with default secrets; development only warns | In production mode, refuse to start unless real values are set. |
| BE-03 | High | **Unapproved photos are public.** `/uploads` is served as static files, so anyone with a URL can view photos still waiting for review. | `main.py` mounts `StaticFiles` | FIXED: `/uploads/photos/<file>` is now a route; unapproved photos only for admin or uploader (404 otherwise) | Serve approved photos only (via a route that checks `is_approved`), or store unapproved files in a private folder. |
| BE-04 | Medium | **Unapproved and rejected coolers are readable by anyone** who has the id (`GET /coolers/{id}` has no approval check). | Reproduced ("get unapproved cooler" returned 200) | FIXED: `GET /coolers/{id}` and its photo list return 404 for unapproved coolers unless admin or submitter | Return 404 unless approved, or the viewer is the submitter or an admin. |
| BE-05 | Medium | **Trust points can be farmed.** A status report gives +10 immediately, even while it is only pending review, with no cooldown, so repeating it climbs toward the 500-point auto-approve level. | `coolers/router.py` `update_cooler_status` | FIXED: points for a status report are paid only when it takes effect (admin approves, or you are trusted); one report per cooler per 10 minutes; reporting the current status is refused | Award the points only when the change is approved; add a per-cooler cooldown. |
| BE-06 | Medium | **Sponsor contact cannot hold an email or a `+20…` phone number.** The shared text sanitizer rejects `@` and `+`. Same behaviour in the old code. | Reproduced (`a@b.com` returned 422) | FIXED: contact accepts emails, `+20...` phone numbers and links (own validator) | Give `contact` its own validator that allows `@ + . -`. |
| BE-07 | Medium | **No brute-force protection on login.** `/auth/login`, `/auth/register` and `/auth/admin/login` have no rate limit. | Only create-cooler and upload-photo use `rate_limiter` | FIXED: 10 login/register attempts per IP per minute (separate from the submission limit) | Add a per-IP limit to the auth routes. |
| BE-08 | Medium | **No upload size limit, and file type is trusted from the client header.** A very large file is written to disk in full; a non-image can be sent labelled `image/png`. | `media/storage.py` | FIXED: 8 MB cap, and the file's real first bytes must match JPEG/PNG/WebP; partial files are deleted | Cap the size and check the file's magic bytes. |
| BE-09 | Medium | **Confirm cooldown and rate limiter live in memory.** They reset on every restart and are not shared if you run more than one server process. | `core/rate_limit.py` | OPEN | Move to the database or Redis if you scale beyond one process. |
| BE-10 | Low | **CORS allows every origin with credentials** (`allow_origins=["*"]`). | `main.py` | OPEN | List the real origins before deploying. |
| BE-11 | Low | **Sponsor `views_count` / `clicks_count` are never incremented**, so the API always returns 0. | No code touches them | DECIDE | Build the counting, or remove the columns. |
| BE-12 | Low | **`WaterCoolerUpdate` is unused.** No route edits a cooler's name, cups info or location, so a typo can only be fixed by delete and re-add. | `coolers/schemas.py` (marked unused) | DECIDE | Build one admin edit route (name, cups; location needs `geom` + duplicate check) or delete the class. |
| BE-13 | Low | **`iot_weight_kg` was unused** (IoT roadmap only). `badges` is unused too, but kept on purpose. | grep | DONE (2026-10-18) | `iot_weight_kg` removed from model and API. `badges` stays: it will hold trust-level badges (LAUNCH_PLAN 8a). An existing database keeps the old empty column until `python -m scripts.sync_schema --apply --drop-extra` is run (back up first); it is harmless meanwhile. |
| BE-14 | Low | **No real migrations.** `create_all` never alters existing tables, so changes need hand-written SQL (`db_fix.py` is exactly that). Your existing database still has the 3 removed columns. | `db_fix.py`, `core/database.py` `init_db` | PARTLY DONE: `python -m scripts.sync_schema` reports and fixes column differences (dry run by default; `--apply` adds missing columns, `--drop-extra` removes unused ones). Tested on a copy of the old database. Alembic still not adopted | Adopt Alembic; until then run the `ALTER TABLE ... DROP COLUMN` from `GETTING_STARTED`/the Phase 1 notes. |
| BE-15 | Low | **There are no tests in the repo.** The 100-step comparison I used lives only in my scratch workspace. | no `tests/` folder | PARTLY DONE: `backend/tests/` has 11 tests (run with pytest). The old 100-step scenario is not saved | Save the scenario as `backend/tests/` so every later phase has a safety net. |
| BE-16 | Low | **Blocking file write inside an async route** (`shutil.copyfileobj`). Fine at low traffic. | `media/storage.py` | OPEN | Use a thread or `aiofiles` later. |
| BE-17 | Low | **Three overlapping ways to update a cooler's status** (Confirm, Change status, Add photo), plus the pending/approve flow. Hard to reason about and to explain to users. | Code + UI | DECIDE | Decide what each flow is for during the "behaviour clutter" phase. |
| BE-18 | Low | **`cups_type` is never set by the app** (so it is always null); only `has_cups` is used. | Earlier analysis | CONFIRMED: the app only ever sends null (the add dialog never picks a cups type) | DECIDE: add a picker in the app or remove the field. |

---

## 3. Open: mobile (from the earlier analysis; re-confirm in the real code during Phases 2-4)

| ID | Sev | Finding | Status |
|---|---|---|---|
| MB-01 | Medium | Add-cooler flow swallows photo-upload failures (`catch (_) {}`) and shows "submitted successfully" even when a photo was refused (pairs with BE-01). Confirmed in `map_screen.dart` (`catch (_) {}` in the add-cooler flow). | FIXED: the app now reports how many photos failed after adding a cooler |
| MB-02 | Low | `_statusColor` / `_statusIcon` copy-pasted in `map_screen.dart` and the admin screens. | FIXED in Phase 2 (one `statusColor`/`statusIcon` in `widgets/status_style.dart`) |
| MB-03 | Low | Photo-category sheet and camera/gallery sheet copy-pasted in map and admin screens. | FIXED in Phase 2 (`widgets/photo_pickers.dart`). The admin screen now shows the map screen's wording instead of its own. |
| MB-04 | Low | Two snackbar helpers (`_snack`, `_showSnackbar`) and a duplicated `_StatusPill`. | FIXED in Phase 2 (`widgets/app_snackbar.dart`, `StatusPill`). Admin errors are now the shared red instead of `red.shade700`. |
| MB-05 | Low | Base URL `http://10.0.2.2:8000` hard-coded in two files; teal `0xFF0F766E` and other colours typed out hundreds of times. | FIXED in Phase 2 (`ApiConfig.baseUrl`, `AppColors`). 9 one-off colours were left as literals (trust-level colours in `profile_screen.dart`, two onboarding gradient shades, `34D399` and `4F46E5` in `admin_widgets.dart`). Still needs one `baseUrl` change for a real phone or release build. |
| MB-06 | Low | `map_screen.dart` is now split (Phase 3). Still to do:  `admin_widgets.dart` (1,431) + `admin_screen.dart` (695) are too big to navigate. | Planned (Phases 3-4) |
| MB-07 | Medium | "Still working" availability is decided in the app from the cooler's shared `last_verified_at`, but the server uses a per-user cooldown, so the button can disagree with the server. | VERIFY |
| MB-08 | Low | Hard-coded "+50 Trust" on submissions and the "+50 / -100" chips in My Submissions are fixed text, not real data (wrong for trusted users, who get +50 immediately, and for pending items). | CONFIRMED (hard-coded "+50 Trust pending" in `map_screen.dart`), fix in Phase 4 |
| MB-09 | Low | Trust levels (Newcomer to Champion) exist only in the profile screen; the thresholds are not shared with the server's rules. | VERIFY |
| MB-10 | Low | Admin area is reached by tapping the title 5 times (hidden, not secured beyond the admin login). | VERIFY |

---

## 4. Repo cleanup: needs your approval before anything is deleted

Approved on 2026-10-16 and removed (RC-01 to RC-06, RC-09; the old README was replaced earlier). `packer.py.txt` was moved, not deleted (RC-07). Still waiting for a decision: RC-08.

| ID | Item | Why it is a candidate | Status |
|---|---|---|---|
| RC-01 | `__pycache__/` (5 `.pyc` files) at the repo root, and `routers/__pycache__/`, `services/__pycache__/` | Compiled Python committed by accident; now covered by `.gitignore` but still tracked. | DELETED |
| RC-02 | `routers/auth.py`, `services/dependencies.py` | An abandoned earlier split. Nothing imports them, and the new `backend/sabil/` code replaces them. `routers/__pycache__` also holds compiled `admin`/`coolers` files whose source is gone. | DELETED |
| RC-03 | `db_fix.py` | One-off `ALTER TABLE` patches for two columns; superseded by BE-14 (migrations). | DELETED |
| RC-04 | `package.json`, `tsconfig.json`, `vite.config.ts`, `metadata.json` | Leftovers from the AI Studio web template; the app has no web frontend and they have no dependencies. | DELETED |
| RC-05 | `README.md` (AI Studio text) and `.env.example` (Gemini key placeholders) | Describe the template, not Sabil. Suggest replacing them with a real README rather than just deleting. | DELETED |
| RC-06 | `coolman_dump_20260705_061337.txt` (289 KB) | Stale snapshot of the code from July; the git history already keeps every version. | DELETED |
| RC-07 | `packer.py.txt` | Developer tool for packing the code into one file; suggest moving it to `backend/scripts/` instead of deleting. | MOVED to `tools/pack_code.py` (now also includes `.yml`/`.txt`, skips `uploads/`) |
| RC-08 | `.vscode/settings.json` | Hard-codes a Windows venv path (`venv/Scripts/python.exe`); personal editor setting, not project config. | APPROVAL |
| RC-09 | Node-only lines in `.gitignore` (`node_modules/`, `dist/`, `coverage/`) | Only needed if RC-04 stays. | DELETED |
| RC-10 | Docs note `pydantic-settings` as installed but nothing uses it. | Cosmetic; already dropped from `requirements.txt`. | FIXED |

### What each candidate was for (explained to the owner; still waiting for answers on the ones marked ASK)

| Item | What it was for | Verdict so far |
|---|---|---|
| `__pycache__/`, `routers/__pycache__/`, `services/__pycache__/` | Python's automatic cache of compiled files. Never written by hand; any machine recreates them. | Safe to delete |
| `routers/auth.py`, `services/dependencies.py` | An earlier attempt to split `main.py` into folders (they import with the old flat names like `from database import ...`). The same code now lives in `backend/sabil/users/router.py`, `core/dependencies.py` and `core/rate_limit.py`. | Safe to delete |
| `db_fix.py` | Run once by hand to add two columns (`is_rejected`, `pending_status_user_id`) to an existing database, because `create_all` never changes existing tables. It cannot run any more (old import path). | Safe to delete; the lasting fix is BE-14 (migrations) |
| `package.json`, `tsconfig.json`, `vite.config.ts`, `metadata.json`, `.env.example`, old `README.md` | Generated by Google AI Studio when the project was first created there (a web-app template with a Gemini API key). Nothing in them is used by the Flutter app or the server. | ASK: was there ever a web version, or a plan for the Gemini photo check mentioned in BUSINESS_STRATEGY.md? |
| `coolman_dump_20260705_061337.txt` | A text snapshot of the whole code on 5 July, made by `packer.py.txt` so the code could be pasted or uploaded to an AI chat in one file. | Out of date; safe to delete |
| `packer.py.txt` | The script that makes those snapshots. It skips Android, iOS, venv and similar folders to keep the file small. | ASK: do you still use it? If yes, keep it as `tools/pack_code.py` |
| `.vscode/settings.json` | Tells VS Code to use a Windows virtual environment at `venv/Scripts/python.exe` in the repo root. | ASK: do you still develop on Windows with that folder? The server code is now in `backend/`, so the path may need to change rather than go |
| `docker-compose.yml` | Starts the PostGIS database. | KEEP (needed) |

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
| 3 | Mobile: split `map_screen.dart` | Done (1,621 to 484 lines; `flutter analyze` passes on GitHub) |
| 4 | Mobile: split `admin_screen.dart`, `admin_widgets.dart`, other screens | Done: admin split into `screens/admin/` (8 files), profile into `screens/profile/` (4 files). `my_submissions`, `sponsor` and `onboarding` screens left whole (under 320 lines each) |
| 5 | Cleanup deletions (section 4) and docs refresh | Done 2026-10-16. A fresh dated dump is in the repo root; `GETTING_STARTED.md` rewritten for a new laptop |
| After | Work through sections 2 and 3 of this log | Not started |

### Temporary compatibility shims (REMOVED 2026-10-17)

- `mobile/lib/models/water_cooler.dart` re-exports `cooler_photo.dart` and `sponsor.dart`.
- `mobile/lib/services/api_service.dart` re-exports `user_profile.dart` and `leaderboard_entry.dart`.

Done: every file now imports `cooler_photo.dart`, `sponsor.dart`, `user_profile.dart` and `leaderboard_entry.dart` directly and the re-exports are gone.

### Static check limits (Phase 2)

A script checked that every import, export and `part` resolves, that braces balance (`sponsor_screen.dart` was already off by one parenthesis before my changes, a quirk of the checker's string handling), and that shared names are imported. It is not a compiler, so `flutter analyze` is the real test.

### Extra bug found and fixed while testing (batch 2-3)

- **Deleting a cooler that had photos failed with a server error** (the photo rows were not deleted with it). Now the photos are deleted with the cooler, and their image files are removed from disk too.
- The admin photo gallery in the app now sends the admin's token with image requests, because unapproved photos are no longer public.

### Behaviour changes from batch 4 (for the app)

- Reporting a status change now requires an approved cooler, and returns an error if the cooler already has that status ("Use Still working") or if you reported it in the last 10 minutes. The app shows these messages as it does any other error.

---

## 7. Cross-check after the splits (app vs server, and duplicated rules)

### What was checked and passed

| Check | Result |
|---|---|
| Every server call in the app (31) against the server's route list (method and path) | All match. |
| Fields the app reads from `WaterCooler`, `CoolerPhoto`, `Sponsor`, `UserProfile` against what the server sends | The app reads nothing the server does not send (`cooler_count` comes from the sponsor list/detail routes, which do send it). |
| `flutter analyze` on GitHub after every phase | Clean after fixes (see "Caught by the analyzer" below). |
| Backend tests (11) against a real PostGIS database | All pass. |

### New findings

| ID | Sev | Finding | Status |
|---|---|---|---|
| XC-01 | Medium | **The app did not know the new server rule from batch 4**: tapping the status the cooler already has returned an error ("Use Still working"). | FIXED: the highlighted status button now does nothing. The 10-minute report cooldown still shows the server's message as a normal error. |
| MB-11 | Low | **Nine `catch (_)` blocks hide the reason for a failure.** Expected ones: `session_store.dart`, `api_client.dart` (fall back to default text), `admin_login_dialog.dart` (shows "Invalid credentials"). To review: `admin/photo_gallery_sheet.dart` (x2), `admin/sponsor_assign_sheet.dart`, `map_screen.dart` (two places), `sponsor_screen.dart`. | OPEN: check each shows the person something useful. |
| MB-12 | Low | `sponsor_screen.dart` says "Maintains N Coolers **in Cairo**" with the city typed in. | FIXED: text now says "Maintains N Coolers" |
| MB-13 | Low | `admin/admin_login_dialog.dart` and `create_sponsor_dialog.dart` dispose their text controllers right after the dialog closes; Flutter can throw "used after being disposed" while the close animation runs. Also a variable named `pass` holds a controller. | FIXED in code: both dialogs are now small widgets that own and dispose their controllers; confirm on a device |
| MB-14 | Low | **Reward amounts and rules are typed into the app** (`+50`, `+5`, `-100`, "500 points", "60 minutes") in `map_screen.dart`, `cooler_sheet.dart`, `my_submissions_screen.dart`, `onboarding_screen.dart`, `profile/trust_level.dart`. They duplicate `backend/sabil/users/trust.py` and the confirm cooldown, and will drift if the server numbers change. Extends MB-07, MB-08 and MB-09. | OPEN: one fix (the server sends its rules, or one shared Dart constants file) |
| MB-15 | Low | The words `Working` / `Empty` / `Broken`, the sponsor types (`Business`, `Mosque`, `Individual`, `NGO`) and the photo categories are plain text repeated in about 8 files. A typo would compile fine. | OPEN: Dart `enum`s |
| BE-19 | Low | `GET /coolers/{id}` is never called by the app (dead route). | DECIDE: keep for future clients or remove |
| RC-11 | Low | `my_submissions_screen.dart` has its own colour and icon logic for submission states (Approved / Rejected / Pending). It is a different idea from cooler status, so it was left alone, but it could join `widgets/status_style.dart`. | OPEN |

### Found while building the translation sheet and new features (2026-10-17)

| ID | Sev | Finding | Status |
|---|---|---|---|
| BE-20 | Medium | The text check on cooler names rejected Arabic punctuation (`،` `؟` `؛` `«»`), so an Arabic cooler name or dedication with a comma or question mark would be refused. | FIXED in `core/validation.py` (Arabic letters were already allowed) |
| MB-16 | Medium | **Server error sentences are shown to the user as they arrive, in English.** Arabic needs the server to send error codes the app can translate (22 messages, listed in the translation sheet). | OPEN: part of the Arabic work |
| MB-17 | Low | Several words are assembled from pieces, which does not work in Arabic: plurals (`day` + `s`), `Verified $days days ago`, `$n item(s)`. Arabic has different forms for 1, 2, 3-10 and 11+. | OPEN: part of the Arabic work (marked in the sheet) |
| MB-18 | Low | Odd English in the app: "Sponsored Sadie", "Map Index empty", "Sabil s.a." as the app-bar title, "Administration Controller". Probably typing mistakes and machine wording. | OPEN: fix with the Arabic wording pass |
| BE-21 | Low | A phone number can be linked to an account on the server (`/auth/phone/attach`) but the app has no button for it yet, so password users cannot add a number. | OPEN |
| BE-22 | Low | `scripts/sync_schema.py` adds missing columns and their index, but does not create foreign keys (not needed for the columns added so far). | NOTED |

### Caught by the analyzer while splitting (all fixed, none left)

1. A script that added `super.key` to the new public widgets also rewrote *uses* of those widgets and removed the key from `AdminScreen` (`use_key_in_widget_constructors`).
2. A constructor ended up with the key declared twice (`duplicate_definition`).
3. One unused import (`profile_error_card.dart`).

Lesson for later phases: scripted rewrites of Dart need `flutter analyze` right after, which the GitHub check now does on every push.

---

## 8. Planned for later (not started)

### AI photo moderation (Gemini Vision)

Idea: when someone uploads a photo, send it to a Gemini Vision model to check it really shows a water cooler (or cups) and reject spam or unrelated pictures before an admin has to look. It is listed in `BUSINESS_STRATEGY.md` (roadmap, Phase 2 area).

Decision (2026-10-16): build it on a clean slate **after the app is running well**. The leftover Google AI Studio files (`package.json`, `vite.config.ts`, `.env.example` with a Gemini key placeholder, etc.) were deleted because they were an unrelated web template.

Notes for when it is built:
- Hook point: `backend/sabil/media/storage.py` `save_image` / `coolers/photos.py` upload route, after the magic-byte check.
- Keep the key in a new `SABIL_GEMINI_API_KEY` setting in `core/config.py`, never in the repo.
- Treat the AI verdict as advice (auto-flag or auto-hide), keep admin as final say, and fail open (photo goes to the normal queue) if the AI call errors or times out. Add retries/fallback around the call.

## 9. Integration and dead-code audit (2026-10-18)

Method: ruff + vulture on the backend; every config constant, schema and model field grep-checked; a script scanning every Dart declaration/file for zero references; every app HTTP call compared with the server's route list (from `app.openapi()`).

**Result: app and server agree.** All 33 app calls hit an existing route with the right verb (including phone sign-in and dedications). 39 backend tests pass.

**Removed (provably unused):** `WaterCoolerUpdate` schema (no edit route exists); `fetchSponsor` in the app (never called); lint fixes (`raise ... from None`, unused test arguments).

**Server routes the app does not call (kept, intentional):** `GET /coolers/{id}` (public cooler page, useful for share links), `GET /sponsors/{id}`, `GET /admin/dedications` (admin list for a future screen), `POST /auth/phone/attach` (button not built yet).

**Needs owner decision (not touched):**
- `users.badges`: KEPT by owner decision (trust-level badges, LAUNCH_PLAN 8a).
- `water_coolers.iot_weight_kg`: REMOVED from code (owner approved 2026-10-18).
- `.vscode/settings.json` (RC-08): stale Windows path; delete?
- MB-11 (nine `catch (_)`): FIXED 2026-10-18. Screens now show the real reason (server message, or "could not reach the server"). Found and fixed a real bug on the way: opening the app with no internet signed the person out (any profile-fetch failure deleted the saved login); now only a 401 from the server does. The contact button on a sponsor page also did nothing silently when no app could open it; it now says so.
- Still open from before: BE-09 (rate limits in memory, one server only), BE-10 (CORS `*`), BE-11/12/13/17/19/21.
- **RC-12 (found on the owner's first Windows run, 2026-10-21):** `requirements.txt` had `sqlalchemy` without `[asyncio]`, so `greenlet` was not installed and the server crashed at start with "requires that the Python 'greenlet' library is installed". FIXED: now `sqlalchemy[asyncio]>=2.0`. Lesson: always test a fresh install on a clean venv.
