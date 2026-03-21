import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/features/auth/providers/auth_provider.dart';
import 'package:pfc_app/features/auth/providers/profile_provider.dart';

void main() {
  group('Auth providers', () {
    test('authStateProvider is defined', () {
      expect(authStateProvider, isNotNull);
    });

    test('currentUserProvider is defined', () {
      expect(currentUserProvider, isNotNull);
    });

    test('userRoleProvider is defined', () {
      expect(userRoleProvider, isNotNull);
    });

    test('currentProfileProvider is defined', () {
      expect(currentProfileProvider, isNotNull);
    });

    test('hasSellerApplicationProvider is defined', () {
      expect(hasSellerApplicationProvider, isNotNull);
    });
  });
}
