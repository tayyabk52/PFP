import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.validateDisplayName', () {
    test('null returns required error', () {
      expect(AuthRepository.validateDisplayName(null), isNotNull);
    });
    test('empty returns required error', () {
      expect(AuthRepository.validateDisplayName(''), isNotNull);
    });
    test('1 char returns too short error', () {
      expect(AuthRepository.validateDisplayName('a'), isNotNull);
    });
    test('2 chars is valid', () {
      expect(AuthRepository.validateDisplayName('Al'), isNull);
    });
    test('51 chars returns too long error', () {
      expect(AuthRepository.validateDisplayName('a' * 51), isNotNull);
    });
    test('50 chars is valid', () {
      expect(AuthRepository.validateDisplayName('a' * 50), isNull);
    });
  });

  group('AuthRepository.validateEmail', () {
    test('null returns required error', () {
      expect(AuthRepository.validateEmail(null), isNotNull);
    });
    test('no @ returns invalid error', () {
      expect(AuthRepository.validateEmail('notanemail'), isNotNull);
    });
    test('valid email returns null', () {
      expect(AuthRepository.validateEmail('user@example.com'), isNull);
    });
  });

  group('AuthRepository.validatePassword', () {
    test('null returns required error', () {
      expect(AuthRepository.validatePassword(null), isNotNull);
    });
    test('7 chars returns too short error', () {
      expect(AuthRepository.validatePassword('short12'), isNotNull);
    });
    test('8 chars is valid', () {
      expect(AuthRepository.validatePassword('validpa1'), isNull);
    });
  });

  group('AuthRepository.validatePhone', () {
    test('null is valid (field is optional)', () {
      expect(AuthRepository.validatePhone(null), isNull);
    });
    test('empty string is valid (treated as not provided)', () {
      expect(AuthRepository.validatePhone(''), isNull);
    });
    test('+923001234567 is valid', () {
      expect(AuthRepository.validatePhone('+923001234567'), isNull);
    });
    test('+923211234567 is valid', () {
      expect(AuthRepository.validatePhone('+923211234567'), isNull);
    });
    test('03001234567 is invalid (missing country code)', () {
      expect(AuthRepository.validatePhone('03001234567'), isNotNull);
    });
    test('+923 with 8 extra digits is invalid (too short)', () {
      expect(AuthRepository.validatePhone('+923012345'), isNotNull);
    });
    test('+923 with 10 extra digits is invalid (too long)', () {
      expect(AuthRepository.validatePhone('+9230012345678'), isNotNull);
    });
    test('starts with +921 is invalid (not mobile)', () {
      expect(AuthRepository.validatePhone('+921001234567'), isNotNull);
    });
  });

  group('AuthRepository.normalizePhone', () {
    test('null returns null', () {
      expect(AuthRepository.normalizePhone(null), isNull);
    });
    test('empty returns null', () {
      expect(AuthRepository.normalizePhone(''), isNull);
    });
    test('03001234567 normalizes to +923001234567', () {
      expect(AuthRepository.normalizePhone('03001234567'), '+923001234567');
    });
    test('+923001234567 stays unchanged', () {
      expect(AuthRepository.normalizePhone('+923001234567'), '+923001234567');
    });
  });
}
