import 'package:flutter_test/flutter_test.dart';
import 'package:careplus/features/auth/validators.dart';

void main() {
  group('validatePhone', () {
    test('accepts E.164 formatted numbers', () {
      expect(validatePhone('+250788123456'), isNull);
    });

    test('rejects empty input', () {
      expect(validatePhone(''), isNotNull);
    });

    test('rejects numbers without a country code', () {
      expect(validatePhone('0788123456'), isNotNull);
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

  group('validateOtpCode', () {
    test('accepts a 6-digit code', () {
      expect(validateOtpCode('123456'), isNull);
    });

    test('rejects a code with the wrong length', () {
      expect(validateOtpCode('123'), isNotNull);
    });

    test('rejects non-numeric input', () {
      expect(validateOtpCode('abcdef'), isNotNull);
    });
  });
}
