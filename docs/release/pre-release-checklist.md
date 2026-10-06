# Pre-release checklist — বিলবাক্স MVP

Use on a physical Android device (API 26+) before Play Console upload.

## Automated

- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all green
- [ ] `flutter build apk --release` succeeds
- [ ] `flutter build appbundle --release` succeeds (for Play Store)

## Device QA

- [ ] Launcher name shows **বিলবাক্স**
- [ ] Add / edit / soft-delete bill accounts
- [ ] Soft-delete does **not** wipe payment history rows
- [ ] Home sorts overdue / due soon correctly
- [ ] **পে করুন** opens portal / bKash (or shows fallback)
- [ ] Log payment sheet saves amount; history updates
- [ ] Analytics bar chart shows months with payments
- [ ] Airplane mode: add bill + log payment still works
- [ ] Settings → test reminder fires (~2 minutes)
- [ ] Bill with `typicalDueDay` schedules monthly reminder (09:00 Asia/Dhaka, 2 days before)

## Firebase (after `flutterfire configure`)

- [ ] Phone OTP with `+880` number
- [ ] Firestore sync: add on device A → login on device B
- [ ] Remote Config URL override picked up (or defaults work offline)
- [ ] `firebase deploy --only firestore:rules`

## Signing

- [ ] `android/key.properties` created from `key.properties.example`
- [ ] Upload keystore backed up offline
- [ ] AAB uploaded to Play Console internal testing track
