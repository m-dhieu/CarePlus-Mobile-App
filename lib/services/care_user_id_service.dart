import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Care+ public user ids matching the Firestore seed schema: `user_001`, `user_002`
///
// Firebase Auth uid stays the security / Drift `userId`
// `patientId` (and top-level `users/{careUserId}`) use this public id
class CareUserIdService {
  CareUserIdService({FirebaseFirestore? firestore, this.localOnly = false})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  // When true (unit tests / forced offline), skip Firestore counter
  final bool localOnly;

  static const _uuid = Uuid();

  /// Counter doc: starts after seeded `user_001` / `user_002`
  static const counterPath = 'meta/user_counter';
  static const _defaultNext = 3;

  // Online: next `user_NNN` from Firestore counter
  // Offline / error / [localOnly]: `user_` + 8 hex chars (still schema-shaped)
  Future<String> allocate() async {
    if (localOnly) return localFallback();
    try {
      final fs = _firestore ?? FirebaseFirestore.instance;
      return await fs.runTransaction((tx) async {
        final ref = fs.doc(counterPath);
        final snap = await tx.get(ref);
        final next = (snap.data()?['next'] as num?)?.toInt() ?? _defaultNext;
        tx.set(ref, {'next': next + 1}, SetOptions(merge: true));
        return format(next);
      });
    } catch (_) {
      return localFallback();
    }
  }

  static String format(int n) => 'user_${n.toString().padLeft(3, '0')}';

  static String localFallback() {
    final hex = _uuid.v4().replaceAll('-', '');
    return 'user_${hex.substring(0, 8)}';
  }

  // Top-level registry doc shaped like `scripts/seed_firestore.js` users/*
  Map<String, dynamic> registryPayload({
    required String careUserId,
    required String authUid,
    required String fullName,
    required String email,
    required String phone,
    String role = 'patient',
    String status = 'active',
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    final now = (createdAt ?? DateTime.now().toUtc()).toIso8601String();
    final login = (lastLogin ?? DateTime.now().toUtc()).toIso8601String();
    return {
      'uid': careUserId,
      'authUid': authUid,
      'fullName': fullName,
      'email': email,
      'phone': phone.trim().isEmpty ? '—' : phone.trim(),
      'role': role,
      'status': status,
      'createdAt': now,
      'lastLogin': login,
      'updatedAt': now,
      'id': careUserId,
      'userId': authUid,
    };
  }
}
