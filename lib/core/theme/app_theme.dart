import 'package:flutter/material.dart';

/// Holds global [ThemeData] definitions.
class AppTheme {
  const AppTheme._();

  /// Common geometry for all primary/secondary buttons, taken from the
  /// auth screens mockup: full-height pill-ish rounded rectangle (52px tall,
  /// 12px corner radius).
  static const double _buttonHeight = 52;
  static const double _buttonRadius = 12;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
    );
    const buttonTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
     
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffececf1),
          minimumSize: const Size(64, _buttonHeight),
          shape: buttonShape,
          textStyle: buttonTextStyle,
          elevation: 0
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, _buttonHeight),
          shape: buttonShape,
          side: const BorderSide(color: Color(0xffC7C7D2), width: 1),
          textStyle: buttonTextStyle.copyWith(color: Color(0xff46566f)),
          elevation: 0,
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, _buttonHeight),
          shape: buttonShape.copyWith(
            side: BorderSide(color: Color(0xffc7c7c2), width: 1)
          ),
          textStyle: buttonTextStyle,
          elevation: 0

        ),
      ),
    );
  }
}
