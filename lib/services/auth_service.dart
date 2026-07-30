import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_errors.dart';

const kGoogleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

typedef CredentialFactory = Future<AuthCredential> Function();
typedef CredentialSigner = Future<UserCredential> Function(AuthCredential);

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    CredentialFactory? googleCredentialFactory,
    CredentialFactory? appleCredentialFactory,
    CredentialSigner? credentialSigner,
    Future<bool> Function()? appleAvailable,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _googleCredentialFactory = googleCredentialFactory,
       _appleCredentialFactory = appleCredentialFactory,
       _credentialSigner = credentialSigner,
       _appleAvailable = appleAvailable;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialFactory? _googleCredentialFactory;
  final CredentialFactory? _appleCredentialFactory;
  final CredentialSigner? _credentialSigner;
  final Future<bool> Function()? _appleAvailable;

  bool _googleReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _signUpAndBootstrapProfile(
      email: email,
      password: password,
    );
    final trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmedName);
      await credential.user?.reload();
    }
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  Future<UserCredential> signInWithGoogle() async {
    if (_googleCredentialFactory != null) {
      return _signInWithCredential(await _googleCredentialFactory());
    }

    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    try {
      if (kIsWeb) {
        // Firebase handles the OAuth popup on web — no google_sign_in plugin.
        return await _auth.signInWithPopup(provider);
      }

      // Prefer the native Firebase provider flow (Credential Manager / ASWeb).
      // Falls back to google_sign_in when the provider flow is unavailable.
      try {
        return await _auth.signInWithProvider(provider);
      } on FirebaseAuthException catch (e) {
        if (_isCancelCode(e.code)) throw AuthCancelledException();
        if (!_shouldFallbackToGoogleSignIn(e)) rethrow;
      } on UnimplementedError {
        // Some platforms still need the google_sign_in plugin.
      }

      return _signInWithCredential(await _obtainGoogleCredential());
    } on FirebaseAuthException catch (e) {
      if (_isCancelCode(e.code)) throw AuthCancelledException();
      rethrow;
    }
  }

  Future<UserCredential> signInWithApple() async {
    if (_appleCredentialFactory != null) {
      return _signInWithCredential(await _appleCredentialFactory());
    }

    final provider = AppleAuthProvider();

    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(provider);
      }

      // Native Apple flow via Firebase (works on iOS; Android needs Service ID).
      try {
        return await _auth.signInWithProvider(provider);
      } on FirebaseAuthException catch (e) {
        if (_isCancelCode(e.code)) throw AuthCancelledException();
        // Fall back to sign_in_with_apple plugin when configured.
      } on UnimplementedError {
        // Continue to plugin fallback.
      }

      final available = _appleAvailable != null
          ? await _appleAvailable()
          : await _isAppleAvailable();
      if (!available) {
        throw AuthUnavailableException('apple');
      }
      return _signInWithCredential(await _obtainAppleCredential());
    } on FirebaseAuthException catch (e) {
      if (_isCancelCode(e.code)) throw AuthCancelledException();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google may not have been initialized / used.
    }
    await _auth.signOut();
  }

  Future<UserCredential> _signUpAndBootstrapProfile({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> _signInWithCredential(AuthCredential credential) {
    final signer = _credentialSigner;
    if (signer != null) {
      return signer(credential);
    }
    return _auth.signInWithCredential(credential);
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    await _googleSignIn.initialize(
      serverClientId: kGoogleServerClientId.isEmpty
          ? null
          : kGoogleServerClientId,
    );
    _googleReady = true;
  }

  Future<AuthCredential> _obtainGoogleCredential() async {
    await _ensureGoogleInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw AuthUnavailableException(
        'google',
        'This platform requires a platform-specific Google button',
      );
    }
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthUnavailableException(
          'google',
          'Missing ID token — set GOOGLE_SERVER_CLIENT_ID dart-define '
              '(Firebase Console → Authentication → Google → Web client ID)',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException();
      }
      rethrow;
    }
  }

  Future<AuthCredential> _obtainAppleCredential() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final idToken = apple.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthUnavailableException('apple', 'Missing Apple identity token');
      }
      return OAuthProvider(
        'apple.com',
      ).credential(idToken: idToken, rawNonce: rawNonce);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthCancelledException();
      }
      rethrow;
    }
  }

  Future<bool> _isAppleAvailable() async {
    if (kIsWeb) return true; // Firebase popup handles web Apple when enabled.
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return SignInWithApple.isAvailable();
      default:
        return false;
    }
  }

  static bool _isCancelCode(String code) {
    return code == 'popup-closed-by-user' ||
        code == 'cancelled-popup-request' ||
        code == 'web-context-canceled' ||
        code == 'canceled' ||
        code == 'user-cancelled';
  }

  static bool _shouldFallbackToGoogleSignIn(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
      case 'unauthorized-domain':
      case 'invalid-credential':
        return false;
      default:
        return true;
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
