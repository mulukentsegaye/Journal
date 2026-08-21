import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Design tokens extracted from the Daily Reflection design system.
/// Dynamically resolves colors based on active theme mode (Light / Dark).
class AppColors {
  AppColors._();

  static bool get _isDark => SettingsService().isDarkMode;

  // ── Light Theme Tokens ────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAF6F1); // warm cream
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5EFE8);
  static const Color lightPrimary = Color(0xFFC27B62);
  static const Color lightPrimaryLight = Color(0xFFD4936E);
  static const Color lightTextPrimary = Color(0xFF2D2319);
  static const Color lightTextSecondary = Color(0xFF7A7067);
  static const Color lightTextHint = Color(0xFFB0A89F);
  static const Color lightStreakBadgeBg = Color(0xFFF3EDE7);
  static const Color lightStreakBadgeText = Color(0xFF6B5D50);
  static const Color lightCalmTagBg = Color(0xFFE8F0E4);
  static const Color lightCalmTagText = Color(0xFF5A7A52);
  static const Color lightDivider = Color(0xFFE8E2DB);

  // ── Dark Theme Tokens (OLED / Night Sky) ──────────────────────
  static const Color darkBackground = Color(0xFF141518);
  static const Color darkCardBackground = Color(0xFF1E2024);
  static const Color darkSurface = Color(0xFF282A30);
  static const Color darkPrimary = Color(0xFFE08D6E);
  static const Color darkPrimaryLight = Color(0xFFECA386);
  static const Color darkTextPrimary = Color(0xFFF5EFE8);
  static const Color darkTextSecondary = Color(0xFFAAA196);
  static const Color darkTextHint = Color(0xFF756E65);
  static const Color darkStreakBadgeBg = Color(0xFF2C2520);
  static const Color darkStreakBadgeText = Color(0xFFE5A992);
  static const Color darkCalmTagBg = Color(0xFF1B271C);
  static const Color darkCalmTagText = Color(0xFF90C498);
  static const Color darkDivider = Color(0xFF2E3036);

  // ── Adaptive Dynamic Color Getters ────────────────────────────
  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get cardBackground => _isDark ? darkCardBackground : lightCardBackground;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get primary => _isDark ? darkPrimary : lightPrimary;
  static Color get primaryLight => _isDark ? darkPrimaryLight : lightPrimaryLight;
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => _isDark ? darkTextHint : lightTextHint;
  static Color get streakBadgeBg => _isDark ? darkStreakBadgeBg : lightStreakBadgeBg;
  static Color get streakBadgeText => _isDark ? darkStreakBadgeText : lightStreakBadgeText;
  static Color get calmTagBg => _isDark ? darkCalmTagBg : lightCalmTagBg;
  static Color get calmTagText => _isDark ? darkCalmTagText : lightCalmTagText;
  static Color get reflectionDot => _isDark ? darkPrimary : lightPrimary;
  static Color get navActive => _isDark ? darkPrimary : lightPrimary;
  static Color get navInactive => _isDark ? darkTextHint : lightTextHint;
  static Color get divider => _isDark ? darkDivider : lightDivider;
  static Color get shadow => _isDark ? const Color(0x33000000) : const Color(0x0A000000);
}
