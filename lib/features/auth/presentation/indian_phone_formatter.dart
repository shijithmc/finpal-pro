import 'package:flutter/services.dart';

/// Formats a 10-digit Indian mobile number as `98765 43210` while typing.
///
/// Strips all non-digits from input, caps at 10 digits, and inserts a single
/// space after the fifth digit for display. The raw value (digits only) is
/// recovered with [digitsOf].
final class IndianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Extracts the raw 10-digit value from a formatted display string.
  static String digitsOf(String formatted) =>
      formatted.replaceAll(RegExp(r'\D'), '');
}
