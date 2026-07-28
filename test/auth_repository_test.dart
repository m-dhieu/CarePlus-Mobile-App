import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:careplus/features/auth/auth_repository.dart';

import 'support/fake_users_firestore.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeUsersFirestore firestore;
  late CareAuthRepository repo;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeUsersFirestore();
    repo = CareAuthRepository(auth: auth, firestore: firestore);
  });

  group('registerWithEmailPassword', () {
    test('creates a Firebase user and a matching users/{uid} profile',
        () async {
      await repo.registerWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
        fullName: 'Ada Lovelace',
        phone: '+250788123456',
      );

      final uid = auth.currentUser!.uid;
      final doc = await firestore.collection('users').doc(uid).get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['fullName'], 'Ada Lovelace');
      expect(doc.data()!['email'], 'ada@example.com');
      expect(doc.data()!['phone'], '+250788123456');
      expect(doc.data()!['role'], 'patient');
      expect(doc.data()!['status'], 'active');
    });
  });

  group('loginWithEmailPassword', () {
    test('signs in and stamps lastLogin on the existing profile', () async {
      await repo.registerWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
        fullName: 'Ada Lovelace',
      );
      final uid = auth.currentUser!.uid;

      await repo.loginWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
      );

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.data()!['lastLogin'], isNotNull);
      expect(auth.currentUser, isNotNull);
    });
  });

  group('signOut', () {
    test('clears the current user', () async {
      await repo.registerWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
        fullName: 'Ada Lovelace',
      );
      expect(auth.currentUser, isNotNull);

      await repo.signOut();

      expect(auth.currentUser, isNull);
    });
  });

  group('hasUserProfile', () {
    test('is true after registration and false for an unknown uid',
        () async {
      await repo.registerWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
        fullName: 'Ada Lovelace',
      );
      final uid = auth.currentUser!.uid;

      expect(await repo.hasUserProfile(uid), isTrue);
      expect(await repo.hasUserProfile('someone-else'), isFalse);
    });
  });

  group('watchUser', () {
    test('streams the profile matching the created document', () async {
      await repo.registerWithEmailPassword(
        email: 'ada@example.com',
        password: 'supersecret',
        fullName: 'Ada Lovelace',
      );
      final uid = auth.currentUser!.uid;

      final appUser = await repo.watchUser(uid).first;

      expect(appUser, isNotNull);
      expect(appUser!.fullName, 'Ada Lovelace');
      expect(appUser.email, 'ada@example.com');
    });

    test('emits null for a profile that does not exist', () async {
      final appUser = await repo.watchUser('missing-uid').first;
      expect(appUser, isNull);
    });
  });

  group('resetPasswordEmail', () {
    test('completes without throwing', () async {
      await expectLater(
        repo.resetPasswordEmail('ada@example.com'),
        completes,
      );
    });
  });

  group('mapAuthError', () {
    test('maps known codes to friendly messages', () {
      expect(
        repo.mapAuthError(FirebaseAuthException(code: 'user-not-found')),
        'No account found for this email.',
      );
      expect(
        repo.mapAuthError(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'An account already exists for this email.',
      );
      expect(
        repo.mapAuthError(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect email or password.',
      );
    });

    test('falls back to the exception message for unknown codes', () {
      expect(
        repo.mapAuthError(
          FirebaseAuthException(code: 'weird-code', message: 'Odd failure'),
        ),
        'Odd failure',
      );
    });
  });
}
