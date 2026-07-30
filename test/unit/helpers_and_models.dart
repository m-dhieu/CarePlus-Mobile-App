import 'package:careplus/models/models.dart';
import 'package:careplus/services/auth_errors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// helpers + model copyWith or expiry logic — no Drift, no widgets

void main() {
  group('AuthErrorMapper', () {
    test('maps cancelled auth to a short user message', () {
      expect(
        AuthErrorMapper.message(AuthCancelledException()),
        'Sign-in cancelled',
      );
    });

    test('prefers explicit unavailable detail when provided', () {
      expect(
        AuthErrorMapper.message(
          AuthUnavailableException('google', 'Play Services unavailable'),
        ),
        'Play Services unavailable',
      );
    });

    test('maps firebase password failures consistently', () {
      expect(
        AuthErrorMapper.message(FirebaseAuthException(code: 'wrong-password')),
        'Invalid email or password',
      );
    });

    test('falls back to raw network hints for unknown errors', () {
      expect(
        AuthErrorMapper.message(Exception('network-request-failed')),
        'Network error — try again',
      );
    });
  });

  group('UserProfile.copyWith', () {
    test('updates selected fields and preserves the rest', () {
      const original = UserProfile(
        name: 'Alice',
        initials: 'AL',
        phone: '+250700000000',
        age: 32,
        bloodType: 'A+',
        height: '170 cm',
        patientId: 'CP-ALICE',
        hba1c: '6.8%',
        bpAvg: '118/77',
        weight: '65 kg',
        allergies: ['Peanuts'],
        emergencyContact: EmergencyContact(
          name: 'Grace',
          relation: 'Sister',
          phone: '+250711111111',
        ),
      );

      const nextEmergency = EmergencyContact(
        name: 'Jean',
        relation: 'Brother',
        phone: '+250722222222',
      );

      final updated = original.copyWith(
        phone: '+250733333333',
        allergies: const ['Peanuts', 'Dust'],
        emergencyContact: nextEmergency,
      );

      expect(updated.name, 'Alice');
      expect(updated.phone, '+250733333333');
      expect(updated.patientId, 'CP-ALICE');
      expect(updated.allergies, ['Peanuts', 'Dust']);
      expect(updated.emergencyContact, nextEmergency);
    });
  });

  group('MedicalDocument.copyWith', () {
    test('stores remote metadata without changing identity fields', () {
      final createdAt = DateTime.utc(2026, 7, 30, 8);
      final original = MedicalDocument(
        id: 'doc-1',
        icon: Icons.science,
        name: 'Lab Result',
        source: 'Imported',
        ocrText: 'HbA1c: 6.8%',
      );

      final updated = original.copyWith(
        storagePath: 'users/u1/documents/doc-1.pdf',
        downloadUrl: 'https://example.com/doc-1.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 4096,
        createdAt: createdAt,
      );

      expect(updated.id, 'doc-1');
      expect(updated.name, 'Lab Result');
      expect(updated.storagePath, 'users/u1/documents/doc-1.pdf');
      expect(updated.downloadUrl, 'https://example.com/doc-1.pdf');
      expect(updated.mimeType, 'application/pdf');
      expect(updated.sizeBytes, 4096);
      expect(updated.createdAt, createdAt);
    });
  });

  group('Caregiver model', () {
    test('copyWith updates sync-backed status fields', () {
      final invitedAt = DateTime.utc(2026, 7, 30, 9);
      final caregiver = Caregiver(
        id: 'cg-1',
        name: 'Maya',
        relation: 'Mother',
        phone: '+250744444444',
        role: CaregiverRole.viewOnly,
      );

      final updated = caregiver.copyWith(
        role: CaregiverRole.fullAccess,
        status: 'accepted',
        invitedAt: invitedAt,
      );

      expect(updated.role, CaregiverRole.fullAccess);
      expect(updated.roleLabel, 'Full access');
      expect(updated.status, 'accepted');
      expect(updated.invitedAt, invitedAt);
      expect(updated.phone, '+250744444444');
    });
  });

  group('Share token expiry', () {
    test('reports expired and active tokens correctly', () {
      final expired = RecordShareToken(
        id: 't1',
        token: 'MED-OLD',
        doctorName: 'Dr. A',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final active = RecordShareToken(
        id: 't2',
        token: 'MED-NEW',
        doctorName: 'Dr. B',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );

      expect(expired.isExpired, isTrue);
      expect(active.isExpired, isFalse);
    });
  });
}
