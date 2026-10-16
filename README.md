# Sabil (CoolMan)

A crowd-sourced map of public water coolers (*sabil*) in Egypt. People add coolers, report whether they work or are empty, and attach photos. An admin reviews new submissions. Users earn **trust points** for good reports; trusted users skip the review queue.

| Part | Tech | Folder |
|---|---|---|
| Phone app | Flutter (Dart), OpenStreetMap tiles | `mobile/` |
| Server | FastAPI + async SQLAlchemy | `backend/` |
| Database | PostgreSQL with PostGIS (distance queries) | `docker-compose.yml` |

## Run it

Step-by-step instructions (database, server, app, settings) are in **[GETTING_STARTED.md](GETTING_STARTED.md)**. The short version:

```bash
docker compose up -d                      # database
cd backend
pip install -r requirements.txt
uvicorn sabil.main:app --reload           # server on http://localhost:8000  (docs at /docs)
cd ../mobile && flutter run               # the app
```

## Where to look

| I want to... | Read |
|---|---|
| Understand how the code is organised, file by file | [DOCUMENTATION.md](DOCUMENTATION.md) |
| Reuse a piece in another project | "Reusable pieces" in [DOCUMENTATION.md](DOCUMENTATION.md) |
| See known problems and what has been fixed | [docs/FINDINGS_LOG.md](docs/FINDINGS_LOG.md) |
| Read the product plan | [BUSINESS_STRATEGY.md](BUSINESS_STRATEGY.md) |

## Tests

```bash
cd backend
pip install -r requirements-dev.txt
SABIL_DATABASE_URL="postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_test?ssl=disable" python -m pytest tests -q
```

GitHub also runs `flutter analyze` on every push (`.github/workflows/flutter-analyze.yml`).
