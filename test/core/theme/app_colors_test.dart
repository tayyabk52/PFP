import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is Deep Emerald #003527', () {
      expect(AppColors.primary, const Color(0xFF003527));
    });

    test('primaryGradientEnd is #064e3b', () {
      expect(AppColors.primaryGradientEnd, const Color(0xFF064e3b));
    });

    test('surface is #f9f9fc', () {
      expect(AppColors.surface, const Color(0xFFf9f9fc));
    });

    test('surfaceContainerLow is #f3f3f6', () {
      expect(AppColors.surfaceContainerLow, const Color(0xFFf3f3f6));
    });

    test('surfaceContainerHighest is #e2e2e5', () {
      expect(AppColors.surfaceContainerHighest, const Color(0xFFe2e2e5));
    });

    test('card is white', () {
      expect(AppColors.card, const Color(0xFFffffff));
    });

    test('onBackground is near-black #1a1c1e', () {
      expect(AppColors.onBackground, const Color(0xFF1a1c1e));
    });

    test('secondary charcoal is #555f70', () {
      expect(AppColors.secondary, const Color(0xFF555f70));
    });

    test('goldAccent is #e9c176', () {
      expect(AppColors.goldAccent, const Color(0xFFe9c176));
    });

    test('goldBadgeBg is #3e2b00', () {
      expect(AppColors.goldBadgeBg, const Color(0xFF3e2b00));
    });

    test('ghostBorderBase is #bfc9c3', () {
      expect(AppColors.ghostBorderBase, const Color(0xFFbfc9c3));
    });

    test('error is standard red', () {
      expect(AppColors.error, const Color(0xFFba1a1a));
    });
  });
}
