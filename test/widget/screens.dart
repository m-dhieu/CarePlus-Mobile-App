import 'package:careplus/database/app_database.dart';
import 'package:careplus/main.dart';
import 'package:careplus/providers/providers.dart';
import 'package:careplus/screens/auth_screen.dart';
import 'package:careplus/screens/caregivers_screen.dart';
import 'package:careplus/screens/emergency_access_screen.dart';
import 'package:careplus/screens/forgot_password.dart';
import 'package:careplus/screens/home_screen.dart';
import 'package:careplus/screens/journal_screen.dart';
import 'package:careplus/screens/meds_screen.dart';
import 'package:careplus/screens/metrics_screen.dart';
import 'package:careplus/screens/onboarding_screen.dart';
import 'package:careplus/screens/profile_screen.dart';
import 'package:careplus/screens/records_screen.dart';
import 'package:careplus/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

// every screen builds — smoke tests with Riverpod and memory Drift

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform shell', () {
    testWidgets('unsupported platform message renders', (tester) async {
      await tester.pumpWidget(const UnsupportedPlatformApp());
      expect(find.textContaining('Care+ supports'), findsOneWidget);
    });
  });

  group('Pre-auth screens', () {
    testWidgets('onboarding first page renders', (tester) async {
      configureTestView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(NotOnboardedNotifier.new),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Your health, unified'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('auth screen shows login and sign-up tabs', (tester) async {
      configureTestView(tester, size: const Size(430, 1400));
      ignoreFlexOverflowInTests();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(LoggedOutAuthNotifier.new),
            onboardingProvider.overrideWith(OnboardedNotifier.new),
          ],
          child: const MaterialApp(home: Scaffold(body: AuthScreen())),
        ),
      );
      await tester.pump();

      expect(find.text('Login'), findsWidgets);
      expect(find.text('Sign up'), findsWidgets);
      expect(find.text("You're welcome again"), findsOneWidget);
    });

    testWidgets('forgot password screen renders', (tester) async {
      configureTestView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(LoggedOutAuthNotifier.new)],
          child: const MaterialApp(home: ForgotPasswordScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });
  });

  group('Signed-in screens', () {
    late AppDatabase db;

    setUp(() {
      db = memoryDb();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('home screen greets the user', (tester) async {
      await pumpSignedInScreen(tester, const HomeScreen(), db: db);
      expect(find.textContaining('Hi, Alice'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('medications screen renders', (tester) async {
      await pumpSignedInScreen(tester, const MedsScreen(), db: db);
      expect(find.text('Medications'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('journal screen renders empty state', (tester) async {
      await pumpSignedInScreen(tester, const JournalScreen(), db: db);
      expect(find.text('Treatment Journal'), findsOneWidget);
      expect(find.text('No journal entries yet'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('records screen renders', (tester) async {
      await pumpSignedInScreen(tester, const RecordsScreen(), db: db);
      expect(find.text('Medical Records'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('profile screen renders', (tester) async {
      await pumpSignedInScreen(tester, const ProfileScreen(), db: db);
      expect(find.text('My Profile'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('reminders screen renders empty state', (tester) async {
      await pumpSignedInScreen(tester, const RemindersScreen(), db: db);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('No reminders yet'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('caregivers screen renders empty state', (tester) async {
      await pumpSignedInScreen(tester, const CaregiversScreen(), db: db);
      expect(find.text('Caregivers'), findsOneWidget);
      expect(find.text('No caregivers added'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('metrics screen renders empty state', (tester) async {
      await pumpSignedInScreen(tester, const MetricsScreen(), db: db);
      expect(find.text('Health Metrics'), findsOneWidget);
      expect(find.text('No metrics yet'), findsOneWidget);
      await unmountTester(tester);
    });

    testWidgets('emergency access screen renders', (tester) async {
      await pumpSignedInScreen(tester, const EmergencyAccessScreen(), db: db);
      expect(find.text('Emergency Access'), findsOneWidget);
      await unmountTester(tester);
    });
  });
}
