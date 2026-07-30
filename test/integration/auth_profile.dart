import 'package:careplus/providers/providers.dart';
import 'package:careplus/screens/auth_screen.dart';
import 'package:careplus/screens/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

// auth + profile wiring — sign-up fields and password reset reach the notifier

class _RegisterCall {
  const _RegisterCall({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;
}

_RegisterCall? _lastRegisterCall;
String? _lastResetEmail;

class _RegisterAuthNotifier extends AuthNotifier {
  @override
  bool build() => false;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _lastRegisterCall = _RegisterCall(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }
}

class _ResetAuthNotifier extends AuthNotifier {
  @override
  bool build() => false;

  @override
  Future<void> sendPasswordReset(String email) async {
    _lastResetEmail = email;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _lastRegisterCall = null;
    _lastResetEmail = null;
  });

  testWidgets('sign up submits full name and phone through register', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(430, 1400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_RegisterAuthNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: AuthScreen())),
      ),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Alice Uwimana');
    await tester.enterText(find.byType(TextField).at(1), '+250 788 000 000');
    await tester.enterText(find.byType(TextField).at(2), 'alice@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.enterText(find.byType(TextField).at(4), 'secret123');

    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign up').first;
    await tester.tap(signUpButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(_lastRegisterCall, isNotNull);
    expect(_lastRegisterCall!.email, 'alice@example.com');
    expect(_lastRegisterCall!.password, 'secret123');
    expect(_lastRegisterCall!.fullName, 'Alice Uwimana');
    expect(_lastRegisterCall!.phone, '+250 788 000 000');

    await tester.pump(const Duration(milliseconds: 2500));
    await unmountTester(tester);
  });

  testWidgets('forgot password sends reset email through auth provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_ResetAuthNotifier.new)],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'patient@example.com',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pump();

    expect(_lastResetEmail, 'patient@example.com');
    expect(find.textContaining('Password reset email sent'), findsOneWidget);
  });
}
