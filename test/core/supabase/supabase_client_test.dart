import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('supabaseUrl throws when env not loaded', () {
      expect(() => AppConfig.supabaseUrl, throwsA(isA<Error>()));
    });

    test('supabaseAnonKey throws when env not loaded', () {
      expect(() => AppConfig.supabaseAnonKey, throwsA(isA<Error>()));
    });
  });
}
