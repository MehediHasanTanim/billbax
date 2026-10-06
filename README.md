# বিলবাক্স (BilBax)

Utility bill tracker for Bangladesh — Flutter, offline-first, Android-first.

**Package:** `com.nextgenai.billbax`  
**Version:** `1.0.0+1`

## Progress

- [x] **Phase 0** — Flutter project, folder structure, Riverpod, deps
- [x] **Phase 1** — SQLite schema, models, repositories, unit tests
- [x] **Phase 2** — Bill management UI (home, add/edit/delete)
- [x] **Phase 3** — Payment redirect + manual payment log
- [x] **Phase 4** — Payment history & analytics charts
- [x] **Phase 5** — Phone OTP auth + Firestore sync (needs Firebase config)
- [x] **Phase 6** — Local due-date reminders + FCM hooks
- [x] **Phase 7** — Polish, tests, release build config
- [ ] Firebase via FlutterFire (see [docs/setup/firebase-setup.md](docs/setup/firebase-setup.md))

## Run

```bash
flutter pub get
flutter run                 # pick a device
flutter test
flutter analyze
```

## Release builds

```bash
# Debug-signed release APK (no key.properties required)
flutter build apk --release

# Play Store bundle (recommended)
flutter build appbundle --release

# Outputs
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

Upload signing: copy `android/key.properties.example` → `android/key.properties` and point at your keystore.

## Docs

| Doc | Path |
|---|---|
| Feature spec | `docs/feature/utility-bill-aggregator-mvp-spec_1.md` |
| Technical design | `docs/design/bilbax-technical-design.md` |
| Implementation plan | `docs/plan/bilbax-implementation-plan.md` |
| Firebase setup | `docs/setup/firebase-setup.md` |
| Pre-release checklist | `docs/release/pre-release-checklist.md` |
| Firestore rules | `firestore.rules` |

### Reminder QA
Settings → **টেস্ট রিমাইন্ডার (২ মিনিট)** or add a bill with a due day; reminders fire 2 days before at 09:00 Asia/Dhaka.
