import 'package:flutter/material.dart';

/// The brand palette. Swap [brand] to re-skin the whole app.
class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF1F55A8);
  static const Color brandDeep = Color(0xFF14356B);
  static const Color brandSoft = Color(0xFFE8EFFA);
  static const Color brandLight = Color(0xFF7FACE4);

  /// Secondary brand colour, used for the wordmark and highlights.
  static const Color accent = Color(0xFFF5A524);

  static const Color success = Color(0xFF0E9F6E);
  static const Color successSoft = Color(0xFFDEF7EC);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);

  // Light neutrals
  static const Color canvasLight = Color(0xFFF6F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color fieldLight = Color(0xFFF1F3F9);
  static const Color borderLight = Color(0xFFE3E8F0);
  static const Color textLight = Color(0xFF0F172A);
  static const Color mutedLight = Color(0xFF6B7488);

  // Dark neutrals
  static const Color canvasDark = Color(0xFF0B1020);
  static const Color surfaceDark = Color(0xFF151C2E);
  static const Color fieldDark = Color(0xFF1B2337);
  static const Color borderDark = Color(0xFF26304A);
  static const Color textDark = Color(0xFFE9EDF7);
  static const Color mutedDark = Color(0xFF95A0B8);
}
