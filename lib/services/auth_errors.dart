import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// User-facing auth failures that are safe to map in UI and tests.
class AuthCancelledException implements Exception {
  @override
  String toString() => 'AuthCancelledException';
}

class AuthUnavailableException implements Exception {
  AuthUnavailableException(this.provider, [this.detail]);
  final String provider;
  final String? detail;

  @override
  String toString() =>
      'AuthUnavailableException($provider${detail == null ? '' : ': $detail'})';
}

/// Maps Firebase / social auth errors to short UI messages.
abstract final class AuthErrorMapper {
  static String message(Object error) {
    if (error is AuthCancelledException) {
      return 'Sign-in cancelled';
    }
    if (error is AuthUnavailableException) {
      final detail = error.detail;
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
      return '${_title(error.provider)} sign-in is not available on this device';
    }

    if (error is FirebaseAuthException) {
      return _firebase(error);
    }

    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Sign-in cancelled';
      }
      return error.description?.isNotEmpty == true
          ? error.description!
          : 'Google sign-in failed';
    }

    final raw = error.toString();
    if (raw.contains('invalid-email')) return 'Invalid email address';
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'Invalid email or password';
    }
    if (raw.contains('email-already-in-use')) return 'Email already in use';
    if (raw.contains('weak-password')) {
      return 'Password should be at least 6 characters';
    }
    if (raw.contains('network-request-failed') || raw.contains('network')) {
      return 'Network error — try again';
    }
    if (raw.contains('account-exists-with-different-credential')) {
      return 'An account already exists with a different sign-in method';
    }
    if (raw.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled in Firebase Console';
    }
    if (raw.contains('unauthorized-domain')) {
      return 'This domain is not authorized for Google sign-in';
    }
    if (raw.contains('canceled') || raw.contains('cancelled')) {
      return 'Sign-in cancelled';
    }
    return 'Authentication failed';
  }

  static String _firebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password';
      case 'invalid-credential':
        return 'Sign-in failed — check Google is enabled in Firebase Console';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'network-request-failed':
        return 'Network error — try again';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Console';
      case 'unauthorized-domain':
        return 'Add this domain under Firebase Authentication → Settings → Authorized domains';
      case 'popup-blocked':
        return 'Pop-up blocked — allow pop-ups for this site and try again';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
        return 'Sign-in cancelled';
      default:
        final msg = error.message;
        if (msg != null && msg.isNotEmpty) return msg;
        return 'Authentication failed (${error.code})';
    }
  }

  static String _title(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        return provider;
    }
  }
}
