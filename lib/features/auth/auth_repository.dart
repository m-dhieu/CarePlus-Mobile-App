import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_user.dart';

class CareAuthRepository {
  CareAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

  String _syntheticEmail(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digitsOnly@careplus-app.internal';
  }

  Future<void> registerWithPhonePassword({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _syntheticEmail(phone),
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
    final uid = credential.user!.uid;
    await _users.doc(uid).set(
          AppUser(
            uid: uid,
            fullName: fullName,
            phone: phone,
            role: 'patient',
            status: 'active',
          ).toNewDoc(),
        );
  }

  Future<void> loginWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: _syntheticEmail(phone),
      password: password,
    );
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _users.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  Future<void> startPhoneVerification({
    required String phone,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? forceResendingToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  PhoneAuthCredential smsCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Links a verified phone number to the currently signed-in account, so it
  /// can later be used as an independent sign-in method for the same uid.
  Future<void> linkPhoneToCurrentUser(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to link a phone number to.');
    }
    await user.linkWithCredential(credential);
  }

  /// Signs in using a verified phone credential. If that phone number is
  /// linked to an existing account, this resolves to the same uid.
  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to update a password for.');
    }
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() => _auth.signOut();

  String mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This phone number is already registered.';
      case 'invalid-email':
      case 'invalid-phone-number':
        return 'Enter a valid phone number, e.g. +250788123456.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
        return 'No account found for this phone number.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect phone number or password.';
      case 'invalid-verification-code':
        return 'That code is incorrect. Please try again.';
      case 'session-expired':
      case 'code-expired':
        return 'That code has expired. Request a new one.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
}
