import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          error: AppColors.error,
          onError: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: AppTextStyles.displayLg,
          displayMedium: AppTextStyles.displayMd,
          displaySmall: AppTextStyles.displaySm,
          headlineLarge: AppTextStyles.headlineLg,
          headlineMedium: AppTextStyles.headlineMd,
          headlineSmall: AppTextStyles.headlineSm,
          titleLarge: AppTextStyles.titleLg,
          titleMedium: AppTextStyles.titleMd,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.bodyMd,
          bodySmall: AppTextStyles.bodySm,
          labelLarge: AppTextStyles.labelLg,
          labelSmall: AppTextStyles.label,
        ),
        // No borders — tonal layering only
        cardTheme: const CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        // Inputs — surfaceContainerLow fill, no border
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          labelStyle: AppTextStyles.label,
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        // Buttons — sharp 4px radius, primary gradient color
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: AppTextStyles.labelLg.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.bodyMd,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent, // No dividers — use tonal layering
          thickness: 0,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTextStyles.headlineSm,
          foregroundColor: AppColors.onBackground,
        ),
      );
}
