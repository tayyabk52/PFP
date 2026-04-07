import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/theme/app_text_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // google_fonts fires background font-loading async errors in unit tests
  // (no network, no bundled fonts). Capture and discard them so the
  // synchronous property assertions below can report clean pass/fail.
  // ignore: no_leading_underscores_for_local_identifiers
  T _get<T>(T Function() fn) {
    late T result;
    runZonedGuarded(
      () => result = fn(),
      (_, __) {}, // swallow async font-load errors
    );
    return result;
  }

  group('AppTextStyles', () {
    test('displayLg uses Noto Serif', () {
      final style = _get(() => AppTextStyles.displayLg);
      expect(style.fontFamily, contains('NotoSerif'));
    });

    test('displayLg is 56sp', () {
      final style = _get(() => AppTextStyles.displayLg);
      expect(style.fontSize, 56.0);
    });

    test('bodyMd uses Inter', () {
      final style = _get(() => AppTextStyles.bodyMd);
      expect(style.fontFamily, contains('Inter'));
    });

    test('label has uppercase letter spacing', () {
      final style = _get(() => AppTextStyles.label);
      expect(style.letterSpacing, greaterThan(0));
    });
  });
}
