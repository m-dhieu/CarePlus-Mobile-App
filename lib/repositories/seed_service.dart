import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../sync/outbox_service.dart';
import '../sync/sync_constants.dart';

/// Seeds demo data once per Firebase Auth user so offline UI is populated.
class SeedService {
  SeedService(this._db, this._outbox);

  final AppDatabase _db;
  final OutboxService _outbox;
  static const _uuid = Uuid();

  Future<void> seedIfNeeded(String userId) async {
    final existing = await (_db.select(_db.syncMeta)
          ..where((t) =>
              t.userId.equals(userId) & t.key.equals(SyncMetaKeys.seeded)))
        .getSingleOrNull();
    if (existing != null) return;

    final now = DateTime.now().toUtc();

    // Profile
    final profileId = 'profile-$userId';
    await _db.into(_db.userProfiles).insert(UserProfilesCompanion.insert(
          id: profileId,
          userId: userId,
          name: 'Arnold Mugabo',
          initials: 'AM',
          age: 42,
          bloodType: 'O+',
          height: '174 cm',
          patientId: 'VTL-2026-08124',
          hba1c: '6.8%',
          bpAvg: '124/82',
          weight: '78 kg',
          allergies: jsonEncode(['Penicillin', 'Sulfa drugs', 'Peanuts']),
          emergencyName: 'Grace Mugisha',
          emergencyRelation: 'Spouse',
          emergencyPhone: '+250 788 832 123',
          updatedAt: now,
          syncStatus: const Value(SyncStatuses.pending),
        ));
    await _enqueueProfile(userId, profileId);

    final meds = [
      ('1', 'Metformin', '500 mg', 'Type 2 Diabetes', 2),
      ('2', 'Lisinopril', '10 mg', 'Hypertension', 4),
      ('3', 'Atorvastatin', '20 mg', 'Cholesterol', 1),
      ('4', 'Vitamin D3', '1000 IU', 'Supplement', 6),
    ];
    for (final m in meds) {
      await _db.into(_db.medications).insert(MedicationsCompanion.insert(
            id: m.$1,
            userId: userId,
            name: m.$2,
            dose: m.$3,
            condition: m.$4,
            refills: m.$5,
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ));
      final row = await (_db.select(_db.medications)
            ..where((t) => t.id.equals(m.$1)))
          .getSingle();
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.medications,
        entityId: m.$1,
        operation: SyncOps.create,
        payload: {
          'id': row.id,
          'userId': row.userId,
          'name': row.name,
          'dose': row.dose,
          'condition': row.condition,
          'refills': row.refills,
          'updatedAt': row.updatedAt.toIso8601String(),
          'syncStatus': row.syncStatus,
          'deletedAt': null,
        },
      );
    }

    final reminders = [
      ('1', 'Metformin', 8, 0, [true, true, true, true, true, true, true]),
      ('2', 'Lisinopril', 13, 30, [true, true, true, true, true, false, false]),
      ('3', 'Atorvastatin', 21, 30, [true, true, true, true, true, true, true]),
    ];
    for (final r in reminders) {
      await _db.into(_db.reminders).insert(RemindersCompanion.insert(
            id: r.$1,
            userId: userId,
            medicationName: r.$2,
            hour: r.$3,
            minute: r.$4,
            days: jsonEncode(r.$5),
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ));
      final row = await (_db.select(_db.reminders)
            ..where((t) => t.id.equals(r.$1)))
          .getSingle();
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.reminders,
        entityId: r.$1,
        operation: SyncOps.create,
        payload: {
          'id': row.id,
          'userId': row.userId,
          'medicationName': row.medicationName,
          'hour': row.hour,
          'minute': row.minute,
          'days': row.days,
          'enabled': row.enabled,
          'updatedAt': row.updatedAt.toIso8601String(),
          'syncStatus': row.syncStatus,
          'deletedAt': null,
        },
      );
    }

    final journal = [
      (
        '1',
        'Visit',
        '08 JUN',
        'Kigali University Hospital',
        'Routine endocrinology check-up',
        'Dr. Amara Diallo',
        'HbA1c improved to 6.8%. Continue current regimen.',
        ['Diabetes', 'Follow-up'],
        Icons.medical_services.codePoint,
      ),
      (
        '2',
        'Lab',
        '29 MAY',
        'Central Pathology',
        'Lipid panel & HbA1c',
        'Lab · Central Pathology',
        'LDL 102 mg/dl, HDL 48, HbA1c 6.8%.',
        ['Lab result'],
        Icons.science.codePoint,
      ),
      (
        '3',
        'Prescription',
        '14 MAY',
        "St. Mary's Medical Center",
        'Atorvastatin 20mg added',
        'Dr. Henrik Vos',
        'Begin once-daily evening dose.',
        ['New med'],
        Icons.medication.codePoint,
      ),
      (
        '4',
        'Procedure',
        '02 APR',
        'Riverside Clinic',
        'Ophthalmology screening – retina',
        'Dr. Lin Wei',
        'No diabetic retinopathy detected.',
        ['Screening', 'Annual'],
        Icons.monitor_heart.codePoint,
      ),
      (
        '5',
        'Visit',
        '18 MAR',
        "St. Mary's Medical Center",
        'Cardiology consultation',
        'Dr. Henrik Vos',
        'Blood pressure trending high. Adjusted Lisinopril to 10mg.',
        ['New med'],
        Icons.medical_services.codePoint,
      ),
    ];
    for (final j in journal) {
      await _db.into(_db.journalEntries).insert(JournalEntriesCompanion.insert(
            id: j.$1,
            userId: userId,
            type: j.$2,
            date: j.$3,
            facility: j.$4,
            title: j.$5,
            person: j.$6,
            note: j.$7,
            tags: jsonEncode(j.$8),
            iconCodePoint: j.$9,
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ));
      final row = await (_db.select(_db.journalEntries)
            ..where((t) => t.id.equals(j.$1)))
          .getSingle();
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.journalEntries,
        entityId: j.$1,
        operation: SyncOps.create,
        payload: {
          'id': row.id,
          'userId': row.userId,
          'type': row.type,
          'date': row.date,
          'facility': row.facility,
          'title': row.title,
          'person': row.person,
          'note': row.note,
          'tags': row.tags,
          'iconCodePoint': row.iconCodePoint,
          'updatedAt': row.updatedAt.toIso8601String(),
          'syncStatus': row.syncStatus,
          'deletedAt': null,
        },
      );
    }

    final docs = [
      ('1', Icons.science.codePoint, 'Hb1c lab results',
          'Central Pathology · 29 May 2026'),
      ('2', Icons.description.codePoint, 'Cardiology consultation note',
          'Dr. Henrik Vos · 18 Mar 2026'),
      ('3', Icons.image.codePoint, 'Retina scan – left eye',
          'Riverside Clinic · 2 Apr 2026'),
      ('4', Icons.description.codePoint, 'Discharge summary',
          'Kigali University Hospital · 11 Jan 2026'),
    ];
    for (final d in docs) {
      await _db.into(_db.documents).insert(DocumentsCompanion.insert(
            id: d.$1,
            userId: userId,
            iconCodePoint: d.$2,
            name: d.$3,
            source: d.$4,
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ));
      final row = await (_db.select(_db.documents)
            ..where((t) => t.id.equals(d.$1)))
          .getSingle();
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.documents,
        entityId: d.$1,
        operation: SyncOps.create,
        payload: {
          'id': row.id,
          'userId': row.userId,
          'iconCodePoint': row.iconCodePoint,
          'name': row.name,
          'source': row.source,
          'ocrText': row.ocrText,
          'updatedAt': row.updatedAt.toIso8601String(),
          'syncStatus': row.syncStatus,
          'deletedAt': null,
        },
      );
    }

    final caregivers = [
      ('1', 'Grace Mugisha', 'Spouse', '+250 788 832 123', 'fullAccess'),
      ('2', 'Eric Mugabo', 'Brother', '+250 788 111 222', 'viewOnly'),
    ];
    for (final c in caregivers) {
      await _db.into(_db.caregivers).insert(CaregiversCompanion.insert(
            id: c.$1,
            userId: userId,
            name: c.$2,
            relation: c.$3,
            phone: c.$4,
            role: c.$5,
            updatedAt: now,
            syncStatus: const Value(SyncStatuses.pending),
          ));
      final row = await (_db.select(_db.caregivers)
            ..where((t) => t.id.equals(c.$1)))
          .getSingle();
      await _outbox.enqueue(
        userId: userId,
        entityType: EntityTypes.caregivers,
        entityId: c.$1,
        operation: SyncOps.create,
        payload: {
          'id': row.id,
          'userId': row.userId,
          'name': row.name,
          'relation': row.relation,
          'phone': row.phone,
          'role': row.role,
          'notificationsEnabled': row.notificationsEnabled,
          'updatedAt': row.updatedAt.toIso8601String(),
          'syncStatus': row.syncStatus,
          'deletedAt': null,
        },
      );
    }

    final series = <String, (String, String, List<double>)>{
      'glucose': ('Blood Glucose', 'mg/dL', [132, 128, 125, 121, 119, 117, 119]),
      'bp_sys': ('Systolic BP', 'mmHg', [138, 135, 130, 128, 126, 124, 125]),
      'bp_dia': ('Diastolic BP', 'mmHg', [90, 88, 86, 84, 83, 82, 82]),
      'hr': ('Heart Rate', 'bpm', [78, 76, 75, 74, 73, 72, 72]),
      'weight': ('Weight', 'kg', [81, 80.5, 80, 79.5, 79, 78.5, 78]),
      'hba1c': ('HbA1c', '%', [7.4, 7.2, 7.1, 7.0, 6.9, 6.8, 6.8]),
    };
    for (final entry in series.entries) {
      final vals = entry.value.$3;
      for (var i = 0; i < vals.length; i++) {
        final id = _uuid.v4();
        final date = now.subtract(Duration(days: (vals.length - 1 - i) * 7));
        await _db.into(_db.metricPoints).insert(MetricPointsCompanion.insert(
              id: id,
              userId: userId,
              seriesKey: entry.key,
              label: entry.value.$1,
              unit: entry.value.$2,
              date: date,
              value: vals[i],
              updatedAt: now,
              syncStatus: const Value(SyncStatuses.pending),
            ));
        await _outbox.enqueue(
          userId: userId,
          entityType: EntityTypes.metricPoints,
          entityId: id,
          operation: SyncOps.create,
          payload: {
            'id': id,
            'userId': userId,
            'seriesKey': entry.key,
            'label': entry.value.$1,
            'unit': entry.value.$2,
            'date': date.toIso8601String(),
            'value': vals[i],
            'updatedAt': now.toIso8601String(),
            'syncStatus': SyncStatuses.pending,
            'deletedAt': null,
          },
        );
      }
    }

    await _db.into(_db.syncMeta).insert(SyncMetaCompanion.insert(
          key: SyncMetaKeys.seeded,
          userId: userId,
          value: 'true',
        ));
  }

  Future<void> _enqueueProfile(String userId, String profileId) async {
    final row = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(profileId)))
        .getSingle();
    await _outbox.enqueue(
      userId: userId,
      entityType: EntityTypes.profile,
      entityId: profileId,
      operation: SyncOps.create,
      payload: {
        'id': row.id,
        'userId': row.userId,
        'name': row.name,
        'initials': row.initials,
        'age': row.age,
        'bloodType': row.bloodType,
        'height': row.height,
        'patientId': row.patientId,
        'hba1c': row.hba1c,
        'bpAvg': row.bpAvg,
        'weight': row.weight,
        'allergies': row.allergies,
        'emergencyName': row.emergencyName,
        'emergencyRelation': row.emergencyRelation,
        'emergencyPhone': row.emergencyPhone,
        'updatedAt': row.updatedAt.toIso8601String(),
        'syncStatus': row.syncStatus,
        'deletedAt': null,
      },
    );
  }
}
