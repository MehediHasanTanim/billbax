# বিলবাক্স (BilBax)

Utility bill tracker for Bangladesh — Flutter, offline-first, Android-first.

**Package:** `com.nextgenai.billbax`

## Phase 0 status

- [x] Flutter project created (android / ios / macos)
- [x] Feature-first `lib/` folder structure
- [x] Riverpod + go_router + sqflite wired
- [x] Dependencies in `pubspec.yaml`
- [ ] Firebase connected via FlutterFire (see [docs/setup/firebase-setup.md](docs/setup/firebase-setup.md))

## Run

```bash
flutter pub get
flutter run                 # pick a device
flutter run -d macos        # desktop smoke test
flutter test
```

## Docs

| Doc | Path |
|---|---|
| Feature spec | `docs/feature/utility-bill-aggregator-mvp-spec_1.md` |
| Technical design | `docs/design/bilbax-technical-design.md` |
| Implementation plan | `docs/plan/bilbax-implementation-plan.md` |
| Firebase setup | `docs/setup/firebase-setup.md` |

## Next

**Phase 1 — Data layer:** full `BillAccount` / `PaymentRecord` models, repositories, unit tests.
