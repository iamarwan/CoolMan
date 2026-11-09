# Sabil (CoolMan) — Getting Started

## Project layout

| Folder | What it is |
|---|---|
| `app/` | FastAPI backend (routers, models, services) |
| `migrations/` | Database migrations (Alembic) |
| `scripts/` | `reset_db.py`, `seed.py` |
| `tests/` | Backend tests (pytest) |
| `mobile/` | Flutter Android app |
| `deploy/` | Production files — **inactive until you deploy** (see `deploy/DEPLOY.md`) |
| `docs/` | Rework plan and design prompts |

---

## Part 1 — One-time setup

### Database (PostgreSQL + PostGIS on port 5433)
Either your native Windows PostgreSQL (with PostGIS) or Docker:
```powershell
docker compose up -d
```
Database `sabil_db`, user `sabil`, password `sabil_pass`.

For backend tests, create a second database once:
```powershell
createdb -U sabil -p 5433 sabil_test
# Docker: docker exec sabil-postgis createdb -U sabil sabil_test
```

### Backend
```powershell
python -m venv venv
venv\Scripts\pip install -r requirements-dev.txt
```

### ⚠️ One-time database reset (after this rework)
The schema changed. Your database only had test data, so wipe and re-create it:
```powershell
.\run_backend.ps1 -Reset
```
This creates sample coolers in Maadi plus two test accounts:
`tester` / `tester1234` (new user) and `trusted` / `trusted1234` (instant approval).

### Flutter
```powershell
cd mobile
flutter pub get
```

---

## Part 2 — Every session

```powershell
# 1. Database running (Windows service, or: docker start sabil-postgis)
# 2. Backend (applies new migrations automatically, then starts on port 8000)
.\run_backend.ps1
# 3. App on the emulator
cd mobile
flutter run
```

API docs: http://localhost:8000/docs · Health check: http://localhost:8000/health

**Admin panel:** http://localhost:8000/admin (development login: `admin` / `admin123`).
Review new coolers, status changes and photos; edit coolers; manage sponsors.
It also works from any device on your Wi-Fi at `http://<your-pc-ip>:8000/admin`.
The admin screens are no longer inside the phone app.

Run backend tests: `.\run_backend.ps1 -Test`

---

## Part 3 — Test on a REAL phone (same Wi-Fi as your PC)

`10.0.2.2` only works inside the Android emulator. A real phone must reach your
PC through its Wi-Fi IP address.

1. **Start the backend** with `.\run_backend.ps1` (it listens on all interfaces).
2. **Allow port 8000 through Windows Firewall** (PowerShell as Administrator, once):
   ```powershell
   New-NetFirewallRule -DisplayName "Sabil API 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private
   ```
   Your Wi-Fi network must be set to **Private** in Windows network settings.
3. **Check from the phone's browser:** open `http://<your-pc-ip>:8000/health`.
   Find your PC's IP with `ipconfig` (the "IPv4 Address" of the Wi-Fi adapter).
4. **Build the APK** (auto-detects your PC's IP):
   ```powershell
   cd mobile
   .\build_apk.ps1
   ```
5. **Install** `mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`
   (USB: `adb install -r <that file>`, or copy it to the phone and open it).

If your PC's IP changes, rebuild with `.\build_apk.ps1`.
To run on a USB-connected phone in debug mode instead:
`flutter run --dart-define=API_BASE_URL=http://<your-pc-ip>:8000`

**Expected size:** ~15–20 MB for the arm64 APK (the old single "fat" APK was ~70 MB).

**If something goes wrong on the phone,** connect it by USB, run
`adb logcat -s flutter` while opening the app, and send the output.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `type "geometry" does not exist` / PostGIS errors | Run `CREATE EXTENSION postgis;` in `sabil_db` |
| Backend won't start: "relation already exists" | Run `.\run_backend.ps1 -Reset` once (old schema) |
| Phone shows "Failed to load coolers" | Phone and PC on the same Wi-Fi? Firewall rule added? `http://<pc-ip>:8000/health` opens in the phone browser? |
| Emulator can't reach the API | The emulator uses `10.0.2.2:8000` automatically; make sure the backend is running |
| Login rejected after reset | Old saved login — log out in Profile, or reinstall the app |
