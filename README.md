# Care+

Care+ is an offline-first mobile healthcare management application built with Flutter, Riverpod, a local Drift (SQLite) database, and Firebase. It lets a patient keep a personal health profile, track medications and reminders, log health metrics and journal entries, store medical documents, manage caregivers, and generate time-limited emergency-access codes and record-sharing tokens, all usable without a live internet connection, syncing to the cloud once one is available.

Developed by Group 3 

  *![SignUp.png](SignUp.png)* 
  
  *![MyProfile.png](MyProfile.png)* 

  *![Home.png](Home.png)*

## Features

- **Authentication** - email/password, Google, and Apple sign-in via Firebase Authentication, with email verification on registration.
- **Profile** - blood type, allergies, height/weight, HbA1c, blood pressure, and emergency contact.
- **Medications** - add medications and request refills.
- **Reminders** - time- and weekday-based medication reminders.
- **Health Metrics** - log and view trends (HbA1c, blood pressure, weight, etc.).
- **Journal** - dated entries for visits, labs, prescriptions, and procedures.
- **Documents** - store medical document records (OCR text extraction is currently a mock pending a real recognition engine - see Known Limitations below).
- **Caregivers** - add caregivers with a role-based access level.
- **Emergency Access** - generate a short-lived emergency code with a defined scope.
- **Record Sharing** - generate a time-limited share token for a doctor.
- **Offline-first** - every action is written to a local Drift database first and queued for background sync to Cloud Firestore once connectivity returns.

## Tech Stack

| Layer | Technology |
|---|---|
| UI / Framework | Flutter (Dart ^3.11.5) - Android, iOS, and Web |
| State management | Riverpod (`flutter_riverpod`, `Notifier`/`AsyncNotifier` API) |
| Local database | Drift (SQLite), via `drift_flutter` |
| Backend | Firebase Authentication, Cloud Firestore |
| Connectivity | `connectivity_plus` |
| Local preferences | `shared_preferences` |

## Project Structure

```
lib/
├── constants/        # Static app constants (e.g. journal categories)
├── data/             # Data-source abstractions (legacy — see Known Limitations)
├── database/         # Drift schema, tables, and row-to-model mappers
├── features/auth/    # Auth-specific models, providers, repository, validators
├── models/           # Core domain models (Medication, Reminder, JournalEntry, ...)
├── providers/         # Riverpod providers/notifiers — providers.dart is the live one
├── repositories/       # CareRepository (Drift-backed) plus per-entity repositories
├── screens/            # App screens (auth, onboarding, home, meds, journal, ...)
├── services/           # AuthService, error mapping, platform support checks
├── sync/               # Outbox queue + sync engine (Drift <-> Firestore)
├── widgets/            # Shared/reusable widgets
├── firebase_options.dart
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (`^3.11.5` or compatible) — [install guide](https://docs.flutter.dev/get-started/install)
- A configured Firebase project with **Authentication** (Email/Password, Google, Apple providers enabled) and **Cloud Firestore** turned on
- Android Studio / Xcode for platform builds, or a physical Android/iOS device

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/m-dhieu/CarePlus-Mobile-App.git
   cd CarePlus-Mobile-App
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Firebase is already configured for this project via `lib/firebase_options.dart` and `firebase.json` (generated with the FlutterFire CLI, project `careplusplus-b8166`). To point the app at your own Firebase project instead, run:
   ```bash
   flutterfire configure
   ```
4. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```
5. Build a release APK:
   ```bash
   flutter build apk --release
   ```

### Running Tests
```bash
flutter test
```
The test suite (`test/`) covers widget/integration flows (`app_flow_integration_test.dart`, `app_test.dart`), authentication (`auth_repository_test.dart`, `auth_validators_test.dart`), and offline-first sync behavior (`offline_first_test.dart`) against an in-memory Drift database.

### Code Quality
```bash
flutter analyze
dart format .
```

## Firebase Security Rules

Firestore data is scoped per-user under `users/{uid}` and its subcollections (`medications`, `reminders`, `journal_entries`, `documents`, `caregivers`, `profile`, `metric_points`, `share_tokens`, `emergency_access`). Access should be restricted so a user can only read/write documents under their own `uid`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```
More information are in the docs folder

## Known Limitations

- Document OCR is currently simulated (returns fixed sample text) rather than performing real text recognition.
- Firestore security rules are configured in the Firebase Console and not yet committed as a `firestore.rules` file in this repository.
- Record sharing uses a text-based share token rather than the QR-code exchange from the original Figma prototype.
- The password-reset screen exists but is not yet linked from the login flow.
- Only onboarding-completion is currently persisted via `SharedPreferences`.

See `AUTHENTICATION.md` for authentication-specific setup and provider details.

## License
This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
