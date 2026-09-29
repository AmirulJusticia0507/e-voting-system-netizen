# E-Voting System — Netizen

Sistem e-voting berbasis **Django (DRF + JWT)** untuk backend dan **Flutter** untuk frontend (Web / Android / iOS). Mendukung autentikasi nomor HP, OTP, login biometrik (fingerprint) & PIN, voting per topik, rekap hasil, WhatsApp notification, dan manajemen **Role & Permission (RBAC)**.

```
├── backend/            Django 5.1 + DRF + SimpleJWT + Channels (PostgreSQL)
│   ├── core/           settings, urls, asgi
│   ├── users/          User custom + JWT + login
│   ├── roles/          Role & Permission (RBAC)
│   ├── topics/         candidates/ votes/ comments/   domain voting
│   ├── netizens/       signup netizen
│   ├── elections/      multi-periode, wilayah & DPT
│   ├── audit/          audit trail berantai (HMAC-SHA256)
│   ├── notifications/  in-app + push FCM
│   └── dashboard/      dashboard template Django
└── evoting_flutter/    Aplikasi Flutter (Web/Android/iOS)
```

---

## 🔗 Kaitan dengan Civic Engagement Pipeline

Project ini adalah **komponen ke-4 (E-Netizen Voting)** dalam arsitektur **Civic Engagement Pipeline** (lihat [`CIVIC_ENGAGEMENT_PIPELINE.md`](../lex-dss/docs/CIVIC_ENGAGEMENT_PIPELINE.md) di project `lex-dss`):

```
[ Video YouTube DPRD/Pemda ]
         │
         ▼
┌─────────────────────────────────────┐
│ 1. STT ENGINE (Ingestion & Speech)  │
└──────────────────┬──────────────────┘
         │ (Raw Transcript)
         ▼
┌─────────────────────────────────────┐
│ 2. LEX INTEGRITY (Legal Auditor)    │
└──────────────────┬──────────────────┘
         │ (Audited Legal Risks & Context)
         ▼
┌─────────────────────────────────────┐
│ 3. LEX DSS (Decision Support System)│
└──────────────────┬──────────────────┘
         │ (Simplified Poll Payload)
         ▼
┌─────────────────────────────────────┐
│ 4. E-NETIZEN VOTING  ←  PROJECT INI │
│    • Auth (Face ID / NIK / OTP)     │
│    • Citizen Voting & Feedback      │
│    • Real-Time Analytics            │
└─────────────────────────────────────┘
```

Sistem ini menerima **payload polling mikro** (JSON) dari Lex DSS, memvalidasi pemilih (OTP + verifikasi wajah/NIK), mencatat suara dengan integritas kriptografis, dan mengembalikan agregat hasil ke Lex DSS sebagai *feedback loop* berbasis bukti.

---

## ✨ Fitur Utama

| Kategori | Fitur |
|----------|-------|
| **Auth** | Login HP + OTP (WhatsApp), Biometrik (Fingerprint/PIN), JWT |
| **RBAC** | Role: `superadmin`, `admin`, `netizen` + 10 permission granular |
| **Voting** | Per topik/kandidat, enkripsi AES-256-GCM, chain hash anti-tamper |
| **Integritas** | `previous_hash`, `integrity_hash`, `nonce`, `encrypted_choice`, verifikasi rantai |
| **OTP Verifikasi** | 6 digit via WhatsApp, TTL 10 menit, enforcement sebelum vote |
| **Multi-Periode/DPT** | `ElectionPeriod`, `Region`, `VoterRegistration` (DPT), enforcemen wilayah |
| **Realtime** | WebSocket (`ws/votes/<topic_id>/`) + REST fallback (`/votes/stats/`) |
| **Rekap Resmi** | Ed25519 signed recap (`/votes/recap/`), verifikasi publik (`/votes/recap/verify/`) |
| **Audit Trail** | HMAC-SHA256 chained logs, `/audit/chain/` verifikasi, evidence root hash |
| **Public Share** | Public results tanpa login, QR code, share URL, public hub & archive |
| **Gamifikasi** | Poin, streak, badge (`first_vote`, `streak_3/7/30`), leaderboard |
| **Analytics/Export** | Dashboard analitik, export CSV (results, votes, audit) |
| **Notifikasi** | In-app + broadcast admin, push FCM (opsional) |

---

## 🚀 Quick Start

### Backend (Django)

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/macOS
pip install -r requirements.txt

# Konfigurasi .env (salin dari .env.example)
# Isi: SECRET_KEY, DB_*, VOTE_ENCRYPTION_KEY, RESULT_SIGNING_KEY, WA_GATEWAY_TOKEN, VOTE_BROADCAST

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

**WebSocket (realtime):** butuh Redis + Daphne
```bash
pip install daphne
redis-server
daphne -b 0.0.0.0 -p 8000 core.asgi:application
```

### Frontend (Flutter)

```bash
cd evoting_flutter
flutter pub get
flutter run -d chrome        # Web
flutter run -d <device-id>   # Android/iOS
```

Base URL API otomatis per platform (lihat `lib/services/api_service.dart`).

---

## 📚 Dokumentasi Lengkap

Lihat **[SETUP.md](SETUP.md)** untuk:
- Setup detail (Ubuntu/Windows, PostgreSQL 15+ permissions, Python 3.14 + psycopg3)
- RBAC permission matrix per endpoint
- Struktur basis data relasi
- Alur integritas suara (chain hash + AES-GCM)
- OTP verifikasi pemilih (V2)
- Multi-periode, wilayah & DPT (V3)
- Hasil realtime & partisipasi (V4)
- Rekap resmi & tanda tangan digital Ed25519 (V5)
- Audit trail berantai & bukti transparan (V6)
- Viral & engagement: share/QR, region battle, gamifikasi (V7)
- Public hub, archive, recap verifikasi publik
- Analytics, export CSV, notifikasi, push FCM
- Troubleshooting umum

---

## 🔐 Environment Variables (Backend)

| Variable | Wajib | Deskripsi |
|----------|-------|-----------|
| `SECRET_KEY` | ✅ | Django secret (64+ char random) |
| `DEBUG` | | `True`/`False` |
| `ALLOWED_HOSTS` | ✅ | Comma-separated hosts |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` | ✅ | PostgreSQL connection |
| `VOTE_ENCRYPTION_KEY` | ✅ | 64+ char, kunci AES-256-GCM untuk enkripsi pilihan |
| `RESULT_SIGNING_KEY` | | Kunci privat Ed25519 untuk tanda tangan rekap (kosong = fallback SECRET_KEY) |
| `WA_GATEWAY_URL`, `WA_GATEWAY_TOKEN` | | WhatsApp gateway (Fonnte), kosong = mode simulasi |
| `VOTE_BROADCAST` | | `True`/`False` enable WebSocket broadcast |
| `PUBLIC_BASE_URL` | | Domain frontend untuk link share publik |
| `AUDIT_SECRET` | | Kunci HMAC audit trail (fallback SECRET_KEY) |
| `FCM_SERVER_KEY` | | Firebase server key untuk push notifikasi |

---

## 📱 Flutter Dependencies Utama

- `http`, `dio` — API client
- `flutter_secure_storage` — JWT storage
- `local_auth` — Biometrik (Android/iOS only)
- `qr_flutter`, `share_plus`, `mobile_scanner` — QR share/scan
- `web_socket_channel` — Realtime votes
- `firebase_messaging` — Push FCM (opsional)
- `csv`, `universal_html` — Export CSV (web/mobile)

---

## 🧪 Testing

```bash
# Backend
cd backend
python manage.py test

# Flutter
cd evoting_flutter
flutter test
```

---

## 📄 Lisensi

Proprietary / Internal Use — Netizen Civic Engagement Platform.