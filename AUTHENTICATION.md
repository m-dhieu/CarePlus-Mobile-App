# Care+ Authentication — backend reference

Backend/data layer for the Authentication ticket. There is **no REST API** here —
this is a Flutter app talking directly to Firebase (Auth + Firestore). Frontend
screens call these methods and watch these providers directly; there's nothing
to hit with Postman.

Owns: `lib/features/auth/` (`auth_repository.dart`, `auth_providers.dart`,
`app_user.dart`, `validators.dart`, `google_sign_in_config.dart`).

## Setup required before this works

1. `main.dart` must wrap the app in `ProviderScope` (already done) and call
   `Firebase.initializeApp(...)` before `runApp` (already done).
2. Firebase Console (project `careplusplus-b8166`): **Email/Password** and
   **Google** sign-in providers must be enabled under Authentication → Sign-in
   method, and a Firestore database + `firestore.rules` (repo root) must be
   deployed.
3. `lib/features/auth/google_sign_in_config.dart` — `googleWebClientId` must be
   set to the real Web client ID from the Google provider setup (currently a
   placeholder). Only needed for the Google Sign-In button to work.

## Two login methods

1. **Email + Password**, with mandatory email verification before a user is
   considered fully signed in.
2. **Google Sign-In** — also doubles as instant registration for new users
   (standard "Continue with Google" UX); Google-verified emails skip the
   verification step automatically.

## Providers (`auth_providers.dart`)

Watch these with Riverpod; don't call `CareAuthRepository` methods that only
read state directly in build methods — use the providers so the UI reacts to
changes.

| Provider | Type | What it gives you |
|---|---|---|
| `authRepositoryProvider` | `Provider<CareAuthRepository>` | The repository instance — use `ref.read(authRepositoryProvider)` to call action methods (register, login, etc). |
| `authStateProvider` | `StreamProvider<User?>` | The current Firebase `User`, or `null` if signed out. Re-emits on sign-in/out **and** after `reloadUser()` (so you can detect `user.emailVerified` flipping true). This is what should drive your top-level "which screen to show" logic. |
| `currentAppUserProvider` | `StreamProvider<AppUser?>` | The signed-in user's Firestore profile (`users/{uid}`), or `null` if signed out / doc missing. |

Typical routing logic for whoever builds the root widget:
```dart
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) {
    if (user == null) return const LoginScreen();
    if (!user.emailVerified) return const EmailVerificationScreen();
    return const HomeScreen();
  },
  loading: () => const LoadingScreen(),
  error: (e, _) => ErrorScreen(e),
);
```

## `CareAuthRepository` methods (`auth_repository.dart`)

Call these via `ref.read(authRepositoryProvider).methodName(...)`. All are
`async` and throw `FirebaseAuthException` on failure — catch it and pass to
`mapAuthError()` for a user-facing message.

| Method | Signature | Notes |
|---|---|---|
| Register | `Future<void> registerWithEmailPassword({required String email, required String password, required String fullName, String phone = ''})` | Creates the Firebase account, sets display name, sends the verification email, writes the `users/{uid}` profile doc. `phone` is optional. |
| Login | `Future<void> loginWithEmailPassword({required String email, required String password})` | Signs in, bumps `lastLogin` on the profile doc. |
| Google sign-in | `Future<UserCredential> signInWithGoogle()` | Handles the whole OAuth flow. Auto-creates the `users/{uid}` profile on first use, otherwise bumps `lastLogin`. Throws a plain `StateError` (not `FirebaseAuthException`) if the platform doesn't support it — check for both. |
| Resend verification | `Future<void> resendVerificationEmail()` | No-op if no user is signed in. |
| Refresh auth state | `Future<void> reloadUser()` | Call after the user claims to have clicked the verification link, then check `authStateProvider`'s `user.emailVerified` again. |
| Forgot password | `Future<void> resetPasswordEmail(String email)` | Sends Firebase's built-in reset email. One call, no extra screens needed on our side. |
| Logout | `Future<void> signOut()` | — |
| Profile exists? | `Future<bool> hasUserProfile(String uid)` | Used internally by Google sign-in; exposed in case a screen needs it. |
| Watch profile | `Stream<AppUser?> watchUser(String uid)` | Backs `currentAppUserProvider` — you probably want the provider instead of calling this directly. |
| Error mapping | `String mapAuthError(FirebaseAuthException error)` | Turns Firebase error codes into user-facing strings (e.g. `wrong-password` → "Incorrect email or password."). Always run caught exceptions through this before showing them. |

## `AppUser` model (`app_user.dart`)

Mirrors the Firestore `users/{uid}` doc:

```dart
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;   // '' if not provided
  final String role;    // 'patient' by default
  final String status;  // 'active' by default
}
```

## Validators (`validators.dart`)

Pure functions, no Firebase calls — safe to use directly as `TextFormField`
validators: `validateEmail`, `validatePassword`, `validateFullName`. Each
returns `null` when valid, or an error string to display.

## Testing without any UI

`test/auth_repository_test.dart` exercises every repository method against
`firebase_auth_mocks` (fake Auth) and a small hand-rolled Firestore fake
(`test/support/fake_users_firestore.dart`) — no real network calls, no UI.
Run with `flutter test`. This is the closest equivalent to hitting the "API"
directly for this stack, and a good template for adding cases as the frontend
surfaces edge cases.
