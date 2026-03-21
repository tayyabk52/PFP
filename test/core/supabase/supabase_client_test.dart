import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('supabaseUrl is non-empty', () {
      expect(AppConfig.supabaseUrl, isA<String>());
    });

    test('supabaseAnonKey is non-empty', () {
      expect(AppConfig.supabaseAnonKey, isA<String>());
    });
  });
}
