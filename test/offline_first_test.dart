import 'dart:convert';

import 'package:careplus/database/app_database.dart';
import 'package:careplus/database/mappers.dart';
import 'package:careplus/models/models.dart';
import 'package:careplus/repositories/care_repository.dart';
import 'package:careplus/repositories/seed_service.dart';
import 'package:careplus/sync/outbox_service.dart';
import 'package:careplus/sync/sync_constants.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('Sync constants', () {
    test('entity type list covers core collections', () {
      expect(EntityTypes.all, contains(EntityTypes.medications));
      expect(EntityTypes.all, contains(EntityTypes.reminders));
      expect(EntityTypes.all, contains(EntityTypes.journalEntries));
      expect(EntityTypes.all, contains(EntityTypes.profile));
      expect(SyncStatuses.pending, 'pending');
      expect(SyncStatuses.synced, 'synced');
      expect(SyncOps.create, 'create');
      expect(SyncMetaKeys.seeded, 'seeded');
    });
  });

  group('Mappers', () {
    test('medicationFromRow maps domain fields', () {
      final now = DateTime.utc(2026, 7, 25);
      final row = MedicationRow(
        id: 'm1',
        userId: 'u1',
        name: 'Metformin',
        dose: '500 mg',
        condition: 'Diabetes',
        refills: 2,
        updatedAt: now,
        syncStatus: SyncStatuses.synced,
        deletedAt: null,
      );
      final med = medicationFromRow(row);
      expect(med.id, 'm1');
      expect(med.name, 'Metformin');
      expect(med.dose, '500 mg');
      expect(med.refills, 2);
    });

    test('reminderFromRow decodes days JSON and time', () {
      final now = DateTime.utc(2026, 7, 25);
      final row = ReminderRow(
        id: 'r1',
        userId: 'u1',
        medicationName: 'Lisinopril',
        hour: 13,
        minute: 30,
        days: jsonEncode([true, true, false, false, false, false, false]),
        enabled: true,
        updatedAt: now,
        syncStatus: SyncStatuses.pending,
        deletedAt: null,
      );
      final reminder = reminderFromRow(row);
      expect(reminder.time, const TimeOfDay(hour: 13, minute: 30));
      expect(reminder.days, [true, true, false, false, false, false, false]);
      expect(reminder.enabled, isTrue);
    });

    test('caregiverFromRow maps role enum', () {
      final now = DateTime.utc(2026, 7, 25);
      final row = CaregiverRow(
        id: 'c1',
        userId: 'u1',
        name: 'Grace',
        relation: 'Spouse',
        phone: '+250',
        role: 'fullAccess',
        notificationsEnabled: true,
        updatedAt: now,
        syncStatus: SyncStatuses.synced,
        deletedAt: null,
      );
      final caregiver = caregiverFromRow(row);
      expect(caregiver.role, CaregiverRole.fullAccess);
      expect(caregiver.notificationsEnabled, isTrue);
    });

    test('metricsFromRows groups and sorts by date', () {
      final now = DateTime.utc(2026, 7, 25);
      final rows = [
        MetricPointRow(
          id: 'a',
          userId: 'u1',
          seriesKey: 'glucose',
          label: 'Blood Glucose',
          unit: 'mg/dL',
          date: now.add(const Duration(days: 7)),
          value: 120,
          updatedAt: now,
          syncStatus: SyncStatuses.synced,
          deletedAt: null,
        ),
        MetricPointRow(
          id: 'b',
          userId: 'u1',
          seriesKey: 'glucose',
          label: 'Blood Glucose',
          unit: 'mg/dL',
          date: now,
          value: 110,
          updatedAt: now,
          syncStatus: SyncStatuses.synced,
          deletedAt: null,
        ),
      ];
      final series = metricsFromRows(rows);
      expect(series.keys, ['glucose']);
      expect(series['glucose']!.points.map((p) => p.value), [110, 120]);
      expect(series['glucose']!.latest, 120);
    });
  });

  group('OutboxService', () {
    late AppDatabase db;
    late OutboxService outbox;

    setUp(() {
      db = _memoryDb();
      outbox = OutboxService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueue stores pending mutation', () async {
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.medications,
        entityId: 'm1',
        operation: SyncOps.create,
        payload: {'id': 'm1', 'name': 'Metformin'},
      );

      final pending = await outbox.pending('u1');
      expect(pending, hasLength(1));
      expect(pending.first.entityId, 'm1');
      expect(pending.first.operation, SyncOps.create);
      expect(jsonDecode(pending.first.payloadJson)['name'], 'Metformin');
    });

    test('enqueue coalesces ops for the same entity', () async {
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.reminders,
        entityId: 'r1',
        operation: SyncOps.create,
        payload: {'enabled': true},
      );
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.reminders,
        entityId: 'r1',
        operation: SyncOps.update,
        payload: {'enabled': false},
      );

      final pending = await outbox.pending('u1');
      expect(pending, hasLength(1));
      expect(pending.first.operation, SyncOps.update);
      expect(jsonDecode(pending.first.payloadJson)['enabled'], isFalse);
    });

    test('remove and removeForEntity clear queue entries', () async {
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.documents,
        entityId: 'd1',
        operation: SyncOps.create,
        payload: {'id': 'd1'},
      );
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.documents,
        entityId: 'd2',
        operation: SyncOps.create,
        payload: {'id': 'd2'},
      );

      final all = await outbox.pending('u1');
      await outbox.remove(all.first.id);
      expect(await outbox.pending('u1'), hasLength(1));

      await outbox.removeForEntity(
        userId: 'u1',
        entityType: EntityTypes.documents,
        entityId: 'd2',
      );
      expect(await outbox.pending('u1'), isEmpty);
    });

    test('markAttempt increments attempts and stores error', () async {
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.caregivers,
        entityId: 'c1',
        operation: SyncOps.update,
        payload: {'id': 'c1'},
      );
      final id = (await outbox.pending('u1')).first.id;
      await outbox.markAttempt(id, 'network down');
      final row = (await outbox.pending('u1')).first;
      expect(row.attempts, 1);
      expect(row.lastError, 'network down');
    });

    test('pending is scoped by userId', () async {
      await outbox.enqueue(
        userId: 'u1',
        entityType: EntityTypes.medications,
        entityId: 'm1',
        operation: SyncOps.create,
        payload: {'id': 'm1'},
      );
      await outbox.enqueue(
        userId: 'u2',
        entityType: EntityTypes.medications,
        entityId: 'm2',
        operation: SyncOps.create,
        payload: {'id': 'm2'},
      );

      expect(await outbox.pending('u1'), hasLength(1));
      expect(await outbox.pending('u2'), hasLength(1));
      expect((await outbox.pending('u1')).first.entityId, 'm1');
    });
  });

  group('CareRepository', () {
    late AppDatabase db;
    late OutboxService outbox;
    late CareRepository repo;
    var dirtyCalls = 0;

    setUp(() async {
      db = _memoryDb();
      outbox = OutboxService(db);
      dirtyCalls = 0;
      repo = CareRepository(db, outbox, onDirty: () => dirtyCalls++);

      await db
          .into(db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: 'm1',
              userId: 'u1',
              name: 'Metformin',
              dose: '500 mg',
              condition: 'Diabetes',
              refills: 2,
              updatedAt: DateTime.now().toUtc(),
              syncStatus: const Value(SyncStatuses.synced),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('requestRefill bumps count, marks pending, enqueues outbox', () async {
      await repo.requestRefill('u1', 'm1');

      final row = await (db.select(
        db.medications,
      )..where((t) => t.id.equals('m1'))).getSingle();
      expect(row.refills, 3);
      expect(row.syncStatus, SyncStatuses.pending);

      final pending = await outbox.pending('u1');
      expect(pending, hasLength(1));
      expect(pending.first.entityType, EntityTypes.medications);
      expect(pending.first.operation, SyncOps.update);
      expect(dirtyCalls, 1);
    });

    test('addReminder persists locally and queues create', () async {
      await repo.addReminder(
        'u1',
        Reminder(
          id: 'r1',
          medicationName: 'Atorvastatin',
          time: const TimeOfDay(hour: 21, minute: 30),
          days: List.filled(7, true),
        ),
      );

      final reminders = await repo.watchReminders('u1').first;
      expect(reminders, hasLength(1));
      expect(reminders.first.medicationName, 'Atorvastatin');
      expect(reminders.first.time.hour, 21);

      final pending = await outbox.pending('u1');
      expect(pending.any((p) => p.entityType == EntityTypes.reminders), isTrue);
      expect(dirtyCalls, greaterThanOrEqualTo(1));
    });

    test('removeReminder soft-deletes and hides from watch', () async {
      await repo.addReminder(
        'u1',
        Reminder(
          id: 'r2',
          medicationName: 'Vitamin D',
          time: const TimeOfDay(hour: 8, minute: 0),
          days: List.filled(7, true),
        ),
      );
      await repo.removeReminder('u1', 'r2');

      final visible = await repo.watchReminders('u1').first;
      expect(visible.where((r) => r.id == 'r2'), isEmpty);

      final tombstone = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r2'))).getSingle();
      expect(tombstone.deletedAt, isNotNull);
      expect(tombstone.syncStatus, SyncStatuses.pending);
    });

    test('toggleReminder flips enabled flag', () async {
      await repo.addReminder(
        'u1',
        Reminder(
          id: 'r3',
          medicationName: 'Lisinopril',
          time: const TimeOfDay(hour: 13, minute: 0),
          days: List.filled(7, true),
          enabled: true,
        ),
      );
      await repo.toggleReminder('u1', 'r3');

      final reminders = await repo.watchReminders('u1').first;
      expect(reminders.firstWhere((r) => r.id == 'r3').enabled, isFalse);
    });
  });

  group('SeedService', () {
    late AppDatabase db;
    late OutboxService outbox;
    late SeedService seed;

    setUp(() {
      db = _memoryDb();
      outbox = OutboxService(db);
      seed = SeedService(db, outbox);
    });

    tearDown(() async {
      await db.close();
    });

    test('seedIfNeeded does not insert demo data (real-data mode)', () async {
      await seed.seedIfNeeded('user-a');

      expect(
        await (db.select(
          db.medications,
        )..where((t) => t.userId.equals('user-a'))).get(),
        isEmpty,
      );
      expect(
        await (db.select(
          db.userProfiles,
        )..where((t) => t.userId.equals('user-a'))).get(),
        isEmpty,
      );
      expect(await outbox.pending('user-a'), isEmpty);
    });
  });

  group('CareRepository journal + documents (Drift primary)', () {
    late AppDatabase db;
    late OutboxService outbox;
    late CareRepository repo;

    setUp(() {
      db = _memoryDb();
      outbox = OutboxService(db);
      repo = CareRepository(db, outbox, onDirty: () {});
    });

    tearDown(() async {
      await db.close();
    });

    test('addJournal writes Drift and enqueues outbox', () async {
      await repo.addJournal(
        'u1',
        JournalEntry(
          id: 'j1',
          type: 'Visit',
          date: '28 JUL',
          facility: 'Kigali Hospital',
          title: 'Checkup',
          person: 'Dr. A',
          note: 'All good',
          tags: const ['routine'],
          icon: Icons.medical_services,
        ),
      );

      final entries = await repo.watchJournal('u1').first;
      expect(entries, hasLength(1));
      expect(entries.first.title, 'Checkup');
      expect(
        (await outbox.pending(
          'u1',
        )).any((p) => p.entityType == EntityTypes.journalEntries),
        isTrue,
      );
    });

    test('addDocument and updateDocumentOcr stay local-first', () async {
      await repo.addDocument(
        'u1',
        MedicalDocument(
          id: 'd1',
          icon: Icons.description,
          name: 'Labs.pdf',
          source: 'OCR',
        ),
      );
      await repo.updateDocumentOcr('u1', 'd1', 'HbA1c: 6.8%');

      final docs = await repo.watchDocuments('u1').first;
      expect(docs, hasLength(1));
      expect(docs.first.ocrText, 'HbA1c: 6.8%');
      expect(await outbox.pending('u1'), isNotEmpty);
    });

    test('generateShareToken persists in Drift', () async {
      final token = await repo.generateShareToken('u1', 'Dr. Smith');
      final tokens = await repo.watchShareTokens('u1').first;
      expect(tokens, hasLength(1));
      expect(tokens.first.doctorName, 'Dr. Smith');
      expect(tokens.first.token, token.token);
    });
  });
}
