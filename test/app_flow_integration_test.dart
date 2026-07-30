import 'package:careplus/database/app_database.dart';
import 'package:careplus/main.dart';
import 'package:careplus/models/models.dart';
import 'package:careplus/providers/providers.dart';
import 'package:careplus/repositories/care_repository.dart';
import 'package:careplus/sync/outbox_service.dart';
import 'package:careplus/sync/sync_constants.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

class _AuthedNotifier extends AuthNotifier {
  @override
  bool build() => true;
}

class _OnboardedNotifier extends OnboardingNotifier {
  @override
  bool build() => true;
}

class _ScreenNotifier extends ScreenNotifier {
  _ScreenNotifier(this.initial);
  final String initial;
  @override
  String build() => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App shell (Drift-primary, signed-in)', () {
    late AppDatabase db;

    setUp(() {
      db = _memoryDb();
    });

    tearDown(() async {
      await db.close();
    });

    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      String uid = 'user-a',
      String screen = 'meds',
    }) async {
      final view = tester.view;
      view.physicalSize = const Size(390, 844);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      // Home has known tight-layout overflows in tests; ignore those only.
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('A RenderFlex overflowed')) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            currentUserIdProvider.overrideWithValue(uid),
            authProvider.overrideWith(_AuthedNotifier.new),
            onboardingProvider.overrideWith(_OnboardedNotifier.new),
            sessionBootstrapProvider.overrideWith((ref) async {}),
            screenProvider.overrideWith(() => _ScreenNotifier(screen)),
          ],
          child: const CarePlusApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      return ProviderScope.containerOf(
        tester.element(find.byType(CarePlusApp)),
      );
    }

    testWidgets('signed-in shell reaches medications from Drift', (
      tester,
    ) async {
      await db
          .into(db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: 'm1',
              userId: 'user-a',
              name: 'Metformin',
              dose: '500 mg',
              condition: 'Type 2 Diabetes',
              refills: 2,
              updatedAt: DateTime.now().toUtc(),
              syncStatus: const Value(SyncStatuses.synced),
            ),
          );

      await pumpApp(tester, screen: 'meds');

      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Metformin'), findsWidgets);
      expect(find.text('Type 2 Diabetes'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('journal add writes Drift, shows in UI, and queues outbox', (
      tester,
    ) async {
      final container = await pumpApp(tester, screen: 'journal');

      expect(find.text('Treatment Journal'), findsOneWidget);
      expect(find.text('No journal entries yet'), findsOneWidget);

      await container
          .read(careRepositoryProvider)
          .addJournal(
            'user-a',
            JournalEntry(
              id: 'j1',
              type: 'Visit',
              date: '28 JUL',
              facility: 'Kigali Hospital',
              title: 'Annual checkup',
              person: 'Dr. Uwimana',
              note: 'Stable',
              tags: const [],
              icon: Icons.medical_services,
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Annual checkup'), findsOneWidget);
      expect(find.text('Kigali Hospital'), findsOneWidget);

      final pending = await container
          .read(outboxServiceProvider)
          .pending('user-a');
      expect(
        pending.any((p) => p.entityType == EntityTypes.journalEntries),
        isTrue,
      );

      // Unmount so Drift stream cancel timers can flush.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('user B medications are not shown for user A session', (
      tester,
    ) async {
      await db
          .into(db.medications)
          .insert(
            MedicationsCompanion.insert(
              id: 'other',
              userId: 'user-b',
              name: 'Secret Med',
              dose: '1 mg',
              condition: 'Private',
              refills: 0,
              updatedAt: DateTime.now().toUtc(),
              syncStatus: const Value(SyncStatuses.synced),
            ),
          );

      await pumpApp(tester, uid: 'user-a', screen: 'meds');
      expect(find.text('Secret Med'), findsNothing);
      expect(find.text('Medications'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('bottom nav switches records screen', (tester) async {
      await pumpApp(tester, screen: 'meds');
      await tester.tap(find.text('Records'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Medical Records'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });

  group('Multi-entity Drift flow (repository integration)', () {
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

    test('full care loop stays user-scoped and queues sync outbox', () async {
      const uid = 'patient-1';

      await repo.addReminder(
        uid,
        Reminder(
          id: 'r1',
          medicationName: 'Atorvastatin',
          time: const TimeOfDay(hour: 21, minute: 0),
          days: List.filled(7, true),
        ),
      );
      await repo.addJournal(
        uid,
        JournalEntry(
          id: 'j1',
          type: 'Lab',
          date: '28 JUL',
          facility: 'LabCorp',
          title: 'HbA1c panel',
          person: 'Lab tech',
          note: '',
          tags: const ['lab'],
          icon: Icons.science,
        ),
      );
      await repo.addDocument(
        uid,
        MedicalDocument(
          id: 'd1',
          icon: Icons.description,
          name: 'Labs.pdf',
          source: 'OCR',
          ocrText: 'HbA1c: 6.8%',
        ),
      );
      final token = await repo.generateShareToken(uid, 'Dr. Niyonsaba');
      await repo.addCaregiver(
        uid,
        Caregiver(
          id: 'c1',
          name: 'Grace',
          relation: 'Spouse',
          phone: '+250',
          role: CaregiverRole.viewOnly,
        ),
      );

      expect(await repo.watchReminders(uid).first, hasLength(1));
      expect(await repo.watchJournal(uid).first, hasLength(1));
      expect(await repo.watchDocuments(uid).first, hasLength(1));
      expect(await repo.watchShareTokens(uid).first, hasLength(1));
      expect(await repo.watchCaregivers(uid).first, hasLength(1));
      expect(token.doctorName, 'Dr. Niyonsaba');

      expect(await repo.watchReminders('other').first, isEmpty);
      expect(await repo.watchJournal('other').first, isEmpty);
      expect(await repo.watchDocuments('other').first, isEmpty);

      final pending = await outbox.pending(uid);
      expect(pending, isNotEmpty);
      expect(pending.every((p) => p.userId == uid), isTrue);
      expect(await outbox.pending('other'), isEmpty);
    });
  });
}
