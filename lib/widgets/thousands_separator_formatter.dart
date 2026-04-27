import 'package:flutter/services.dart';

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.isEmpty) return newValue.copyWith(text: '0');

    final buf = StringBuffer();
    int count = 0;
    for (int i = trimmed.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(trimmed[i]);
      count++;
    }
    final formatted = buf.toString().split('').reversed.join();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
