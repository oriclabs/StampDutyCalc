import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input with thousand separators as the user types.
/// E.g., "45000" → "45,000"
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'en');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Strip non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue();

    final number = int.tryParse(digitsOnly);
    if (number == null) return newValue;

    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Parse the formatted text back to a number
  static double? parse(String text) {
    final clean = text.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }
}
