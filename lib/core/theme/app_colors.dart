import 'package:flutter/material.dart';

/// Olfactory Archive design system color tokens.
/// No borders — use tonal layering (surface → surfaceContainerLow → card).
abstract class AppColors {
  // Primary
  static const Color primary = Color(0xFF003527);
  static const Color primaryGradientEnd = Color(0xFF064e3b);
  static const Color onPrimary = Color(0xFFffffff);

  // Secondary
  static const Color secondary = Color(0xFF555f70);
  static const Color onSecondary = Color(0xFFffffff);

  // Gold accent — use sparingly (verified badges, heritage chips)
  static const Color goldAccent = Color(0xFFe9c176);
  static const Color goldBadgeBg = Color(0xFF3e2b00);
  static const Color onGoldBadge = Color(0xFF261900);

  // Surface hierarchy (tonal layering — no borders)
  static const Color surface = Color(0xFFf9f9fc);
  static const Color surfaceContainerLow = Color(0xFFf3f3f6);
  static const Color surfaceContainerHighest = Color(0xFFe2e2e5);
  static const Color card = Color(0xFFffffff);

  // Text
  static const Color onBackground = Color(0xFF1a1c1e);
  static const Color onSurface = Color(0xFF1a1c1e);
  static const Color textSecondary = Color(0xFF555f70);
  static const Color textMuted = Color(0xFF8a9390);

  // Ghost border — only at 15% opacity, accessibility only
  static const Color ghostBorderBase = Color(0xFFbfc9c3);
  static Color get ghostBorder => ghostBorderBase.withOpacity(0.15);

  // Status
  static const Color error = Color(0xFFba1a1a);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color success = Color(0xFF1a6b4a);
  static const Color successContainer = Color(0xFFbcf0d7);
  static const Color warning = Color(0xFFb45300);
  static const Color warningContainer = Color(0xFFffe0bb);
}
