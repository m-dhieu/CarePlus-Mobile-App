import 'package:flutter_test/flutter_test.dart';
import 'package:careplus/features/auth/validators.dart';

void main() {
  group('validateEmail', () {
    test('accepts a well-formed email', () {
      expect(validateEmail('ada@example.com'), isNull);
    });

    test('rejects empty input', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rejects a string with no @ or domain', () {
      expect(validateEmail('not-an-email'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('accepts passwords of 8+ characters', () {
      expect(validatePassword('password123'), isNull);
    });

    test('rejects empty input', () {
      expect(validatePassword(''), isNotNull);
    });

    test('rejects short passwords', () {
      expect(validatePassword('abc123'), isNotNull);
    });
  });

  group('validateFullName', () {
    test('accepts a real name', () {
      expect(validateFullName('Ada Lovelace'), isNull);
    });

    test('rejects empty input', () {
      expect(validateFullName(''), isNotNull);
    });
  });
}
