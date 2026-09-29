#!/usr/bin/env bash
# Provision/rebuild e-netizen di Oracle Cloud Always Free (ARM64).
#
#   ./deploy/provision.sh          # setup awal + jalankan
#   ./deploy/provision.sh --rebuild  # tarik perubahan lalu rebuild (data aman)
#
# Idempoten: dijalankan berkali-kali tidak merusak data yang sudah ada.
set -euo pipefail

REPO_URL="https://github.com/AmirulJusticia0507/e-voting-system-netizen.git"
APP_DIR="${APP_DIR:-$HOME/enetizen}"
COMPOSE="docker-compose.oracle.yml"
REBUILD=0
[ "${1:-}" = "--rebuild" ] && REBUILD=1

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# ── 1. Prasyarat ────────────────────────────────────────────────────────────
log "Memeriksa prasyarat..."
command -v docker >/dev/null 2>&1 || die "Docker belum terpasang. Jalankan: curl -fsSL https://get.docker.com | sh"
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 belum ada. Jalankan: sudo apt-get install -y docker-compose-plugin"
docker info >/dev/null 2>&1 || warn "Docker daemon belum jalan; coba: sudo systemctl start docker"

# ── 2. Ambil kode ───────────────────────────────────────────────────────────
if [ "$REBUILD" = "1" ] && [ -d "$APP_DIR/.git" ]; then
  log "Menarik perubahan terbaru..."
  git -C "$APP_DIR" pull --ff-only
else
  log "Meng-clone repository ke $APP_DIR..."
  [ -d "$APP_DIR" ] && die "$APP_DIR sudah ada. Gunakan --rebuild untuk memperbarui."
  git clone --depth 1 "$REPO_URL" "$APP_DIR"
fi
cd "$APP_DIR/backend"

# ── 3. Konfigurasi ──────────────────────────────────────────────────────────
gen_secret() { python3 -c "import secrets; print(secrets.token_urlsafe(48))"; }

if [ -f .env ]; then
  log ".env sudah ada, tidak ditimpa (rahasia dipertahankan)."
else
  log "Membuat .env dengan secret acak..."
  PUBLIC_IP="$(curl -fsS --max-time 10 https://api.ipify.org 2>/dev/null || echo '')"
  cat > .env <<EOF
DEBUG=0
DB_NAME=evoting
DB_USER=evoting
DB_PASSWORD=$(gen_secret)
SECRET_KEY=$(gen_secret)
VOTE_ENCRYPTION_KEY=$(gen_secret)
RESULT_SIGNING_KEY=$(gen_secret)
LEX_DSS_HMAC_SECRET=$(gen_secret)
ALLOWED_HOSTS=*
ENETIZEN_PORT=8000
VOTE_BROADCAST=True
CORS_ALLOWED_ORIGINS=
PUBLIC_BASE_URL=http://${PUBLIC_IP:-<IP-VM>}:8000
EOF
  chmod 600 .env
  warn "Simpan nilai LEX_DSS_HMAC_SECRET di .env — nilai yang sama harus"
  warn "dipasang sebagai ENETIZEN_HMAC_SECRET di Railway lex-dss-api."
fi

# shellcheck disable=SC1091
set -a; . ./.env; set +a

# ── 4. Build & jalankan ─────────────────────────────────────────────────────
log "Build image (bisa beberapa menit di ARM pertama)..."
docker compose -f "$COMPOSE" build

log "Menyalakan stack..."
docker compose -f "$COMPOSE" up -d

# ── 5. Tunggu sehat ─────────────────────────────────────────────────────────
log "Menunggu health check..."
for i in $(seq 1 60); do
  status="$(docker inspect --format '{{.State.Health.Status}}' \
    "$(docker compose -f "$COMPOSE" ps -q enetizen)" 2>/dev/null || echo unknown)"
  if [ "$status" = "healthy" ]; then
    log "Sehat setelah ${i} detik."
    break
  fi
  [ "$i" = "60" ] && {
    warn "Belum sehat setelah 60 detik. Log terakhir:"
    docker compose -f "$COMPOSE" logs --tail 40 enetizen
    exit 1
  }
  sleep 1
done

# ── 6. Ringkasan ────────────────────────────────────────────────────────────
PUBLIC_IP="$(curl -fsS --max-time 10 https://api.ipify.org 2>/dev/null || echo '<IP-VM>')"
echo
log "e-netizen aktif."
echo "   Health   : http://${PUBLIC_IP}:8000/api/votes/public/hub/"
echo "   DB       : postgres://${DB_USER}@<internal>:5432/${DB_NAME} (tidak diekspos)"
echo
log "Langkah berikutnya di Railway (service lex-dss-api):"
echo "   ENETIZEN_URL=https://<domain-atau-ip-vm>:8000"
echo "   ENETIZEN_HMAC_SECRET=<isi sama dengan LEX_DSS_HMAC_SECRET di .env>"
echo
log "Uji integrasi dari Lex-DSS:"
echo "   curl -H \"Authorization: Bearer <JWT>\" \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"event_id\":\"POLL-TES-1\",\"question\":\"Uji integrasi?\","
echo "         \"options\":[{\"code\":\"A\",\"label\":\"Ya\"},{\"code\":\"B\",\"label\":\"Tidak\"}]}' \\"
echo "     https://<lex-dss-domain>/api/v1/civic-poll/drafts"
