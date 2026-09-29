# Tiga Skenario Alternatif Civic Engagement Pipeline

Dokumen ini merupakan alternatif implementasi dari arsitektur pada
`lex-dss/docs/CIVIC_ENGAGEMENT_PIPELINE.md`. Ketiga skenario memakai fondasi
Lex Integrity, Lex-DSS, dan E-Netizen Voting, tetapi memiliki tingkat
otomatisasi, risiko, biaya, dan kebutuhan kerja sama institusional yang
berbeda.

## Tujuan Bersama

Semua skenario bertujuan untuk:

- mengubah dokumen atau pembahasan kebijakan yang panjang menjadi ringkasan yang dapat dipahami warga;
- memperlihatkan sumber, kutipan, dan konteks hukum di balik setiap isu;
- menyediakan polling konsultatif dengan pilihan yang netral dan dapat diaudit;
- mengumpulkan suara serta komentar tanpa mengklaimnya sebagai keputusan hukum yang mengikat;
- mengirimkan hasil agregat kembali ke Lex-DSS sebagai masukan partisipasi publik.

## Prinsip Dasar

1. Hasil AI selalu diperlakukan sebagai draf sampai diperiksa manusia.
2. Setiap klaim harus dapat ditelusuri ke dokumen, video, dan timestamp sumber.
3. Polling harus membedakan fakta, analisis hukum, prediksi dampak, dan opini publik.
4. Hasil disebut `jajak pendapat` atau `konsultasi publik digital`, bukan pemungutan suara resmi.
5. Data identitas dan pilihan warga tidak boleh dipublikasikan atau dikirim kembali ke Lex-DSS.
6. Lex-DSS hanya menerima statistik agregat dan komentar yang telah dianonimkan.

---

## Skenario A — Curated Civic Polling

### Ringkasan

Skenario paling sederhana dan aman. Admin memasukkan URL video, transkrip,
risalah rapat, atau dokumen kebijakan secara manual. Lex Integrity dan Lex-DSS
menghasilkan draf ringkasan serta polling. Editor manusia memeriksa seluruh
materi sebelum dipublikasikan ke E-Netizen.

### Alur

```text
Dokumen/video resmi
        ↓
Admin memilih potongan atau mengunggah transkrip
        ↓
Lex Integrity membuat audit hukum dengan sumber
        ↓
Lex-DSS membuat draf opsi dan pertanyaan polling
        ↓
Editor memeriksa fakta, bahasa, dan keseimbangan opsi
        ↓
Admin menerbitkan polling di E-Netizen
        ↓
Hasil agregat dikirim kembali ke Lex-DSS
```

### Identitas Pemilih

- Login nomor telepon dan OTP.
- DPT internal opsional untuk polling terbatas.
- Biometrik perangkat hanya sebagai pengaman lokal.
- Tidak menggunakan NIK atau face recognition server-side.

### Perubahan Teknis Minimum

- Tambahkan metadata sumber pada `Topic` atau model baru `CivicPoll`.
- Buat model `PollOption`, atau jadikan `Candidate` kompatibel dengan opsi tanpa foto.
- Tambahkan status `DRAFT`, `IN_REVIEW`, `PUBLISHED`, dan `CLOSED`.
- Buat endpoint internal untuk menerima draf payload dari Lex-DSS.
- Buat halaman review dan approval untuk admin.
- Tampilkan sumber, timestamp, disclaimer, dan tanggal pembaruan di aplikasi Flutter.
- Tambahkan endpoint hasil agregat tanpa identitas pemilih.

### Kelebihan

- Dapat dibangun dengan codebase yang sudah ada.
- Tidak bergantung pada API pemerintah atau Dukcapil.
- Risiko salah publikasi lebih rendah karena ada review manusia.
- Cocok untuk demo, riset, komunitas, dan pilot daerah.

### Kekurangan

- Belum real-time.
- Membutuhkan editor atau moderator.
- Jumlah polling yang dapat diproses bergantung pada kapasitas tim.

### Estimasi

- Kesiapan fondasi: **70–80%**.
- Kompleksitas implementasi: **rendah–menengah**.
- Rekomendasi penggunaan: **MVP pertama**.

---

## Skenario B — Moderated Near-Real-Time Pipeline

### Ringkasan

Sistem memantau video atau live stream terpilih, memproses audio dalam chunk,
dan menghasilkan kandidat isu secara berkala. Polling tidak langsung tayang;
moderator menerima antrean isu dan menyetujui atau mengeditnya sebelum
publikasi.

### Alur

```text
Video atau live stream kanal terpilih
        ↓
STT menghasilkan transkrip bertimestamp
        ↓
Topic segmentation mengelompokkan pembahasan
        ↓
Lex Integrity membuat audit dan kutipan sumber
        ↓
Lex-DSS menghasilkan draf micro-poll
        ↓
Moderator menerima alert dan melakukan review
        ↓
Polling diterbitkan 5–30 menit setelah pembahasan
        ↓
Hasil agregat dan sentimen komentar kembali ke Lex-DSS
```

### Identitas Pemilih

- OTP dan akun terverifikasi.
- DPT internal atau pembatasan wilayah untuk polling tertentu.
- Device binding dan rate limiting untuk mengurangi akun ganda.
- Face matching/NIK tetap tidak digunakan tanpa mitra identitas resmi.

### Komponen Tambahan

- Worker ingestion dan antrean pekerjaan, misalnya Celery/Redis.
- Penyimpanan sesi video, chunk audio, transkrip, dan timestamp.
- Speaker diarization dan topic segmentation.
- Deduplication agar satu isu tidak menghasilkan banyak polling serupa.
- Dashboard moderation dengan video preview dan kutipan sumber.
- Mekanisme membatalkan atau mengoreksi polling yang salah.
- Observability untuk latency, kegagalan STT, dan biaya pemrosesan.

### Kelebihan

- Isu dapat dipublikasikan ketika pembahasan masih relevan.
- Skala pemrosesan lebih besar daripada skenario manual.
- Tetap memiliki pagar pengaman melalui moderator.

### Kekurangan

- STT rapat pemerintahan rawan salah nama, angka, istilah, dan atribusi pembicara.
- Biaya komputasi dan operasional lebih tinggi.
- Moderator harus tersedia selama sesi berlangsung.
- Pertanyaan cepat berisiko kehilangan konteks pembahasan.

### Estimasi

- Kesiapan fondasi: **40–50%**.
- Kompleksitas implementasi: **menengah–tinggi**.
- Rekomendasi penggunaan: **setelah Skenario A stabil**.

---

## Skenario C — Institutional Public Consultation

### Ringkasan

Pipeline dijalankan bersama DPRD, Pemda, atau lembaga publik. Agenda,
dokumen, wilayah peserta, serta jadwal konsultasi berasal dari instansi mitra.
Hasil tetap tidak otomatis mengikat, tetapi dapat menjadi bagian dari proses
konsultasi publik yang diakui oleh instansi tersebut.

### Alur

```text
Agenda dan dokumen resmi dari instansi mitra
        ↓
Ingestion melalui API atau portal kerja sama
        ↓
Audit Lex Integrity dan pemodelan Lex-DSS
        ↓
Review bersama editor hukum dan PIC instansi
        ↓
Publikasi konsultasi dengan jadwal dan wilayah resmi
        ↓
Verifikasi peserta melalui penyedia identitas yang sah
        ↓
Voting, komentar, audit, dan rekap bertanda tangan
        ↓
Laporan konsultasi diserahkan kepada instansi dan dipublikasikan
```

### Identitas Pemilih

- Identity provider resmi atau penyedia verifikasi yang memiliki dasar hukum.
- NIK tidak disimpan langsung apabila tokenisasi atau verifiable credential tersedia.
- Pemisahan penyimpanan identitas dan surat suara.
- Kebijakan retensi, penghapusan, persetujuan, serta mekanisme keberatan pengguna.

### Komponen Tambahan

- Perjanjian kerja sama dan penetapan pengendali/prosesor data.
- API gateway, mTLS atau OAuth2 client credentials, IP allowlist, dan rotasi kunci.
- Independent audit dan threat modelling.
- Secret-ballot architecture yang memisahkan identitas dari pilihan.
- Rekap bertanda tangan, arsip publik, dan prosedur koreksi formal.
- Accessibility, service-level agreement, disaster recovery, dan incident response.
- Tata kelola pertanyaan, masa konsultasi, representasi wilayah, dan metode sampling.

### Kelebihan

- Legitimasi dan kualitas data peserta paling tinggi.
- Bisa menjadi kanal konsultasi publik yang benar-benar dipakai instansi.
- Dokumen sumber serta tindak lanjut lebih mudah dipertanggungjawabkan.

### Kekurangan

- Sangat bergantung pada kerja sama, regulasi, audit, dan anggaran lembaga.
- Waktu implementasi panjang.
- Risiko hukum dan keamanan data paling tinggi.
- Codebase saat ini belum memenuhi standar pemungutan suara resmi.

### Estimasi

- Kesiapan fondasi: **20–30%**.
- Kompleksitas implementasi: **sangat tinggi**.
- Rekomendasi penggunaan: **target jangka panjang, bukan MVP**.

---

## Perbandingan Skenario

| Parameter | Skenario A | Skenario B | Skenario C |
|---|---|---|---|
| Input | Dokumen/transkrip manual | Stream dan transkrip otomatis | Data/API resmi mitra |
| Kecepatan publikasi | Jam–hari | 5–30 menit setelah isu | Sesuai jadwal resmi |
| Review manusia | Wajib | Wajib dan cepat | Wajib bersama instansi |
| Verifikasi pemilih | OTP/DPT internal | OTP, DPT, device guard | Identity provider resmi |
| Status hasil | Polling konsultatif | Polling konsultatif cepat | Konsultasi yang diakui mitra |
| Ketergantungan eksternal | Rendah | Sedang | Sangat tinggi |
| Risiko hukum | Rendah–menengah | Menengah–tinggi | Tinggi |
| Biaya operasional | Rendah | Menengah–tinggi | Tinggi |
| Cocok untuk kondisi sekarang | Sangat cocok | Belum | Belum |

## Kontrak Payload Minimum

Semua skenario sebaiknya memakai envelope yang dapat dilacak dan diverifikasi.

```json
{
  "schema_version": "1.0",
  "event_id": "01J-CIVIC-UNIQUE-ID",
  "generated_at": "2026-09-29T10:00:00+07:00",
  "source": {
    "type": "youtube_video",
    "url": "https://www.youtube.com/watch?v=example",
    "publisher": "DPRD Kabupaten Contoh",
    "title": "Rapat Pembahasan Raperda Retribusi",
    "segment_start_seconds": 4460,
    "segment_end_seconds": 6310,
    "content_hash": "sha256:..."
  },
  "legal_audit": {
    "summary": "Ringkasan isu yang telah diperiksa.",
    "jurisdiction": "Kabupaten Contoh",
    "references": [
      {
        "title": "UU Nomor 1 Tahun 2022",
        "article": "Pasal ...",
        "source_url": "https://...",
        "quote": "Kutipan singkat yang mendukung analisis"
      }
    ],
    "risks": [],
    "limitations": [],
    "confidence": 0.78
  },
  "poll_draft": {
    "question": "Bagaimana pendapat Anda mengenai usulan tersebut?",
    "options": [
      {"code": "A", "label": "Setuju"},
      {"code": "B", "label": "Setuju dengan perubahan"},
      {"code": "C", "label": "Tidak setuju"}
    ],
    "opens_at": "2026-09-29T12:00:00+07:00",
    "closes_at": "2026-10-06T12:00:00+07:00",
    "region_code": "ID-YO"
  },
  "review": {
    "status": "DRAFT",
    "requires_human_approval": true
  }
}
```

## Rekomendasi Keputusan

Mulai dari **Skenario A — Curated Civic Polling**. Skenario ini memberikan
nilai produk paling cepat dengan risiko paling terkendali dan sesuai dengan
kemampuan codebase saat ini.

Gunakan kriteria berikut sebelum berpindah ke Skenario B:

- minimal 20 polling telah diproses melalui review manusia;
- kesalahan kutipan sumber dan pilihan polling telah terukur;
- audit trail serta idempotency integrasi sudah stabil;
- tidak ada kebocoran identitas atau pilihan pemilih;
- moderator memiliki SOP koreksi dan pembatalan polling;
- biaya pemrosesan per sesi telah diketahui.

Skenario C hanya dimulai setelah ada mitra institusional, dasar pemrosesan data,
penilaian dampak perlindungan data, audit keamanan independen, serta desain
pemisahan identitas dan surat suara.

## Tahap Implementasi yang Disarankan

### Tahap 1 — Civic Poll Core

- Model `CivicPollSource`, `CivicPoll`, `PollOption`, dan `PollReview`.
- Endpoint import draf dari Lex-DSS.
- Review dan approval admin.
- Tampilan sumber dan disclaimer pada Flutter.
- Hasil agregat anonim.

### Tahap 2 — Trusted Integration

- HMAC signature atau OAuth2 client credentials.
- Idempotency key dan schema validation.
- Audit event untuk import, review, publish, correction, dan close.
- Feedback agregat dari E-Netizen ke Lex-DSS.

### Tahap 3 — Assisted Ingestion

- Upload audio/video atau transkrip.
- STT batch dan timestamp.
- Topic segmentation serta antrean moderator.
- Pengukuran kualitas transkrip dan audit hukum.

### Tahap 4 — Near-Real-Time

- Chunking live stream.
- Deduplication isu.
- Alert moderator dan publikasi terjadwal.
- Monitoring latency, biaya, dan error rate.

### Tahap 5 — Institutional Readiness

- Integrasi identitas resmi.
- Pemisahan identitas dan pilihan.
- Audit independen, DPIA, disaster recovery, dan SLA.
- Tata kelola konsultasi bersama lembaga mitra.

