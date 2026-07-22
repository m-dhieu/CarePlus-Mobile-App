import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'app_user.dart';
import 'google_sign_in_config.dart';

class CareAuthRepository {
  CareAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }

  Future<bool> hasUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
    await credential.user?.sendEmailVerification();
    final uid = credential.user!.uid;
    await _users.doc(uid).set(
          AppUser(
            uid: uid,
            fullName: fullName,
            email: email,
            phone: phone,
            role: 'patient',
            status: 'active',
          ).toNewDoc(),
        );
  }

  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _users
          .doc(uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? googleWebClientId : null,
    );
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google sign-in is not supported on this platform.');
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;
    if (!await hasUserProfile(uid)) {
      await _users.doc(uid).set(
            AppUser(
              uid: uid,
              fullName: userCredential.user?.displayName ??
                  googleUser.displayName ??
                  '',
              email: userCredential.user?.email ?? googleUser.email,
              role: 'patient',
              status: 'active',
            ).toNewDoc(),
          );
    } else {
      await _users
          .doc(uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});
    }
    return userCredential;
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> resetPasswordEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  String mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to a different sign-in method.';
      case 'canceled':
        return 'Sign-in was cancelled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
}
