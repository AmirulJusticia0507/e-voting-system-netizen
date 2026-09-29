# syntax=docker/dockerfile:1
#
# Image produksi e-netizen. Verified berjalan di linux/arm64 (Oracle Always
# Free) tanpa kompilasi: psycopg-binary, cryptography, cffi, dan Pillow
# semuanya punya wheel aarch64, sisanya pure-python.
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# libpq5 untuk psycopg, curl untuk healthcheck, build-essential sebagai jaring
# pengaman kalau suatu saat ada pin yang butuh kompilasi.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        libpq5 \
        curl \
        build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Layer dependensi dipisah supaya perubahan kode tidak memicu build ulang.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Jangan jalankan sebagai root.
RUN useradd --create-home --shell /bin/bash appuser \
 && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8000/api/votes/public/hub/ || exit 1

# daphne (bukan gunicorn) karena proyek ini memakai channels: hasil voting
# real-time lewat WebSocket tidak bisa dilayani WSGI.
ENTRYPOINT ["./deploy/entrypoint.sh"]
