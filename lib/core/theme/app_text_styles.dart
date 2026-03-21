import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Olfactory Archive typography system.
/// Display/Headlines: Noto Serif (editorial weight)
/// Body/Labels: Inter (clean, functional)
abstract class AppTextStyles {
  // --- Display (Noto Serif) — fragrance names, hero headers ---
  static TextStyle get displayLg => GoogleFonts.notoSerif(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMd => GoogleFonts.notoSerif(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.15,
        letterSpacing: -0.25,
      );

  static TextStyle get displaySm => GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.2,
      );

  // --- Headlines (Noto Serif) — section titles ---
  static TextStyle get headlineLg => GoogleFonts.notoSerif(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.25,
      );

  static TextStyle get headlineMd => GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.3,
      );

  static TextStyle get headlineSm => GoogleFonts.notoSerif(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.3,
      );

  // --- Title (Noto Serif) — card titles ---
  static TextStyle get titleLg => GoogleFonts.notoSerif(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.4,
      );

  static TextStyle get titleMd => GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackground,
        height: 1.4,
      );

  static TextStyle get titleSm => GoogleFonts.notoSerif(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackground,
        height: 1.4,
      );

  // --- Body (Inter) — descriptions, functional text ---
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.6,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // --- Label (Inter, UPPERCASE) — field labels, chips, metadata ---
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
        height: 1.4,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.4,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // --- Price — primary color for pricing display ---
  static TextStyle get price => GoogleFonts.notoSerif(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceSm => GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );
}
