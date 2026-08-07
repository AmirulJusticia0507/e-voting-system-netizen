# E-Voting System — Netizen

Sistem e-voting berbasis **Django (DRF + JWT)** untuk backend dan **Flutter** untuk frontend (Web / Android / iOS). Mendukung autentikasi nomor HP, OTP, login biometrik (fingerprint) & PIN, voting per topik, rekap hasil, WhatsApp notification, dan manajemen **Role & Permission (RBAC)**.

```
├── backend/            Django 5.1 + DRF + SimpleJWT + Channels (PostgreSQL)
│   ├── core/           settings, urls, asgi
│   ├── users/          User custom + JWT + login
│   ├── roles/          Role & Permission (RBAC) [BARU]
│   ├── topics/ cadidates/ votes/ comments/   domain voting
│   ├── netizens/       signup netizen
│   └── dashboard/      dashboard template Django
└── evoting_flutter/    Aplikasi Flutter (Web/Android/iOS)
```

---

## 1. Prasyarat

- **Python** 3.10+ (disarankan 3.12)
- **PostgreSQL** 14+ (berjalan)
- **Redis** (opsional, hanya untuk WebSocket real-time)
- **Flutter** SDK (disarankan 3.x, `sdk: ^3.0.0`)
- Android Studio / emulator untuk run mobile, atau Chrome untuk Web

---

## 2. Setup Backend (Django)

```bash
cd backend

# 2a. Buat venv (Linux/macOS)
python3 -m venv venv
source venv/bin/activate

# (Windows PowerShell)
# python -m venv venv
# venv\Scripts\activate

# 2b. Install dependensi
pip install -r requirements.txt
```

> Catatan: repo ini pernah berisi `backend/venv` dari sistem Windows.
> Jika `import django` gagal, buang folder `venv` lama lalu buat ulang seperti di atas.

### 2a. Konfigurasi `.env`

Salin `backend/.env` (sudah ada) dan isi nilainya:

```env
DEBUG=True
SECRET_KEY=ganti-dengan-random-string
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2

DB_NAME=e_voting
DB_USER=postgres
DB_PASSWORD=password-db
DB_HOST=127.0.0.1
DB_PORT=5432

# WhatsApp (opsional — dikosongkan = mode simulasi/log)
WA_GATEWAY_URL=https://api.fonnte.com/send
WA_GATEWAY_TOKEN=

# 🔐 Integritas suara (WAJIB ganti 64+ karakter acak di produksi)
VOTE_ENCRYPTION_KEY=GANTI_DENGAN_STRING_ACA_64+_KARAKTER

# 🔏 Kunci tanda tangan rekap resmi (opsional; kosong = pakai SECRET_KEY di dev)
RESULT_SIGNING_KEY=

# 🔴 Broadcast realtime (True/False)
VOTE_BROADCAST=True
```

### 2b. Buat Database

```sql
CREATE DATABASE e_voting;
CREATE USER voting_user WITH PASSWORD 'password-db';
GRANT ALL PRIVILEGES ON DATABASE e_voting TO voting_user;
```

### 2c. Migrasi & Seed data

```bash
python manage.py makemigrations --check     # pastikan schema selaras
python manage.py migrate

# Buat superuser (role superadmin otomatis/backfill)
python manage.py createsuperuser

python manage.py runserver 0.0.0.0:8000
```

**Role & Permission dibuat otomatis** lewat migrasi `roles.0001` dan di-backfill ke user lama lewat `roles.0002`:

| Role           | is_staff / is_superuser | Permission default                                                                                   |
| -------------- | ----------------------- | ---------------------------------------------------------------------------------------------------- |
| `superadmin` | superuser = true        | Semua (9) permission                                                                                 |
| `admin`      | is_staff=true           | manage_users, manage_topics, manage_candidates, manage_votes, manage_comments, view_results, comment |
| `netizen`    | is_staff=false          | vote, comment, view_results                                                                          |

Daftar `Permission` yang disematkan:
`manage_users`, `manage_topics`, `manage_candidates`, `manage_votes`,
`manage_comments`, `manage_roles`, `vote`, `comment`, `view_results`,
`manage_elections` (ditambahkan via migration `roles.0003`).

### 2d. WebSocket (real-time hasil)

- Jalankan Redis: `redis-server`
- Jalankan lewat **daphne** (bukan runserver WSGI) agar WebSocket berjalan:

```bash
pip install daphne
daphne -b 0.0.0.0 -p 8000 core.asgi:application
```

Endpoint WebSocket: `ws://<host>:8000/ws/votes/<topic_id>/`

- Consumer: `votes/consumers.py`, routing: `votes/routing.py`.
- Broadcast tiap suara baru: `votes/signals.py` (best-effort; bila Redis off, REST tetap normal & login tak masalah).
- Fallback REST: `GET /api/votes/stats/` (rekap + partisipasi semua topik).

---

## 3. Setup Flutter

```bash
cd evoting_flutter
flutter pub get
```

### 3a. Base URL API

`lib/services/api_service.dart` menentukan `baseUrl` otomatis saat ini:

| Platform         | URL                               |
| ---------------- | --------------------------------- |
| Web / desktop    | `http://localhost:8000/api`     |
| Android emulator | `http://10.0.2.2:8000/api`      |
| iOS simulator    | `http://localhost:8000/api`     |
| Device fisik     | sesuaikan manual ke IP LAN server |

### 3b. Jalankan

```bash
flutter run -d chrome        # Web
flutter run -d <device-id>   # Android/iOS
```

### 3c. Fingerprint (biometrik)

- Bergantung paket `local_auth`. Hanya berfungsi di **Android/iOS** (tidak di Web).
- Saat login, tekan ikon **fingerprint**. Pada `AuthGate`, jika sudah pernah login, aplikasi akan meminta sidik jari sebelum masuk.
- Di halaman Signup, tersedia toggle **Aktifkan Biometrik** / **Aktifkan PIN** (salah satu).

> Catatan: biometrik hanya berperan sebagai *unlock* lokal — token JWT tetap didapat pertama kali lewat login biasa.

---

## 4. Role & Permission (RBAC) — cara pakai

Semua endpoint `/api/*` memakai permission default DRF `AllowAny`, namun **viewset** yang terkurasi kini menerapkan kelas permission sendiri. Ringkasan:

| Endpoint                                                               | Metode baca (GET)             | Metode tulis (POST/PUT/PATCH/DELETE)                                     |
| ---------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------ |
| `/api/users/`                                                        | butuh login                   | butuh`manage_users`                                                    |
| `/api/users/me/`                                                     | butuh login                   | butuh login                                                              |
| `/api/users/<id>/set_role/`                                          | —                            | butuh`manage_users`                                                    |
| `/api/roles/` `permissions/`                                       | butuh login                   | butuh`manage_roles`                                                    |
| `/api/topics/`                                                       | semua                         | butuh`manage_topics`                                                   |
| `/api/candidates/`                                                   | semua                         | butuh`manage_candidates`                                               |
| `/api/votes/`                                                        | butuh login                   | butuh`vote` (netizen)                                                  |
| `/api/votes/results/`                                                | butuh login                   | —                                                                       |
| `/api/votes/chain/`                                                  | butuh login                   | status integritas seluruh rantai suara                                   |
| `/api/votes/<id>/verify/`                                            | —                            | butuh login (POST; cek hash & dekripsi)                                  |
| `/api/comments/`                                                     | semua                         | butuh`comment` (delete/Apabila hanya pemilik atau `manage_comments`) |
| `/api/auth/admin-login/`, `/api/token/`, `/api/netizens/signup/` | —                            | public                                                                   |
| `/api/auth/otp/request/`                                             | —                            | public (kirim kode OTP ke HP)                                            |
| `/api/auth/otp/verify/`                                              | —                            | public (verifikasi + beri token)                                         |
| `/api/elections/`                                                    | butuh login                   | butuh`manage_elections`                                                |
| `/api/elections/<id>/voters/`                                        | GET butuh`manage_elections` | POST butuh`manage_elections` (daftar/matiin DPT)                       |
| `/api/elections/<id>/remove_voter/`                                  | —                            | POST butuh`manage_elections`                                           |
| `/api/elections/regions/`                                            | butuh login                   | butuh`manage_elections`                                                |
| `/api/votes/stats/`                                                  | butuh login                   | — (rekap + partisipasi semua topik)                                     |
| `/api/votes/recap/`                                                  | butuh login                   | — (rekap resmi ter-tanda tangan)                                        |
| `/api/votes/recap/verify/`                                           | —                            | POST`{data, signature, public_key}` → `{valid}`                     |

### Alur logis penugasan role

1. Login (admin) → buka menu **Kelola User**.
2. Ikon admin panel → pilih role dari dropdown → **Tugaskan Role**.
3. Menu utama di Flutter dibangun otomatis berdasarkan `permission_codes` user (menu yang tak diizinkan tidak ditampilkan).

---

## 5. Struktur Basis Relasi Baru

```
users_User.roles (FK) -> roles_Role
roles_Role.permissions (M2M) -> roles_Permission
roles_Role.users (reverse)   -> users_User
```

`User.has_permission(code)` = `is_superuser` (True) atau ada di `role.permissions`.
Dipakai oleh kelas permission DRF di `roles/permissions.py`.

### 5b. Integritas Suara (anti-tamper)

Setiap `Vote` kini berlapis:

| Field                | Fungsi                                               |
| -------------------- | ---------------------------------------------------- |
| `previous_hash`    | hash suara sebelumnya (membentuk**chain**)     |
| `integrity_hash`   | HMAC-SHA256 dari`prev_hash \| candidate_id \| nonce` |
| `nonce`            | nilai acak agar dua suara berbeda punya hash berbeda |
| `encrypted_choice` | `candidate_id` dienkripsi **AES-256-GCM**    |
| `verifiable`       | True jika keempat kolom integritas terisi            |

Cara verifikasi: `POST /api/votes/<id>/verify/` (hitung ulang hash & dekripsi), dan
`GET /api/votes/chain/` (daftar `link_valid` per suara + `chain_valid` global).
Jika ada satu suara diubah, semua rantai setelahnya jadi `link_valid=False` → tamper terdeteksi.
Kunci pemakaian: `VOTE_ENCRYPTION_KEY` di `.env`.

### 5c. OTP Verifikasi Pemilih (V2)

Memastikan pemilih benar-benar pemilik nomor sebelum bisa memilih.

| Endpoint                                               | Fungsi                                                                                                                         |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `POST /api/auth/otp/request/` `{phone_number}`     | generate + kirim kode 6 digit (WhatsApp), TTL**10 menit**. Di mode `DEBUG` response menyertakan `dev_otp` untuk tes. |
| `POST /api/auth/otp/verify/` `{phone_number, otp}` | valid kode →`is_verified=True`, balas refresh/access token + user.                                                          |

Logika:

- Field: `users.User.otp_code`, `users.User.otp_expires_at`.
- Implementasi: `users/otp.py`, view di `users/views.py`.
- **Enforcement**: `votes/views.py` menolak voting jika `user.is_verified=False`.

### 5d. Multi-Periode, Wilayah & DPT (V3)

| Model                          | Peran                                                                                     |
| ------------------------------ | ----------------------------------------------------------------------------------------- |
| `election.Region`            | Wilayah (nama + kode), mis. provinsi/kabupaten                                            |
| `election.ElectionPeriod`    | Periode pemilihan dengan`start_at`/`end_at` & `is_active` (bisa berjalan bersamaan) |
| `election.VoterRegistration` | **DPT** — pemilih terdaftar sah pada suatu periode (`unique(user, election)`)    |
| `topics.Topic`               | kini punya`election` & `region` (nullable; kosong = legacy/nasional)                  |

Enforcement di `votes/views.py` (di atas semua cek V2):

- Periode harus aktif & `now ∈ [start_at, end_at]`.
- Pemilih harus ada di DPT periode tersebut & `is_active=True`.
- Bila `topic.region` dan `reg.region` terisi, keduanya harus sama.
- `Topic` legacy tanpa `election` tetap memperbolehkan voting (backward compat).

Admin UI Flutter: **Kelola Pemilihan** (periode + DPT) dan **Kelola Wilayah**.

### 5e. Hasil Realtime & Partisipasi (V4)

- **REST**: `GET /api/votes/stats/` → `{total_votes, topics:[{topic_id, topic_title, total_votes, total_registered, participation_percent, candidates:[{candidate_id, candidate_name, votes}]}]}`
- **WebSocket** `ws://.../ws/votes/<topic_id>/`:
  - on connect: kirim `{"type":"snapshot","data":{...}}`
  - tiap suara baru: broadcast `{"type":"update","data":{...}}`
- **Partisipasi** = `total_votes / total_registered (DPT)` × 100; `total_registered` = jumlah `VoterRegistration(is_active=True)` pada periode topik tersebut (None bila topik tanpa periode).
- Flutter: halaman **Hasil Realtime** (`/live_results`, daftar cand + partisipasi, real-time via WebSocket).

Aktifkan/mati broadcast via env: `VOTE_BROADCAST=True|False`.

### 5f. Rekap Resmi (Ci.Cii) & Tanda Tangan Digital (V5)

- **`GET /api/votes/recap/`** → hasil resmi per periode (rekap per-wilayah + total + partisipasi) yang **di-tanda-tangani**:

```json
{
  "manifest_hash": "sha256...",
  "signature": "hex",
  "public_key": "hex",
  "signature_algorithm": "ed25519",
  "data": { "type": "ci-cii_recap", "generated_at": "...", "elections": [...] }
}
```

- Berbasis **Ed25519** (`votes/signature.py`). Manifest dibuat deterministik (JSON terurut)
  → di-hash SHA-256 → ditandatangani dengan kunci privat server.
- **`POST /api/votes/recap/verify/`** `{data, signature, public_key}` → `{"valid": true/false}`.
  Siapa pun yang memiiki `public_key` dapat memverifikasi keaslian hasil.
- Kunci pemakaian: `RESULT_SIGNING_KEY` di `.env` (kosongkan → fallback `SECRET_KEY`, hanya untuk development).
- Flutter: halaman **Rekap Resmi** (`/recap`) — tampilkan rekap per wilayah + tombol **verify**.

---

## 5. V6 — Audit Trail Berantai & Bukti Transparan

Sistem mencatat **setiap aksi penting** (tabel `AuditLog`) yang dirantai dengan hash
(HMAC-SHA256) sehingga tidak dapat diubah tanpa memutus rantai. Ditambah **bukti ringkas**
untuk transparansi tanpa membocorkan detail suara.

### Endpoint

- `GET /api/audit/` — daftar log (auth). Kolom: `action`, `actor`, `target_type/pk`,
  `ip_address`, `user_agent`, `detail`, `previous_hash`, `integrity_hash`, `timestamp`.
- `GET /api/audit/chain/` — verifikasi seluruh rantai → `{"chain_valid": true/false}`.
- `GET /api/votes/evidence/` — per-topik: `total_votes` + **aggregate root hash** dari semua
  `integrity_hash` suara + tabel hasil per kandidat (tanpa detail per voter, ringan untuk device).

### Event yang teraudit

- `auth.login`, `auth.admin_login`, `auth.otp.request`, `auth.otp.verify`, `auth.otp.verify.fail`
- `user.set_role`, `role.create/update/delete`
- `vote.cast` (dengan `integrity_hash` sang suara)
- `region.create/update/delete`, `election.create/update/delete`, `dpt.register/update`

### Cara kerja

1. `audit/services.compute_hash(previous_hash, action, actor_id, target_type, target_pk, detail, nonce)`
   → HMAC-SHA256 pakai kunci `AUDIT_SECRET` (fallback `SECRET_KEY`).
2. Setiap baris menautkan hash baris sebelumnya (`previous_hash`) → rantai (chain).
3. `GET /api/audit/chain/` memutar ulang rantai; bila ada celah/ubah, `chain_valid` jadi `false`.

> **Catatan**: tambahkan `audit` ke `INSTALLED_APPS` (sudah) & jalankan `python manage.py makemigrations audit` lalu `migrate`.

### Halaman Flutter

- Route `/audit` (`audit_page.dart`) — menampilkan:
  - **Chain Audit**: status `chain_valid` (valid/putus) + jumlah entri.
  - **Bukti Hasil Ringkas**: `total_votes` + aggregate root hash + hasil per kandidat.
  - **Riwayat Log**: daftar recent (waktu, aksi, actor, `previous_hash`, `integrity_hash`, status `link_valid`).
- Entri menu **"Audit Trust"** tersedia di menu netizen (`/home`) dan menu admin.

---

---

## 6. V7 — Viral & Engagement (Share/QR, Region Battle, Gamifikasi)

Supaya hasil "keluar dari kotak WhatsApp" dan ajang voting terasa ramai ala Korea:

### A. Share & QR (transparansi publik, tanpa login)

- `GET /api/votes/public/<topic_id>/` (AllowAny) — hasil topik + `evidence_root` + share payload.
- `GET /api/votes/public/share/<topic_id>/` (AllowAny) — `share_url`, `share_text`, ringkasan (untuk QR/tombol share).
- Setting `PUBLIC_BASE_URL` di `.env` menentukan domain link share (produksi: domain web Flutter).
- Flutter:
  - `widgets/topic_share_sheet.dart` — bottom-sheet QR + "Salin"/"Bagikan" (pakai `qr_flutter` + `share_plus`).
  - Tombol share di halaman Voting & Hasil; `pages/qr_scan_page.dart` (scan QR buka hasil, `mobile_scanner`).
  - `pages/public_results_page.dart` — hasil publik; dibuka dari link `?v=<topic_id>` tanpa login (di-web via `RootGate`).
- `share_plus`, `qr_flutter`, `mobile_scanner` sudah ditambahkan ke `pubspec.yaml` → jalankan `flutter pub get`.

### B. Live ranking flash + Region Battle + Gamification

- **Live ranking flash**: halaman `live_results_page.dart` kini mengurutkan kandidat secara live dengan animasi bar & badge naik/turun (▴/▾) tiap snapshot WebSocket.
- **Region Battle**: `GET /api/votes/regions/` → `region_leaderboard()` (partisipasi per wilayah). Flutter: `pages/region_battle_page.dart`.
- **Gamifikasi**: field `points`, `vote_streak`, `last_vote_date`, `badges` di `User` (migration `users/0008_user_gamification`). Poin +10 & streak bertambah saat vote (`users/gamification.award_vote`, dipanggil di `votes.views.perform_create`). Badge: `first_vote`, `streak_3/7/30`.
- `GET /api/users/gamification/` → `{me, leaderboard, badges_meta}`. Flutter: `pages/gamification_page.dart`.

> Setelah menambah field, jalankan: `python manage.py makemigrations users votes && python manage.py migrate`.

---

### C. Layer trust/civic — hasil & arsip publik terverifikasi

- `GET /api/votes/public/hub/` (AllowAny) — papan nama: semua periode + topik (evidence_root, total, DPT).
- `GET /api/votes/public/archive/<election_id>/` (AllowAny) — arsip satu periode per-topik (hasil + evidence_root + partisipasi) ditandatangani Ed25519.
- `GET /api/votes/public/recap/` + `POST /api/votes/public/recap/verify/` (AllowAny) — rekap global yang bisa diverifikasi siapa pun tanpa login.
- Flutter: `pages/public_hub_page.dart` (daftar periode/topik → buka `public_results_page`), `pages/public_recap_page.dart` (verifikasi tandatangan). Dibuka tanpa login via link `?hub=1` / `?recap=1` di web (`RootGate`).

---

### D. Batch terakhir: analitik, ekspor CSV, & notifikasi

- **Dashboard analitik** (admin): `GET /api/votes/analytics/` (requirement `manage_votes`) →
  total suara/topik, tren 7 hari, top region, partisipasi per periode. Flutter: `pages/admin_analytics_page.dart`.
- **Ekspor CSV** (admin): `GET /api/votes/export_results/`, `export_votes/`, `export_audit/`
  (StreamingHttpResponse + BOM). Flutter: `pages/export_page.dart` + util `utils/csv_download*` (web/mobile).
- **Notifikasi in-app**: app `notifications` (Notification, Broadcast), `GET /api/notifications/`,
  unread count, mark-read, dan broadcast admin `POST /api/notifications/broadcasts/send/`.
  Flutter: `pages/notifications_page.dart` + lonceng ber-notif-badge di `home_page.dart`.
- **Push FCM (opsional/berat)**: `User.fcm_token` (`users/0009_user_fcm_token`); `POST /api/users/fcm/`
  daftarkan token; `notifications/services.send_push` via FCM HTTP bila `FCM_SERVER_KEY` diset
  (perlu `requests`). Flutter: `services/push_service.dart` (pakai `firebase_messaging`).
  Setup Firebase wajib (google-services.json / GoogleService-Info.plist) baru push aktif.

> Jalankan: `python manage.py makemigrations notifications users && python manage.py migrate` + `flutter pub get`.

---

---

## 7. Troubleshooting

| Masalah                                    | Solusi                                                                              |
| ------------------------------------------ | ----------------------------------------------------------------------------------- |
| `No module named 'django'`               | buang`backend/venv` lama, buat ulang, `pip install -r requirements.txt`         |
| Migration`roles` tak ada                 | pastikan`roles` terdaftar di `INSTALLED_APPS` lalu `python manage.py migrate` |
| 403 saat kelola role/user                  | pastikan role user =`superadmin`/`admin` & punya permission yang dimaksud       |
| `ModuleNotFoundError: cryptography`      | `pip install cryptography` (sudah di `requirements.txt`)                        |
| OTP tak terkirim                           | isi`WA_GATEWAY_TOKEN` di `.env` (tanpa token otomatis mode simulasi/log)        |
| Fingerprint nonaktif di Web                | wajar —`local_auth` hanya Android/iOS                                            |
| WebSocket/ASGI error`apps.votes.routing` | sudah diperbaiki; jalankan dengan`daphne`                                         |
