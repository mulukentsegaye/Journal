import 'package:flutter/material.dart';

/// Design tokens extracted from the Daily Reflection Figma.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color background = Color(0xFFFAF6F1); // warm cream
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5EFE8);

  // ── Primary accent (salmon / terracotta) ─────────────────────
  static const Color primary = Color(0xFFC27B62);
  static const Color primaryLight = Color(0xFFD4936E);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2319);
  static const Color textSecondary = Color(0xFF7A7067);
  static const Color textHint = Color(0xFFB0A89F);

  // ── Badges & tags ────────────────────────────────────────────
  static const Color streakBadgeBg = Color(0xFFF3EDE7);
  static const Color streakBadgeText = Color(0xFF6B5D50);
  static const Color calmTagBg = Color(0xFFE8F0E4);
  static const Color calmTagText = Color(0xFF5A7A52);

  // ── Reflection dot ──────────────────────────────────────────
  static const Color reflectionDot = Color(0xFFC27B62);

  // ── Navigation ──────────────────────────────────────────────
  static const Color navActive = Color(0xFFC27B62);
  static const Color navInactive = Color(0xFFB0A89F);

  // ── Misc ────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE8E2DB);
  static const Color shadow = Color(0x0A000000);
}
