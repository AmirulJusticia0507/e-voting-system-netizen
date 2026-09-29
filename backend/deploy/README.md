# Deploy e-netizen di Oracle Cloud Always Free

Gratis selamanya, 2 OCPU / 12 GB ARM64. Cukup untuk Django + PostgreSQL.

> **Perhatikan batas 2026.** Oracle **memangkas** jatah Always Free Ampere A1 dari
> 4 OCPU / 24 GB menjadi **2 OCPU / 12 GB** pada 15 Juni 2026, tanpa pengumuman.
> 18 Agustus 2026 instance di atas batas itu dimatikan. Hampir semua panduan di
> internet masih menyebut angka lama. Rujuk
> [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

## Yang sudah diverifikasi

Semua dependensi `requirements.txt` punya jalur ARM64 — **tidak ada kompilasi**
di dalam container:

| Paket | Jalur ARM64 |
|---|---|
| `psycopg-binary` 3.2.13 | 13 wheel aarch64 glibc |
| `cryptography` 43.0.1 | 6 wheel aarch64 glibc |
| `cffi` 1.17.1 | 11 wheel aarch64 glibc |
| `Pillow` | 32 wheel aarch64 glibc |
| `psycopg`, `gunicorn`, `asgiref`, `sqlparse`, `tzdata` | pure-python (`py3-none-any`) |

`psycopg-c` tidak ikut terpasang karena requirements memakai extra `[binary]`,
bukan `[c]`.

---

## Langkah 1 — VM Oracle

1. Daftar di <https://signup.cloud.oracle.com/> (pilih region saat signup).
2. Console → **Compute → Instances → Create instance**.
3. **Image**: Ubuntu 24.04 (atau Oracle Linux 9).
4. **Shape**: `VM.Standard.A1.Flex`, **1 OCPU / 6 GB** dulu — bentuk kecil jauh
   lebih mudah lolos dari *"Out of host capacity"*. Nanti bisa resize ke 2/12.
5. **Networking**: buat VCN, lalu **tambahkan ingress rule TCP 22 dan TCP 8000**
   dari `0.0.0.0/0`. Port 8000 wajib dibuka untuk Lex-DSS.
6. **SSH key**: unggah atau buat baru, download `.pem`.
7. Storage: 200 GB block storage Always Free (shared), default 50 GB sudah cukup.

### Kalau muncul "Out of host capacity"

Bukan soal kuota. Yang perlu dilakukan:

- Ganti availability domain, atau coba lagi beberapa menit kemudian.
- Jangan klik Launch manual berulang — kapasitas muncul dalam burst.
- Region yang ramai (US/Jakarta) paling sering kosong. Tokyo, Hyderabad, dan
  beberapa region Eropa lebih longgar.

---

## Langkah 2 — Jalankan

```bash
ssh -i ~/kunci.pem ubuntu@<IP-VM>

curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

./deploy/provision.sh          # setup awal
```

Script akan clone repo, membuat `.env` dengan secret acak, build image, menjalankan
migrasi, lalu menunggu health check hijau.

Perbarui kode di kemudian hari:

```bash
./deploy/provision.sh --rebuild
```

`--rebuild` aman diulang: volume `pgdata` tidak disentuh, jadi polling dan
suara yang sudah ada tetap utuh.

---

## Langkah 3 — Sambungkan ke Lex-DSS

Ambil `LEX_DSS_HMAC_SECRET` dari `.env` di VM:

```bash
grep LEX_DSS_HMAC_SECRET ~/enetizen/backend/.env
```

Di Railway → service `lex-dss-api` → Variables:

| Key | Value |
|---|---|
| `ENETIZEN_URL` | `http://<IP-VM>:8000` |
| `ENETIZEN_HMAC_SECRET` | nilai yang sama persis |

Lalu deploy ulang `lex-dss-api`. Migrasi `005` (tabel `civic_poll_events` dan
`civic_poll_results`) sudah otomatis jalan lewat `preDeployCommand`.

Verifikasi dari Railway:

```bash
curl -H "Authorization: Bearer <JWT>" https://<lex-dss>/api/v1/integration/sources
# {"name": "enetizen", "configured": true, "missing": 0}
```

---

## Catatan operasional

### Cloudflare Tunnel (opsional, tapi disarankan)

Domain Railway memakai HTTPS. Kalau Anda memakai HTTP ke IP, Lex-DSS harus
bisa menjangkau IP itu — pastikan port 8000 benar-benar terbuka dari internet.
Tunnel menghindari ini:

```bash
docker run -d --name cloudflared --restart unless-stopped \
  cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://enetizen:8000
```

Lalu pakai URL `https://xxx.trycloudflare.com` sebagai `ENETIZEN_URL`.

**Kalau lewat tunnel, wajib nyalakan HTTPS di aplikasi.** Tunnel sudah
meng-terminasi TLS, jadi aktifkan juga proteksinya di `.env`:

```bash
FORCE_HTTPS=1
SECURE_HSTS_SECONDS=31536000
docker compose -f docker-compose.oracle.yml up -d
```

Dengan dua baris itu plus secret ber-entropi tinggi, `manage.py check --deploy`
melaporkan **0 issues**. Tanpa `FORCE_HTTPS`, `manage.py check --deploy`
menolak lima peringatan (W004, W008, W012, W016) — itu wajar untuk deployment
HTTP langsung ke IP, karena mengaktifkannya tanpa TLS akan membuat semua
request gagal.

Healthcheck container memakai HTTP ke `localhost`, jadi **jangan** set
`FORCE_HTTPS=1` tanpa memastikan `curl -fsS` masih lolos — kalau tidak,
container akan restart loop.

### Idempotensi reclaim

Oracle deems instance **idle** kalau selama 7 hari p95 CPU < 20%, network
< 20%, dan memory < 20% (A1). Ketiganya harus true bersamaan.

Aplikasi riset dengan lalu lintas rendah justru punya profil seperti ini. Jaga dengan kerja
yang benar-benar berguna, bukan beban palsu:

- backup `pgdata` harian ke object storage
- health check terjadwal dari luar
- cron ringan (mis. sinkronisasi region)

Simpan salinan provisioning ini **di luar instance** (repo sudah kemana), supaya
kalau instance di-reclaim, pemulihan cukup satu perintah.

### Resource

2 OCPU / 12 GB untuk satu container Django + PostgreSQL. Kalau instance
saat ini 1 OCPU / 6 GB, naikkan setelah stabil:

```bash
# di console Oracle, lalu:
docker compose -f docker-compose.oracle.yml up -d
```

---

## Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `Signature Lex-DSS tidak valid` | `ENETIZEN_HMAC_SECRET` ≠ `LEX_DSS_HMAC_SECRET` | Samakan byte per byte |
| `RuntimeError: Konfigurasi database kosong` | `DB_NAME` kosong di `.env` | Isi ulang `.env`, restart |
| `RuntimeError: VOTE_ENCRYPTION_KEY minimal 32 karakter` | Secret terlalu pendek | `openssl rand -base64 48` |
| Health check `starting` terus | Migrasi gagal | `docker compose -f docker-compose.oracle.yml logs enetizen` |
| WebSocket tidak konek | Jalan dengan WSGI | Pakai `daphne` (sudah jadi ENTRYPOINT image) |
