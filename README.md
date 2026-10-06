# বিলবাক্স (BilBax)

Utility bill tracker for Bangladesh — Flutter, offline-first, Android-first.

**Package:** `com.nextgenai.billbax`

## Progress

- [x] **Phase 0** — Flutter project, folder structure, Riverpod, deps
- [x] **Phase 1** — SQLite schema, models, repositories, unit tests
- [x] **Phase 2** — Bill management UI (home, add/edit/delete)
- [x] **Phase 3** — Payment redirect + manual payment log
- [x] **Phase 4** — Payment history & analytics charts
- [x] **Phase 5** — Phone OTP auth + Firestore sync (needs Firebase config)
- [x] **Phase 6** — Local due-date reminders + FCM hooks
- [ ] Firebase via FlutterFire (see [docs/setup/firebase-setup.md](docs/setup/firebase-setup.md))
- [ ] **Phase 7** — Polish, testing, release

## Run

```bash
flutter pub get
flutter run                 # pick a device
flutter run -d macos        # desktop smoke test
flutter test
flutter test test/repositories/
```

## Docs

| Doc | Path |
|---|---|
| Feature spec | `docs/feature/utility-bill-aggregator-mvp-spec_1.md` |
| Technical design | `docs/design/bilbax-technical-design.md` |
| Implementation plan | `docs/plan/bilbax-implementation-plan.md` |
| Firebase setup | `docs/setup/firebase-setup.md` |

## Next

**Phase 7 — Polish & release:** more tests, release APK/AAB.

### Reminder QA
Settings → **টেস্ট রিমাইন্ডার (২ মিনিট)** or add a bill with a due day; reminders fire 2 days before at 09:00 Asia/Dhaka.
