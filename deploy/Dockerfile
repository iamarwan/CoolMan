# ─────────────────────────────────────────────────────────────────────────────
# INACTIVE UNTIL DEPLOYMENT. Nothing uses this file during local development.
# It builds the API server image for production. See deploy/DEPLOY.md.
# Build context is the repository root:
#   docker build -f deploy/Dockerfile -t sabil-api .
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /srv

COPY requirements.txt constraints.txt ./
# constraints.txt pins the exact versions that passed the tests.
RUN pip install -r requirements.txt -c constraints.txt

COPY app ./app
COPY migrations ./migrations
COPY scripts ./scripts
COPY alembic.ini .

RUN useradd --create-home --uid 10001 sabil \
    && mkdir -p /srv/uploads \
    && chown -R sabil:sabil /srv/uploads
USER sabil

EXPOSE 8000

# Apply database migrations, then start the API.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2 --proxy-headers --forwarded-allow-ips='*'"]
