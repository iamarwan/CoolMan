// lib/core/theme.dart
//
// The app's colours and theme in one place. Instead of typing
// Color(0xFF0F766E) everywhere, write AppColors.primary, so changing the brand
// colour is a one-line edit.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand (teal) ──
  static const Color primary = Color(0xFF0F766E); // "Elegant Ocean Teal"
  static const Color primaryTint = Color(0xFFE2F1F0); // very light teal background
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal100 = Color(0xFFCCFBF1);

  // ── Meaning colours ──
  static const Color success = Color(0xFF10B981); // green: working, approved
  static const Color successDark = Color(0xFF16A34A);
  static const Color successTint = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  static const Color danger = Color(0xFFEF4444); // red: broken, rejected, errors
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerTint = Color(0xFFFEF2F2);

  static const Color warning = Color(0xFFF59E0B); // amber: pending, stale

  static const Color info = Color(0xFF3B82F6); // blue
  static const Color infoDark = Color(0xFF1D4ED8);
  static const Color infoTint = Color(0xFFEFF6FF);

  // ── Greys (the "slate" scale; bigger number = darker) ──
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B); // main text
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B); // secondary text
  static const Color slate400 = Color(0xFF94A3B8); // hints, disabled
  static const Color slate200 = Color(0xFFE2E8F0); // borders
  static const Color slate100 = Color(0xFFF1F5F9); // subtle backgrounds
  static const Color slate50 = Color(0xFFF8FAFC); // page background
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        brightness: Brightness.light,
      );
}
