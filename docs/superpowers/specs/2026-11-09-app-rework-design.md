# Sabil / CoolMan — Full Rework Design

Status: **Phases 1–3 implemented** (4–6 pending)
Date: 2026-11-09
Stack (kept): Flutter (Android first) · FastAPI · PostgreSQL + PostGIS

---

## 1. Goal

Turn the current prototype into a fast, stable Android app that:

1. Opens instantly on a real phone (no white screen) and stays responsive.
2. Ships as a small APK (target: **~15–20 MB per APK**, down from ~70 MB).
3. Supports **English and Arabic (full right-to-left layout)**.
4. Is ready to deploy to a real server later, without code changes, by
   flipping configuration only.
5. Gets a new brand and a new UI (designed in Google Stitch, then implemented).

### What the owner told us

- APK was built with `flutter build apk` (a single "fat" release APK).
- Backend stays on the owner's PC for now. Deploy files must exist but stay
  inactive until needed.
- Database holds only `seed.py` test data, so a clean schema reset is fine.
- Arabic is required. **Finding: there is no localization in the code yet**
  (no `flutter_localizations`, no `.arb` files, no RTL handling).
- Admin panel: move it out of the phone app if it can run locally, which it can.
- Android only for now.
- Keep the stack.
- Fresh name and brand, produced with a Claude prompt (`docs/prompts/brand-identity-prompt.md`).

---

## 2. Diagnosis (why it is slow, buggy, white-screened and big)

### 2.1 White screen / "does nothing" on a real phone

| Problem | Where | Effect |
|---|---|---|
| No `INTERNET` permission in the **main** manifest (only debug/profile have it) | `mobile/android/app/src/main/AndroidManifest.xml` | Release APK cannot load map tiles or call the API |
| No location permissions declared | same file | "Near me" cannot work; `geolocator` throws |
| API URL hard-coded to `http://10.0.2.2:8000` | `mobile/lib/services/api_service.dart:66`, `mobile/lib/screens/admin_widgets.dart:146` | `10.0.2.2` only exists inside the Android emulator |
| Plain `http://` blocked by Android 9+ in release builds | (no network security config) | Even a correct LAN IP would be refused |
| `main()` awaits secure storage + a network call **before** `runApp` | `mobile/lib/main.dart` | Any hang or exception there leaves the white launch screen up forever |

### 2.2 APK size

`flutter build apk` without flags produces one APK containing native code for
three CPU types (armv7, arm64, x86_64). Modern Android stores native libraries
uncompressed inside the APK, so this triples the biggest part of the app.
Fix: `--split-per-abi` (one APK per CPU type; almost all real phones need only
`arm64-v8a`), plus code obfuscation with split debug info, icon tree-shaking and
R8 resource shrinking.

### 2.3 Slowness and bugs

**Mobile**
- `map_screen.dart` is 1,713 lines; `admin_widgets.dart` 1,431. One `setState`
  rebuilds the whole map, including every marker.
- No local cache: every launch starts from zero, and every action
  re-downloads the full list.
- `/coolers/nearby` returns every cooler within 5 km **with all photos and
  sponsor objects embedded**, even though the map only needs a pin.
- Map tiles come straight from `tile.openstreetmap.org`. OSM's tile usage policy
  does not allow apps to depend on it at scale; requests can be throttled or blocked.
- Admin panel is inside the public app behind a 5-tap gesture (security risk + size).
- Base URL duplicated in two files; no environment configuration.
- `flutter_map` 6.x is several major versions behind.

**Backend**
- Everything lives in one 829-line `main.py`; `routers/auth.py` is a dead duplicate.
- Lookups compare `cast(id, String) == cooler_id`, which defeats the primary-key
  index and does a full table scan.
- Rate limiter and "confirm" cooldown live in Python memory: reset on restart,
  wrong with more than one worker.
- Insecure defaults: admin `admin` / `admin123`, JWT secret `change-me-in-production`.
- Schema changes via ad-hoc `db_fix.py` instead of migrations.
- Uploaded photos are stored full-size; no thumbnails.

**Repository hygiene**
- Leftover Google AI Studio / Vite files (`package.json`, `vite.config.ts`,
  `tsconfig.json`, `metadata.json`, `.env.example`, README) unrelated to this app.
- 289 KB `coolman_dump_*.txt`, committed `__pycache__/`, no `requirements.txt`.

---

## 3. Principles borrowed from mobility apps (Rabbit, Lime, Bird)

Honesty note: Rabbit, Lime and Bird do not publish their engineering internals.
These principles come from how their apps visibly behave (map-first home, bottom
sheets, QR/ID entry, zone overlays) and from widely documented map-app practice
(viewport loading, clustering, caching, small release builds).

1. **The map is the app.** One home screen; everything else is a bottom sheet
   or a short pushed screen. First interactive frame in under ~1 second.
2. **Show something immediately.** Draw the last cached map position and pins
   from disk, then refresh in the background (stale-while-revalidate).
3. **Load only what is visible.** Query by the map's bounding box, debounced
   while panning; send tiny pin objects (id, lat, lng, status, sponsored flag).
   Fetch full details only when a pin is tapped.
4. **Cluster at low zoom, pins at high zoom.** Keep marker widgets cheap
   (no shadows or blur per marker).
5. **Optimistic actions.** "Still working" or "Report empty" updates the pin
   instantly and reconciles with the server afterwards; roll back on failure.
6. **Lazy login.** Browsing needs no account; log in only to contribute
   (the app already does this; keep it).
7. **Cheap, cached tiles.** Cache tiles on device; make the tile provider
   configurable so a proper provider can be used in production.
8. **Small, lean builds.** Split per ABI, obfuscate, shrink, avoid heavy plugins,
   bundle only what is needed (one subset Arabic/Latin font family).
9. **Fail visibly, never freeze.** Every network call has a timeout and a
   friendly error state; startup never blocks on the network.

---

## 4. Architecture after the rework

### 4.1 Mobile (`mobile/lib/`)

```
lib/
  main.dart                 # runApp immediately; error boundary
  app/                      # MaterialApp, theme, router, locale
  core/
    config.dart             # API_BASE_URL, TILE_URL via --dart-define
    http_client.dart        # one client: timeouts, auth header, error mapping
    cache_store.dart        # small JSON-on-disk cache
  l10n/                     # app_en.arb, app_ar.arb (generated localizations)
  features/
    map/                    # map screen, viewport loader, pins, clusters
    cooler/                 # detail sheet, add flow, report, photos
    auth/                   # login/register sheet, session
    profile/                # profile, my submissions, leaderboard
    sponsors/
    onboarding/
```

- State management: **Riverpod** (small, testable, avoids whole-screen rebuilds).
- Each feature has a repository (network + cache) and thin widgets.
- Configuration via `--dart-define`, so the same code targets the emulator,
  a real phone on Wi-Fi (PC's LAN IP) or production HTTPS.

### 4.2 Backend

```
app/
  main.py          # create_app(), middleware, routers
  config.py        # pydantic-settings; refuses insecure defaults when ENV=production
  db.py
  models.py
  schemas.py
  security.py      # password hashing, JWT
  routers/  auth.py  coolers.py  photos.py  sponsors.py  users.py  admin.py
  services/ trust.py  images.py (resize + thumbnail)
  admin_web/       # server-rendered admin panel (Jinja2 templates)
migrations/        # Alembic
tests/             # pytest
```

New or changed endpoints:
- `GET /coolers/map?bbox=minLng,minLat,maxLng,maxLat` → minimal pins.
- `GET /coolers/{id}` → full detail (photos as thumbnail + full URLs).
- UUID path parameters typed as `uuid.UUID` (index used, 422 on garbage).
- Cooldowns and rate limits stored in the database.

### 4.3 Admin panel

Moves to the backend as a small web page at `http://<pc>:8000/admin`
(log in, approve/reject, photos, sponsors). Runs locally with the backend,
no extra install. Removed from the phone app.

### 4.4 Deploy-ready (inactive) files

Added but not used until the owner is ready:
- `deploy/Dockerfile`, `deploy/docker-compose.prod.yml` (API + PostGIS + Caddy for automatic HTTPS)
- `deploy/.env.production.example` (every setting documented)
- `deploy/Caddyfile`
- `deploy/DEPLOY.md` (step-by-step: buy domain → VPS → `docker compose up` → build APK with production URL)

Every file starts with a comment block saying it is inactive and how to switch it on.
Switching to production = set env values + rebuild the APK with
`--dart-define=API_BASE_URL=https://your-domain`.

---

## 5. Phases

Each phase is self-contained: it ends with working, committed code, so stopping
after any phase leaves the app in a good state. Order matters where noted.

### Phase 1 — Make it run on a real phone and shrink the APK
*Depends on: nothing.*
- Add `INTERNET` + location permissions to the main manifest.
- Configurable API URL (`--dart-define=API_BASE_URL=...`); default stays the emulator.
- Dev-only cleartext HTTP allowance (network security config) so a phone on
  the same Wi-Fi can reach the PC; production stays HTTPS-only.
- Start the UI immediately; restore the session in the background; show an
  error screen instead of a white screen if startup fails.
- Native splash in the app's colours instead of plain white.
- Release build settings: R8 + resource shrinking.
- `mobile/build_apk.ps1` (Windows) that builds split, obfuscated APKs and prints sizes.
- Instructions for running the backend so a phone can reach it (`--host 0.0.0.0`, firewall, LAN IP).
- Repository cleanup (AI Studio leftovers, dump file, `__pycache__`, `.gitignore`, `requirements.txt`).

**Done when:** the arm64 APK is ~15–20 MB, opens on a real phone, shows the map,
and loads coolers from the PC over Wi-Fi.

### Phase 2 — Backend rework + deploy-ready files
*Depends on: nothing (can run before or after Phase 1).*
- Split `main.py` into the structure in 4.2; delete dead code.
- Settings via environment; insecure defaults refused in production mode.
- Alembic migrations; clean schema reset; updated `seed.py`.
- Bounding-box pin endpoint + slim payloads; detail endpoint.
- Fix UUID lookups; DB-backed cooldowns and rate limits.
- Photo resize + thumbnails on upload.
- pytest suite for auth, trust rules, duplicate-distance guard and bbox query.
- Inactive deploy files from 4.4.

**Done when:** tests pass, `/docs` shows the new API, and the old app still
works against the old endpoints (kept temporarily for compatibility).

### Phase 3 — Mobile architecture rework (same look, much faster)
*Depends on: Phase 2 (uses the new endpoints).*
- Restructure into `core/` + `features/` with Riverpod.
- Viewport loading, clustering with cheap markers, debounced panning.
- Disk cache for last position + pins (instant start); tile caching.
- Optimistic status updates; consistent error and empty states.
- Upgrade `flutter_map` and other outdated packages.
- Remove the old compatibility endpoints from the backend.
- Widget and unit tests for repositories and the viewport loader.

**Done when:** cold start shows cached pins immediately, panning stays smooth
with hundreds of pins, and no file is over ~400 lines.

### Phase 4 — English + Arabic (RTL)
*Depends on: Phase 3.*
- `flutter_localizations` + `.arb` files for English and Arabic; every visible string moved.
- Direction-aware layouts (`EdgeInsetsDirectional`, `AlignmentDirectional`), mirrored icons where appropriate.
- Language switcher in profile/settings, saved on device; defaults to the phone's language.
- One bundled font family that covers Arabic and Latin (subset to keep size down).
- Backend error messages return codes the app translates.

**Done when:** switching to Arabic flips the whole app to RTL with no English left.

### Phase 5 — Admin panel as a local web page
*Depends on: Phase 2.*
- Server-rendered admin at `/admin`: login, pending queue, approve/reject,
  photo moderation, sponsors, force status.
- Remove admin screens and the 5-tap entry from the phone app.

**Done when:** all current admin tasks work from a browser on the PC and the
APK no longer contains admin code.

### Phase 6 — New brand + new UI
*Depends on: Phases 3 and 4, plus the owner's brand (from the Claude prompt) and Stitch designs.*
- Rename the app, Android application id and launcher icons.
- Apply the brand's colours, type and components as a theme.
- Rebuild each screen from the Stitch designs on top of the Phase 3 structure,
  keeping Arabic/RTL support.

**Done when:** every screen matches the approved designs in both languages.

---

## 6. Testing and verification

- **Backend:** pytest against a real PostGIS database (local Docker or a test DB).
- **Mobile:** `flutter analyze` + `flutter test` (unit and widget tests).
- **Limitation of the cloud workspace:** the Flutter SDK can be installed here,
  but the Android SDK download host is blocked, so **APKs cannot be built in
  this workspace**. The owner builds APKs on their PC with `mobile/build_apk.ps1`
  and reports the size and behaviour on the phone.

---

## 7. Out of scope (for now)

iOS, payments/donations, push notifications, IoT sensors, production hosting
itself (only the files to do it).
