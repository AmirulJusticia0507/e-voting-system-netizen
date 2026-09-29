#!/bin/sh
# Migrasi dijabat ke start supaya schema selalu sinkron sebelum app menerima
# trafik. Kalau migrasi gagal, container berhenti daripada melayani request
# dengan schema yang tidak cocok.
set -e

python manage.py migrate --noinput
python manage.py collectstatic --noinput

if [ -n "${DJANGO_SUPERUSER_USERNAME:-}" ] && [ -n "${DJANGO_SUPERUSER_PASSWORD:-}" ]; then
  python manage.py createsuperuser --noinput 2>/dev/null || true
fi

echo "e-netizen starting on :${PORT:-8000}"
exec daphne -b 0.0.0.0 -p "${PORT:-8000}" core.asgi:application
