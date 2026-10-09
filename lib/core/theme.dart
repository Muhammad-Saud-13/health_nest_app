import 'package:flutter/material.dart';

/// App color tokens extracted from Google Stitch mockups (`ui_design/`).
/// All screen widgets MUST use these named constants instead of hardcoding hex values.
class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF1C27D6);
  static const Color primaryDark = Color(0xFF151D9E);
  static const Color primarySoft = Color(0xFFEEF0FF);

  // Background & Surface
  static const Color canvasBackground = Color(0xFFEDF0F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Typography Colors (High contrast, industrial legibility)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFD5DCEB);

  // Status & Vitals Colors (Never used alone — always paired with Icon + Text)
  // Calm State
  static const Color stateCalm = Color(0xFF15803D);
  static const Color stateCalmBg = Color(0xFFDCFCE7);
  static const Color stateCalmBorder = Color(0xFFBBF7D0);

  // Stressed State
  static const Color stateStressed = Color(0xFFC2410C);
  static const Color stateStressedBg = Color(0xFFFFEDD5);
  static const Color stateStressedBorder = Color(0xFFFED7AA);

  // Getting Ready / Pending Baseline Status
  static const Color stateGettingReady = Color(0xFFB45309);
  static const Color stateGettingReadyBg = Color(0xFFFEF3C7);
  static const Color stateGettingReadyBorder = Color(0xFFFDE68A);

  // Destructive / High Severity Alert
  static const Color error = Color(0xFFB91C1C);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFFECACA);
}

/// App theme defining cohesive colors, typography, and button styles.
/// Optimized for readability (NFR-4.1) and accessibility (NFR-4.4).
class AppTheme {
  // Geometry Tokens
  static const double minTouchTargetHeight = 56.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Convenient Aliases to AppColors
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryBlue = AppColors.primary;
  static const Color stateCalm = AppColors.stateCalm;
  static const Color stateStressed = AppColors.stateStressed;
  static const Color surfaceWhite = AppColors.surfaceWhite;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color borderSubtle = AppColors.borderSubtle;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvasBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surfaceWhite,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, minTouchTargetHeight), // Min 56px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        color: AppColors.surfaceWhite,
      ),
    );
  }
}
