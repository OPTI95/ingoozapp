import 'package:flutter/services.dart';

class SnilsInputFormatter extends TextInputFormatter {
  const SnilsInputFormatter();

  static String formatSnils(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    if (digits.isEmpty) return '';

    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      b.write(digits[i]);
      if ((i == 2 || i == 5 || i == 8) && i != digits.length - 1) {
        b.write('-');
      }
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatSnils(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RussianPhoneInputFormatter extends TextInputFormatter {
  const RussianPhoneInputFormatter();

  static String formatPhone(String digitsInput) {
    if (digitsInput.isEmpty) return '';
    var digits = digitsInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    } else if (!digits.startsWith('7')) {
      digits = '7$digits';
    }
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final local = digits.length > 1 ? digits.substring(1) : '';
    final b = StringBuffer('+7');
    if (local.isEmpty) return b.toString();

    b.write(' ');
    final p1 = local.length >= 3 ? local.substring(0, 3) : local;
    b.write(p1);
    if (local.length <= 3) return b.toString();

    b.write('-');
    final p2 = local.length >= 6 ? local.substring(3, 6) : local.substring(3);
    b.write(p2);
    if (local.length <= 6) return b.toString();

    b.write('-');
    final p3 = local.length >= 8 ? local.substring(6, 8) : local.substring(6);
    b.write(p3);
    if (local.length <= 8) return b.toString();

    b.write('-');
    final p4 = local.length >= 10
        ? local.substring(8, 10)
        : local.substring(8);
    b.write(p4);
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
