import 'package:flutter/material.dart';

/// Design tokens extracted from the Daily Reflection Figma.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color background = Color(0xFFFAF6F1); // warm cream
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5EFE8);

  // ── Dark Theme Backgrounds ───────────────────────────────────
  static const Color darkBackground = Color(0xFF141518);
  static const Color darkCardBackground = Color(0xFF1E2024);
  static const Color darkSurface = Color(0xFF27292F);

  // ── Primary accent (salmon / terracotta) ─────────────────────
  static const Color primary = Color(0xFFC27B62);
  static const Color primaryLight = Color(0xFFD4936E);
  static const Color darkPrimary = Color(0xFFD48B6A);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2319);
  static const Color textSecondary = Color(0xFF7A7067);
  static const Color textHint = Color(0xFFB0A89F);

  // ── Dark Text ────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF4EFEA);
  static const Color darkTextSecondary = Color(0xFFAAA196);
  static const Color darkTextHint = Color(0xFF6B645B);

  // ── Badges & tags ────────────────────────────────────────────
  static const Color streakBadgeBg = Color(0xFFF3EDE7);
  static const Color streakBadgeText = Color(0xFF6B5D50);
  static const Color calmTagBg = Color(0xFFE8F0E4);
  static const Color calmTagText = Color(0xFF5A7A52);

  // ── Dark Badges & tags ───────────────────────────────────────
  static const Color darkStreakBadgeBg = Color(0xFF2C2622);
  static const Color darkStreakBadgeText = Color(0xFFDEAA95);
  static const Color darkCalmTagBg = Color(0xFF1C271E);
  static const Color darkCalmTagText = Color(0xFF90B598);

  // ── Reflection dot ──────────────────────────────────────────
  static const Color reflectionDot = Color(0xFFC27B62);

  // ── Navigation ──────────────────────────────────────────────
  static const Color navActive = Color(0xFFC27B62);
  static const Color navInactive = Color(0xFFB0A89F);

  // ── Misc ────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE8E2DB);
  static const Color darkDivider = Color(0xFF2F3238);
  static const Color shadow = Color(0x0A000000);
}
