import 'package:flutter/material.dart';

/// Holds global [ThemeData] definitions.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      useMaterial3: true,
    );
  }
}
