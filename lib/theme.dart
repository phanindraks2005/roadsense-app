import 'package:flutter/material.dart';

/// Matches style.css: blue #1a73e8 accent, Google-Maps-style light UI.
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryHover = Color(0xFF1769D1);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color border = Color(0xFFDADCE0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color panelBg = Color(0xFFF8F9FA);
  static const Color mapBg = Color(0xFFE8EAED);
  static const Color danger = Color(0xFFD93025);
  static const Color dangerBg = Color(0xFFFCE8E6);
  static const Color iconBg = Color(0xFFE8F0FE);
  static const Color dotIdle = Color(0xFF9AA0A6);
  static const Color dotActive = Color(0xFF34A853);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Arial',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
  );
}
