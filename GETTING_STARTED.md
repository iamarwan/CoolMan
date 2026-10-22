# Getting Sabil running on a laptop (step by step)

This guide takes you from "nothing installed" to "the app is running on an emulator". Commands are for **Windows PowerShell**; Mac/Linux differences are noted.

**Short answer to "do I still use Docker?"** Yes, but **only for the database**. Docker runs PostgreSQL + PostGIS. The server (FastAPI) and the app (Flutter) run directly on your laptop, not in Docker.

You need three things running, each in its own terminal:

| # | What | Where it runs | Command |
|---|---|---|---|
| 1 | Database | Docker | `docker compose up -d` |
| 2 | Server (backend) | Your laptop, in `backend/` | `uvicorn sabil.main:app --reload` |
| 3 | App | Android emulator | `flutter run` (in `mobile/`) |

---

## Part 1: One-time setup

### 1. Install the tools
- **Git**: https://git-scm.com/downloads
- **Docker Desktop**: https://www.docker.com/products/docker-desktop (start it once; wait until it says "running")
- **Python 3.11 or newer**: https://www.python.org/downloads (tick **"Add python.exe to PATH"** in the installer)
- **Flutter SDK** and **Android Studio** (for the emulator): https://docs.flutter.dev/get-started/install. Afterwards run `flutter doctor` and fix anything marked with a red cross.
- **Antigravity** (Google's AI code editor): install it from Google's site. It works like VS Code.

Check they work (each should print a version):
```powershell
git --version
docker --version
python --version
flutter --version
```

### 2. Get the code from GitHub
Pick a folder (for example `C:\Projects`) and run:
```powershell
cd C:\Projects
git clone https://github.com/iamarwan/CoolMan.git
cd CoolMan
git checkout restructure
```
`restructure` is the branch with all the new work (`main` is still the old layout). If you already have an old copy of the project, **do not clone over it**: rename the old folder first, or clone into a new one.

If Git asks you to sign in, use your GitHub account (a browser window opens).

### 3. Open it in Antigravity
1. Start Antigravity.
2. **File > Open Folder** and choose the `CoolMan` folder (the one containing `backend`, `mobile`, `docker-compose.yml`).
3. Install the extensions it suggests, or open the Extensions panel and install **Python** and **Dart** + **Flutter**.
4. Open its built-in terminal (**Terminal > New Terminal**). You will use this for the commands below; open extra terminal tabs with the **+** button.

You can also use any other terminal; Antigravity is only the editor.

### 4. Create the Python environment (once)
```powershell
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```
(Mac/Linux: `source venv/bin/activate`.) Your prompt now starts with `(venv)`.

Tell Antigravity to use it: press `Ctrl+Shift+P`, type **Python: Select Interpreter**, choose the one inside `backend\venv`.

> The repo contains `.vscode/settings.json` pointing at an old `venv\Scripts\python.exe` in the repo root. It is out of date: ignore it and select the interpreter as above.

### 5. Get the Flutter packages (once)
```powershell
cd ..\mobile
flutter pub get
cd ..
```

---

## Part 2: Every time you work on the app

### Step 1: Start the database (Docker)
Make sure Docker Desktop is running, then from the repo root (the folder with `docker-compose.yml`):
```powershell
docker compose up -d
```
This starts a container called `sabil-postgis` (PostGIS 16) on **port 5433**, user `sabil`, password `sabil_pass`, database `sabil_db`. Your data is kept in a Docker volume, so it survives restarts. Stop it with `docker compose down` (data stays; add `-v` only if you want to erase it).

### Step 2: Start the server
In a new terminal:
```powershell
cd backend
venv\Scripts\activate
uvicorn sabil.main:app --reload --host 0.0.0.0 --port 8000 --reload-exclude "uploads"
```
- Always start it **from the `backend` folder**, and use `sabil.main:app`. The old `main.py` in the project root no longer exists.
- Tables are created automatically on first start.
- Open http://localhost:8000/docs to see and try every endpoint.
- **First time only:** to put sample coolers in the (empty) database, run in another terminal in `backend` with the venv active: `python -m scripts.seed`

> **After pulling new code, if your database already existed:** run `python -m scripts.sync_schema --apply` once in `backend/` (venv active). Recent changes added columns (`users.phone`, `water_coolers.dedicated_to`, `water_coolers.dedication_message`, `water_coolers.cups_enabled`); without them the server fails with `column users.phone does not exist`. It only adds missing columns; it never drops anything unless you add `--drop-extra`.

### Step 3: Start the app
1. In Android Studio open **Device Manager** and start an emulator (or run `flutter emulators --launch <id>`).
2. In the emulator's **... > Location** panel set a point in Cairo, for example latitude `29.9596`, longitude `31.2575` (Maadi), so the seeded coolers appear.
3. In a new terminal:
```powershell
cd mobile
flutter run
```
The emulator reaches your laptop's server at `10.0.2.2:8000`; that is already set in `mobile/lib/core/config.dart`.

### Using a real phone instead of the emulator
1. Phone and laptop on the same Wi-Fi.
2. Find the laptop's IP: `ipconfig` (look for IPv4, e.g. `192.168.1.20`).
3. Edit `mobile/lib/core/config.dart` and change `baseUrl` to `http://192.168.1.20:8000`.
4. Keep the server started with `--host 0.0.0.0` (as in Step 2) and allow Python through the Windows firewall if asked.
5. `flutter run` with the phone plugged in (USB debugging on).

### Trying phone sign-in on your laptop
In the app's login pop-up choose the **Phone** tab, type a number such as `01012345678` and tap **Send code**. No text is sent in development: look in the **server terminal** for a line like `SMS to +201012345678: Sabil code: 123456 ...` and type that code in the app. A number with no account yet is then asked for a username.

### Admin screen
In the app, tap the app title 5 times to open the admin login. In development the login is `admin` / `admin123`.

---

## What changed compared to before

| Before | Now |
|---|---|
| `main.py`, `models.py`, etc. in the repo root | Everything in `backend/sabil/`, split by feature |
| `uvicorn main:app` | `uvicorn sabil.main:app` run **from `backend/`** |
| Photos in `uploads/` in the root | `backend/uploads/` (move old photos there, otherwise they show as missing) |
| Photos open to anyone with the link | Unapproved photos/coolers only visible to admin and the person who added them |
| `db_fix.py` for DB changes | Removed. There are no migrations yet (see below) |
| Settings hard-coded | Environment variables (table below) |

### Your existing database
The tables are created if missing, but **existing tables are never altered**. Your old database still has three columns the code no longer uses (`taste_reports`, `is_wheelchair_accessible`, `needs_urgent_refill`). They are harmless. If you ever hit a "column does not exist" error, or want a clean start, the simplest fix is to erase the database and re-seed:
```powershell
docker compose down -v
docker compose up -d
```
then restart the server and run `python -m scripts.seed`.

Or keep your data and only compare/fix the columns: from `backend/` run `python -m scripts.sync_schema` (just reports), then `python -m scripts.sync_schema --apply` (adds missing columns) and, if you want the three unused ones gone, `--apply --drop-extra` (back up first). (If you used a natively installed PostgreSQL before, you can stop using it: Docker replaces it.)

---

## Settings (environment variables)

Set them in the terminal **before** starting the server, e.g. `$env:SABIL_ENV="production"` (PowerShell). Anything unset uses the default.

| Variable | Default | What it is |
|---|---|---|
| `SABIL_DATABASE_URL` | `postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable` | Database connection (matches `docker-compose.yml`) |
| `SABIL_ENV` | `development` | Set to `production` on a real server: it then **refuses to start** unless `SABIL_JWT_SECRET` (32+ random characters) and `SABIL_ADMIN_PASSWORD` are set |
| `SABIL_JWT_SECRET` | `change-me-in-production` | Signs login tokens. Change on any real server |
| `SABIL_ADMIN_USERNAME` / `SABIL_ADMIN_PASSWORD` | `admin` / `admin123` | In-app admin login. Change the password on any real server |
| `SABIL_ADMIN_TOKEN_MIN` / `SABIL_USER_TOKEN_MIN` | `480` / `10080` | How long logins last, in minutes |
| `SABIL_AUTH_MAX_ATTEMPTS` | `10` | Login/register attempts allowed per IP per minute |
| `SABIL_SMS_PROVIDER` | `console` in development, `none` in production | How phone sign-in codes are sent. `console` prints the code in the server terminal (development only). `none` switches phone sign-in off. A real SMS company still has to be added in `backend/sabil/core/sms.py` |

You do not need any of these for normal development.

---

## Tests (optional)

Run against a throw-away database, never your real one. From `backend/` with the venv active:
```powershell
docker exec sabil-postgis psql -U sabil -d sabil_db -c "CREATE DATABASE sabil_test;"
pip install -r requirements-dev.txt
$env:SABIL_DATABASE_URL="postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_test?ssl=disable"
python -m pytest tests -q
```
(44 tests; the PostGIS extension is enabled by the test setup. If the test database already existed before the latest update, run `python -m scripts.sync_schema --apply` against it first, or drop and recreate it.)

## Making a code snapshot for an AI chat
```powershell
python tools/pack_code.py
```
creates `coolman_dump_<date>_<time>.txt` in the repo root with every source file in one text file.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker compose up` fails / "cannot connect to the Docker daemon" | Docker Desktop is not running | Start Docker Desktop, wait until it says running |
| Server error "connection refused" on port 5433 | Database container is not running | `docker compose up -d`, check with `docker ps` |
| `ModuleNotFoundError: sabil` | Started from the wrong folder | `cd backend` first, use `sabil.main:app` |
| `function st_dwithin does not exist` | PostGIS missing (not using the Docker image) | Use `docker compose up -d`, which provides PostGIS |
| App shows no coolers / network error | Server not running, or wrong address | Check http://localhost:8000/docs opens; emulator uses `10.0.2.2`; real phone needs your LAN IP |
| Old photos show as missing | `uploads/` folder moved | Copy the old `uploads` folder into `backend/` |
| Server will not start and mentions JWT secret/admin password | `SABIL_ENV=production` without the required settings | Set them, or unset `SABIL_ENV` for development |
| Server error `column users.phone does not exist` | Database made before phone sign-in / dedications | `python -m scripts.sync_schema --apply` in `backend/` |
| Phone tab says "Phone sign-in is not available" | `SABIL_SMS_PROVIDER` is `none` (or the server runs in production mode) | Unset it in development (default is `console`) |
| Login rejected after changes | Old saved token | Log out in the profile screen, or clear the app data |
| `flutter doctor` shows red crosses | Missing Android licences/SDK | `flutter doctor --android-licenses`, install missing parts in Android Studio |
