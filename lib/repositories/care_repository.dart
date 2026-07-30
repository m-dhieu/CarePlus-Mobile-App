import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/models.dart';
import '../sync/outbox_service.dart';
import '../sync/sync_constants.dart';

typedef SyncRequest = void Function();

class CareRepository {
  CareRepository(this._db, this._outbox, {this.onDirty});

  final AppDatabase _db;
  final OutboxService _outbox;
  final SyncRequest? onDirty;
  static const _uuid = Uuid();

  void _nudge() => onDirty?.call();

  // ── Medications ────────────────────────────────────────────────────────────

  Stream<List<Medication>> watchMedications(String userId) {
    return (_db.select(_db.medications)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(medicationFromRow).toList());
  }

  Future<void> addMedication(String userId, Medication med) async {
    final now = DateTime.now().toUtc();
    final id = med.id.isEmpty ? _uuid.v4() : med.id;
    await _db.into(_db.medications).insert(MedicationsCompanion.insert(
          id: id,
          userId: userId,
          name: med.name,
          dose: med.dose,
          condition: med.condition,
          refills: med.refills,
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.medications,
      entityId: id,
      operation: SyncOps.create,
      payload: _medicationPayload(row),
    );
    _nudge();
  }

  Future<void> requestRefill(String userId, String id) async {
    final row = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      refills: row.refills + 1,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.medications).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.medications,
      entityId: id,
      operation: SyncOps.update,
      payload: _medicationPayload(updated),
    );
    _nudge();
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  Stream<List<Reminder>> watchReminders(String userId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(reminderFromRow).toList());
  }

  Future<void> toggleReminder(String userId, String id) async {
    final row = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      enabled: !row.enabled,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.reminders).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.reminders,
      entityId: id,
      operation: SyncOps.update,
      payload: _reminderPayload(updated),
    );
    _nudge();
  }

  Future<void> addReminder(String userId, Reminder reminder) async {
    final now = DateTime.now().toUtc();
    final id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
    final companion = RemindersCompanion.insert(
      id: id,
      userId: userId,
      medicationName: reminder.medicationName,
      hour: reminder.time.hour,
      minute: reminder.time.minute,
      days: jsonEncode(reminder.days),
      enabled: Value(reminder.enabled),
      updatedAt: now,
      syncStatus: const Value(SyncStatuses.pending),
    );
    await _db.into(_db.reminders).insert(companion);
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.reminders,
      entityId: id,
      operation: SyncOps.create,
      payload: _reminderPayload(row),
    );
    _nudge();
  }

  Future<void> removeReminder(String userId, String id) async {
    final row = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      deletedAt: Value(now),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.reminders).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.reminders,
      entityId: id,
      operation: SyncOps.delete,
      payload: _reminderPayload(updated),
    );
    _nudge();
  }

  Future<void> updateReminderTime(
      String userId, String id, TimeOfDay time) async {
    final row = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      hour: time.hour,
      minute: time.minute,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.reminders).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.reminders,
      entityId: id,
      operation: SyncOps.update,
      payload: _reminderPayload(updated),
    );
    _nudge();
  }

  // ── Journal ────────────────────────────────────────────────────────────────

  Stream<List<JournalEntry>> watchJournal(String userId) {
    return (_db.select(_db.journalEntries)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(journalFromRow).toList());
  }

  Future<void> addJournal(String userId, JournalEntry entry) async {
    final now = DateTime.now().toUtc();
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    await _db.into(_db.journalEntries).insert(JournalEntriesCompanion.insert(
          id: id,
          userId: userId,
          type: entry.type,
          date: entry.date,
          facility: entry.facility,
          title: entry.title,
          person: entry.person,
          note: entry.note,
          tags: jsonEncode(entry.tags),
          iconCodePoint: entry.icon.codePoint,
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row =
        await (_db.select(_db.journalEntries)..where((t) => t.id.equals(id)))
            .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.journalEntries,
      entityId: id,
      operation: SyncOps.create,
      payload: _journalPayload(row),
    );
    _nudge();
  }

  // ── Documents ──────────────────────────────────────────────────────────────

  Stream<List<MedicalDocument>> watchDocuments(String userId) {
    return (_db.select(_db.documents)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(documentFromRow).toList());
  }

  Future<void> addDocument(String userId, MedicalDocument doc) async {
    final now = DateTime.now().toUtc();
    final id = doc.id.isEmpty ? _uuid.v4() : doc.id;
    await _db.into(_db.documents).insert(DocumentsCompanion.insert(
          id: id,
          userId: userId,
          iconCodePoint: doc.icon.codePoint,
          name: doc.name,
          source: doc.source,
          ocrText: Value(doc.ocrText),
          storagePath: Value(doc.storagePath),
          downloadUrl: Value(doc.downloadUrl),
          mimeType: Value(doc.mimeType),
          sizeBytes: Value(doc.sizeBytes),
          createdAt: Value(doc.createdAt ?? now),
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row =
        await (_db.select(_db.documents)..where((t) => t.id.equals(id)))
            .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.documents,
      entityId: id,
      operation: SyncOps.create,
      payload: _documentPayload(row),
    );
    _nudge();
  }

  Future<void> updateDocumentOcr(
      String userId, String id, String ocrText) async {
    final row = await (_db.select(_db.documents)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      ocrText: Value(ocrText),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.documents).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.documents,
      entityId: id,
      operation: SyncOps.update,
      payload: _documentPayload(updated),
    );
    _nudge();
  }

  Future<void> updateDocumentRemote(
    String userId,
    String id, {
    String? storagePath,
    String? downloadUrl,
    String? mimeType,
    int? sizeBytes,
  }) async {
    final row = await (_db.select(_db.documents)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      storagePath: Value(storagePath ?? row.storagePath),
      downloadUrl: Value(downloadUrl ?? row.downloadUrl),
      mimeType: Value(mimeType ?? row.mimeType),
      sizeBytes: Value(sizeBytes ?? row.sizeBytes),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.documents).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.documents,
      entityId: id,
      operation: SyncOps.update,
      payload: _documentPayload(updated),
    );
    _nudge();
  }

  // ── Caregivers ─────────────────────────────────────────────────────────────

  Stream<List<Caregiver>> watchCaregivers(String userId) {
    return (_db.select(_db.caregivers)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(caregiverFromRow).toList());
  }

  Future<void> addCaregiver(String userId, Caregiver c) async {
    final now = DateTime.now().toUtc();
    final id = c.id.isEmpty ? _uuid.v4() : c.id;
    await _db.into(_db.caregivers).insert(CaregiversCompanion.insert(
          id: id,
          userId: userId,
          name: c.name,
          relation: c.relation,
          phone: c.phone,
          role: c.role.name,
          notificationsEnabled: Value(c.notificationsEnabled),
          status: Value(c.status),
          invitedAt: Value(c.invitedAt ?? now),
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row =
        await (_db.select(_db.caregivers)..where((t) => t.id.equals(id)))
            .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.caregivers,
      entityId: id,
      operation: SyncOps.create,
      payload: _caregiverPayload(row),
    );
    _nudge();
  }

  Future<void> removeCaregiver(String userId, String id) async {
    final row = await (_db.select(_db.caregivers)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      deletedAt: Value(now),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.caregivers).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.caregivers,
      entityId: id,
      operation: SyncOps.delete,
      payload: _caregiverPayload(updated),
    );
    _nudge();
  }

  Future<void> updateCaregiverRole(
      String userId, String id, CaregiverRole role) async {
    final row = await (_db.select(_db.caregivers)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      role: role.name,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.caregivers).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.caregivers,
      entityId: id,
      operation: SyncOps.update,
      payload: _caregiverPayload(updated),
    );
    _nudge();
  }

  Future<void> toggleCaregiverNotifications(String userId, String id) async {
    final row = await (_db.select(_db.caregivers)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      notificationsEnabled: !row.notificationsEnabled,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.caregivers).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.caregivers,
      entityId: id,
      operation: SyncOps.update,
      payload: _caregiverPayload(updated),
    );
    _nudge();
  }

  Future<void> updateCaregiverStatus(
    String userId,
    String id,
    String status,
  ) async {
    final row = await (_db.select(_db.caregivers)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      status: status,
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.caregivers).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.caregivers,
      entityId: id,
      operation: SyncOps.update,
      payload: _caregiverPayload(updated),
    );
    _nudge();
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Stream<UserProfile?> watchProfile(String userId) {
    return (_db.select(_db.userProfiles)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : profileFromRow(rows.first));
  }

  /// Creates a blank per-user profile once (from Auth display name / email).
  /// Existing Drift or Firestore profiles are left untouched.
  Future<void> ensureProfile(
    String userId, {
    String? displayName,
    String? email,
  }) async {
    final existing = await (_db.select(_db.userProfiles)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    final name = _displayName(displayName, email);
    final now = DateTime.now().toUtc();
    final id = 'profile-$userId';
    final short = userId.length >= 6 ? userId.substring(0, 6) : userId;
    await _db.into(_db.userProfiles).insert(UserProfilesCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          initials: _initials(name),
          phone: const Value('—'),
          age: 0,
          bloodType: '—',
          height: '—',
          patientId: 'CP-${short.toUpperCase()}',
          hba1c: '—',
          bpAvg: '—',
          weight: '—',
          allergies: '[]',
          emergencyName: '—',
          emergencyRelation: '—',
          emergencyPhone: '—',
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.profile,
      entityId: id,
      operation: SyncOps.create,
      payload: _profilePayload(row),
    );
    _nudge();
  }

  Future<void> upsertProfile(
    String userId, {
    required String name,
    required String phone,
    int? age,
    String? bloodType,
    String? height,
    String? hba1c,
    String? bpAvg,
    String? weight,
    List<String>? allergies,
    EmergencyContact? emergencyContact,
  }) async {
    final existing = await (_db.select(_db.userProfiles)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    final currentAllergies = existing == null
        ? const <String>[]
        : profileFromRow(existing).allergies;
    final now = DateTime.now().toUtc();
    final id = existing?.id ?? 'profile-$userId';
    final short = userId.length >= 6 ? userId.substring(0, 6) : userId;
    await _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: id,
            userId: userId,
            name: name.trim().isEmpty ? 'User' : name.trim(),
            initials: _initials(name.trim().isEmpty ? 'User' : name.trim()),
            phone: Value(phone.trim().isEmpty ? '—' : phone.trim()),
            age: age ?? existing?.age ?? 0,
            bloodType: bloodType ?? existing?.bloodType ?? '—',
            height: height ?? existing?.height ?? '—',
            patientId: existing?.patientId ?? 'CP-${short.toUpperCase()}',
            hba1c: hba1c ?? existing?.hba1c ?? '—',
            bpAvg: bpAvg ?? existing?.bpAvg ?? '—',
            weight: weight ?? existing?.weight ?? '—',
            allergies: jsonEncode(allergies ?? currentAllergies),
            emergencyName:
                emergencyContact?.name ?? existing?.emergencyName ?? '—',
            emergencyRelation:
                emergencyContact?.relation ?? existing?.emergencyRelation ?? '—',
            emergencyPhone:
                emergencyContact?.phone ?? existing?.emergencyPhone ?? '—',
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ),
        );
    final row = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.profile,
      entityId: id,
      operation: existing == null ? SyncOps.create : SyncOps.update,
      payload: _profilePayload(row),
    );
    _nudge();
  }

  static String _displayName(String? displayName, String? email) {
    final fromAuth = displayName?.trim();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final fromEmail = email?.trim();
    if (fromEmail != null && fromEmail.contains('@')) {
      return fromEmail.split('@').first;
    }
    return 'User';
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  // ── Share tokens ───────────────────────────────────────────────────────────

  Stream<List<RecordShareToken>> watchShareTokens(String userId) {
    return (_db.select(_db.shareTokens)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(shareTokenFromRow).toList());
  }

  Future<RecordShareToken> generateShareToken(
      String userId, String doctorName) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final token =
        'CPX-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final expires = now.add(const Duration(hours: 24));
    await _db.into(_db.shareTokens).insert(ShareTokensCompanion.insert(
          id: id,
          userId: userId,
          token: token,
          doctorName: doctorName,
          expiresAt: expires,
          redeemed: const Value(false),
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row =
        await (_db.select(_db.shareTokens)..where((t) => t.id.equals(id)))
            .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.shareTokens,
      entityId: id,
      operation: SyncOps.create,
      payload: _sharePayload(row),
    );
    _nudge();
    return shareTokenFromRow(row);
  }

  Future<void> markShareTokenRedeemed(String userId, String tokenId) async {
    final row = await (_db.select(_db.shareTokens)
          ..where((t) => t.id.equals(tokenId) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      redeemed: true,
      redeemedAt: Value(now),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.shareTokens).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.shareTokens,
      entityId: tokenId,
      operation: SyncOps.update,
      payload: _sharePayload(updated),
    );
    _nudge();
  }

  Future<void> revokeShareToken(String userId, String token) async {
    final row = await (_db.select(_db.shareTokens)
          ..where((t) => t.token.equals(token) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      deletedAt: Value(now),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.shareTokens).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.shareTokens,
      entityId: row.id,
      operation: SyncOps.delete,
      payload: _sharePayload(updated),
    );
    _nudge();
  }

  // ── Emergency access ───────────────────────────────────────────────────────

  Stream<EmergencyAccessCode?> watchEmergency(String userId) {
    return (_db.select(_db.emergencyAccessCodes)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : emergencyFromRow(rows.first));
  }

  Future<EmergencyAccessCode> generateEmergency(
      String userId, String scope) async {
    // Soft-delete prior codes
    final existing = await (_db.select(_db.emergencyAccessCodes)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .get();
    final now = DateTime.now().toUtc();
    for (final row in existing) {
      final tomb = row.copyWith(
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: SyncStatuses.pending,
      );
      await _db.update(_db.emergencyAccessCodes).replace(tomb);
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.emergencyAccess,
        entityId: row.id,
        operation: SyncOps.delete,
        payload: _emergencyPayload(tomb),
      );
    }

    final id = _uuid.v4();
    final code =
        (100000 + now.millisecondsSinceEpoch % 900000).toString();
    final expires = now.add(const Duration(minutes: 30));
    await _db
        .into(_db.emergencyAccessCodes)
        .insert(EmergencyAccessCodesCompanion.insert(
          id: id,
          userId: userId,
          code: code,
          expiresAt: expires,
          scope: scope,
          redeemed: const Value(false),
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    final row = await (_db.select(_db.emergencyAccessCodes)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.emergencyAccess,
      entityId: id,
      operation: SyncOps.create,
      payload: _emergencyPayload(row),
    );
    _nudge();
    return emergencyFromRow(row);
  }

  Future<void> markEmergencyRedeemed(String userId, String codeId) async {
    final row = await (_db.select(_db.emergencyAccessCodes)
          ..where((t) => t.id.equals(codeId) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final updated = row.copyWith(
      redeemed: true,
      redeemedAt: Value(now),
      updatedAt: now,
      syncStatus: SyncStatuses.pending,
    );
    await _db.update(_db.emergencyAccessCodes).replace(updated);
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.emergencyAccess,
      entityId: codeId,
      operation: SyncOps.update,
      payload: _emergencyPayload(updated),
    );
    _nudge();
  }

  Future<void> revokeEmergency(String userId) async {
    final rows = await (_db.select(_db.emergencyAccessCodes)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .get();
    final now = DateTime.now().toUtc();
    for (final row in rows) {
      final updated = row.copyWith(
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: SyncStatuses.pending,
      );
      await _db.update(_db.emergencyAccessCodes).replace(updated);
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.emergencyAccess,
        entityId: row.id,
        operation: SyncOps.delete,
        payload: _emergencyPayload(updated),
      );
    }
    _nudge();
  }

  // ── Metrics ────────────────────────────────────────────────────────────────

  Stream<Map<String, MetricSeries>> watchMetrics(String userId) {
    return (_db.select(_db.metricPoints)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .watch()
        .map(metricsFromRows);
  }

  Future<void> addMetricPoint(
    String userId, {
    required String seriesKey,
    required String label,
    required String unit,
    required DateTime date,
    required double value,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db.into(_db.metricPoints).insert(
          MetricPointsCompanion.insert(
            id: id,
            userId: userId,
            seriesKey: seriesKey,
            label: label,
            unit: unit,
            date: date.toUtc(),
            value: value,
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ),
        );
    final row = await (_db.select(_db.metricPoints)..where((t) => t.id.equals(id)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.metricPoints,
      entityId: id,
      operation: SyncOps.create,
      payload: _metricPayload(row),
    );
    _nudge();
  }

  // ── Payloads ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _medicationPayload(MedicationRow r) => {
        'id': r.id,
        'userId': r.userId,
        'name': r.name,
        'dose': r.dose,
        'condition': r.condition,
        'refills': r.refills,
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _profilePayload(UserProfileRow r) => {
        'id': r.id,
        'userId': r.userId,
        'name': r.name,
        'initials': r.initials,
        'phone': r.phone,
        'age': r.age,
        'bloodType': r.bloodType,
        'height': r.height,
        'patientId': r.patientId,
        'hba1c': r.hba1c,
        'bpAvg': r.bpAvg,
        'weight': r.weight,
        'allergies': r.allergies,
        'emergencyName': r.emergencyName,
        'emergencyRelation': r.emergencyRelation,
        'emergencyPhone': r.emergencyPhone,
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _reminderPayload(ReminderRow r) => {
        'id': r.id,
        'userId': r.userId,
        'medicationName': r.medicationName,
        'hour': r.hour,
        'minute': r.minute,
        'days': r.days,
        'enabled': r.enabled,
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _journalPayload(JournalEntryRow r) => {
        'id': r.id,
        'userId': r.userId,
        'type': r.type,
        'date': r.date,
        'facility': r.facility,
        'title': r.title,
        'person': r.person,
        'note': r.note,
        'tags': r.tags,
        'iconCodePoint': r.iconCodePoint,
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _documentPayload(DocumentRow r) => {
        'id': r.id,
        'userId': r.userId,
        'iconCodePoint': r.iconCodePoint,
        'name': r.name,
        'source': r.source,
        'ocrText': r.ocrText,
        'storagePath': r.storagePath,
        'downloadUrl': r.downloadUrl,
        'mimeType': r.mimeType,
        'sizeBytes': r.sizeBytes,
        'createdAt': r.createdAt?.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _caregiverPayload(CaregiverRow r) => {
        'id': r.id,
        'userId': r.userId,
        'name': r.name,
        'relation': r.relation,
        'phone': r.phone,
        'role': r.role,
        'notificationsEnabled': r.notificationsEnabled,
        'status': r.status,
        'invitedAt': r.invitedAt?.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _sharePayload(ShareTokenRow r) => {
        'id': r.id,
        'userId': r.userId,
        'token': r.token,
        'doctorName': r.doctorName,
        'expiresAt': r.expiresAt.toIso8601String(),
        'redeemed': r.redeemed,
        'redeemedAt': r.redeemedAt?.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _emergencyPayload(EmergencyAccessRow r) => {
        'id': r.id,
        'userId': r.userId,
        'code': r.code,
        'expiresAt': r.expiresAt.toIso8601String(),
        'scope': r.scope,
        'redeemed': r.redeemed,
        'redeemedAt': r.redeemedAt?.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _metricPayload(MetricPointRow r) => {
        'id': r.id,
        'userId': r.userId,
        'seriesKey': r.seriesKey,
        'label': r.label,
        'unit': r.unit,
        'date': r.date.toIso8601String(),
        'value': r.value,
        'updatedAt': r.updatedAt.toIso8601String(),
        'syncStatus': r.syncStatus,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };
}
