# E-Voting System — Flutter App

Aplikasi frontend e-voting berbasis Flutter (mendukung **Web**, **Android**, **iOS**).

## Fitur

- Login dengan **nomor HP atau username** + JWT, dan **login khusus admin**.
- Login biometrik (**fingerprint**) & **PIN** via `local_auth`.
- Signup netizen (dengan upload foto profil, opsi biometrik/PIN).
- Voting per topik, lihat hasil, komentar (like/dislike).
- Manajemen admin: User, Topik, Kandidat, Votes, Komentar, dan **Role & Permission (RBAC)**.
- Menu utama dibangun otomatis berdasarkan `permission_codes` user.

## Setup

```bash
flutter pub get
flutter run -d chrome            # Web
flutter run -d <device-id>       # Android/iOS
```

`baseUrl` API dikelola otomatis di `lib/services/api_service.dart`
(emulator Android → `10.0.2.2`, lain-lain → `localhost`, samakan dengan server Django).

## Struktur

```
lib/
├── main.dart            AuthGate + routes + routing biometrik
├── services/api_service.dart   HTTP + token (per-role) + upload
├── models/              vote, candidate, topic, user, comment
├── pages/               home, login, pin_login, signup, voting,
│                        results, topics, profile, admin_manage,
│                        roles_manage (RBAC) [BARU]
└── widgets/             custom_button, custom_textfield
```

Setup lengkap backend + database + role/permission ada di [`SETUP.md`](../SETUP.md) (root repo).