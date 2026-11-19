import 'package:flutter/material.dart';

/// Brand palette taken from the Figma design system. Keep all hard-coded
/// colors here so screens stay pixel-consistent.
class AppColors {
  AppColors._();

  /// Primary action ("Сохранить", "Активировать") — muted steel blue.
  static const Color primaryBlue = Color(0xFF3B5B83);

  /// Secondary bright blue ("Сменить пароль", lock icon).
  static const Color brightBlue = Color(0xFF2F80ED);

  /// Orange accent ("Сменить email", shield/email icons).
  static const Color orange = Color(0xFFF5A623);

  /// Issue-waybill green ("ВЫПУСТИТЬ ЭПЛ").
  static const Color green = Color(0xFF22C55E);

  /// Home-screen yellow background.
  static const Color yellow = Color(0xFFF4D40C);

  /// Light gray fill for inputs / neutral buttons.
  static const Color fieldFill = Color(0xFFECECF1);

  /// Subtle card background.
  static const Color cardBg = Color(0xFFF4F4F7);

  /// Input outline.
  static const Color inputBorder = Color(0xFFE0E0E7);

  /// Muted caption text.
  static const Color textGrey = Color(0xFF8A8A99);
  static const Color textGrey2 = Color(0xFF4a4d55);
  static const Color textGrey3 = Color(0xFF52688c);

  static const Color textBlack = Color(0xFF1f2126);

  /// Neutral icon stroke (gray SVG icons).
  static const Color iconGrey = Color(0xFF5A5D66);
}
