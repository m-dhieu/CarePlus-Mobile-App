import 'package:careplus/database/app_database.dart';
import 'package:careplus/main.dart';
import 'package:careplus/providers/providers.dart';
import 'package:careplus/sync/sync_constants.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// device/Chrome smoke: signed-in shell + Drift-backed meds list.
///
/// Run:
///   flutter test -d chrome
///   flutter test -d android
///   flutter test -d ios
class _AuthedNotifier extends AuthNotifier {
  @override
  bool build() => true;
}

class _OnboardedNotifier extends OnboardingNotifier {
  @override
  bool build() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Care+ signed-in shell loads Drift medications', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.medications)
        .insert(
          MedicationsCompanion.insert(
            id: 'm-int',
            userId: 'integration-user',
            name: 'Lisinopril',
            dose: '10 mg',
            condition: 'Hypertension',
            refills: 4,
            updatedAt: DateTime.now().toUtc(),
            syncStatus: const Value(SyncStatuses.synced),
          ),
        );

    final view = tester.view;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

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
          currentUserIdProvider.overrideWithValue('integration-user'),
          authProvider.overrideWith(_AuthedNotifier.new),
          onboardingProvider.overrideWith(_OnboardedNotifier.new),
          sessionBootstrapProvider.overrideWith((ref) async {}),
          screenProvider.overrideWith(_ScreenNotifier.new),
        ],
        child: const CarePlusApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Medications'), findsOneWidget);
    expect(find.text('Lisinopril'), findsWidgets);
    expect(find.text('Hypertension'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _ScreenNotifier extends ScreenNotifier {
  @override
  String build() => 'meds';
}
