# Firebase setup (Phase 0.4)

Package ID: `com.nextgenai.billbax`

`lib/firebase_options.dart` currently contains **placeholders**. Firebase is skipped at
startup until you configure a real project (`DefaultFirebaseOptions.isConfigured == false`).

## One-time setup

1. Create a Firebase project (Console name can be anything; e.g. `bilbax-app`).
2. Enable:
   - Authentication → Phone
   - Firestore Database (start in test mode for MVP)
   - Remote Config
   - Cloud Messaging
3. From the project root, run:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure \
  --project=YOUR_FIREBASE_PROJECT_ID \
  --platforms=android,ios \
  --android-package-name=com.nextgenai.billbax \
  --ios-bundle-id=com.nextgenai.billbax
```

4. Open `lib/firebase_options.dart` and set:

```dart
static bool get isConfigured => true;
```

(or remove the gate in `main.dart` once real options are generated).

5. Confirm `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist` exist (FlutterFire adds these).
