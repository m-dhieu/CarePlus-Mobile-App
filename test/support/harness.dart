import 'package:careplus/database/app_database.dart';
import 'package:careplus/main.dart';
import 'package:careplus/models/models.dart';
import 'package:careplus/providers/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart';

// shared test helpers — memory Drift, signed-in overrides, viewport tweaks

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

void configureTestView(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1.0;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
}

void ignoreFlexOverflowInTests() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('A RenderFlex overflowed')) return;
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

class AuthedNotifier extends AuthNotifier {
  @override
  bool build() => true;
}

class LoggedOutAuthNotifier extends AuthNotifier {
  @override
  bool build() => false;
}

class OnboardedNotifier extends OnboardingNotifier {
  @override
  bool build() => true;
}

class NotOnboardedNotifier extends OnboardingNotifier {
  @override
  bool build() => false;
}

class TestScreenNotifier extends ScreenNotifier {
  TestScreenNotifier(this.initial);
  final String initial;

  @override
  String build() => initial;
}

const testUserProfile = UserProfile(
  name: 'Alice Patient',
  initials: 'AP',
  phone: '+250788000000',
  age: 32,
  bloodType: 'O+',
  height: '170 cm',
  patientId: 'CP-TEST',
  hba1c: '6.8%',
  bpAvg: '118/77',
  weight: '65 kg',
  allergies: [],
  emergencyContact: EmergencyContact(
    name: 'Grace',
    relation: 'Sister',
    phone: '+250700000000',
  ),
);

class TestUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfile build() => testUserProfile;
}

List<Override> signedInOverrides({
  required AppDatabase db,
  String uid = 'test-user',
  String screen = 'home',
}) {
  return [
    databaseProvider.overrideWithValue(db),
    currentUserIdProvider.overrideWithValue(uid),
    authProvider.overrideWith(AuthedNotifier.new),
    onboardingProvider.overrideWith(OnboardedNotifier.new),
    sessionBootstrapProvider.overrideWith((ref) async {}),
    userProfileProvider.overrideWith(TestUserProfileNotifier.new),
    screenProvider.overrideWith(() => TestScreenNotifier(screen)),
  ];
}

Future<ProviderContainer> pumpSignedInApp(
  WidgetTester tester, {
  required AppDatabase db,
  String uid = 'test-user',
  String screen = 'home',
}) async {
  configureTestView(tester);
  ignoreFlexOverflowInTests();

  await tester.pumpWidget(
    ProviderScope(
      overrides: signedInOverrides(db: db, uid: uid, screen: screen),
      child: const CarePlusApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return ProviderScope.containerOf(tester.element(find.byType(CarePlusApp)));
}

Future<void> pumpSignedInScreen(
  WidgetTester tester,
  Widget screen, {
  AppDatabase? db,
  String uid = 'widget-user',
}) async {
  final database = db ?? memoryDb();
  if (db == null) addTearDown(database.close);

  configureTestView(tester);
  ignoreFlexOverflowInTests();

  await tester.pumpWidget(
    ProviderScope(
      overrides: signedInOverrides(db: database, uid: uid),
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> unmountTester(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}
