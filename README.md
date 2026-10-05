# বিলবাক্স (BilBax)

Utility bill tracker for Bangladesh — Flutter, offline-first, Android-first.

**Package:** `com.nextgenai.billbax`

## Progress

- [x] **Phase 0** — Flutter project, folder structure, Riverpod, deps
- [x] **Phase 1** — SQLite schema, models, repositories, unit tests
- [x] **Phase 2** — Bill management UI (home, add/edit/delete)
- [ ] Firebase via FlutterFire (see [docs/setup/firebase-setup.md](docs/setup/firebase-setup.md))
- [ ] **Phase 3** — Payment redirect system

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

**Phase 3 — Payment redirect:** Pay Now → url_launcher → log payment sheet.
