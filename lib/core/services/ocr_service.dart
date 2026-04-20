import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/screens/scan_result_screen.dart';

/// Wraps Google ML Kit Text Recognition.
/// MVP: hanya ekstrak merchant name + total amount.
class OcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<ParsedReceiptData> processReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    // Collect all lines in document order
    final List<String> lines = [];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }

    final merchant = _extractMerchant(lines);
    final total    = _extractTotal(lines);
    final category = _guessCategory(merchant, lines);

    return ParsedReceiptData(
      merchant: merchant,
      total: total,
      date: DateTime.now(),
      category: category,
      imagePath: imagePath,
      rawText: lines.join('\n'),
    );
  }

  static Future<void> close() => _recognizer.close();

  // ─── Merchant ─────────────────────────────────────────────

  static String _extractMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (line.length > 3 && !_isNumeric(line) && !_isTotalKeyword(line)) {
        return line.trim();
      }
    }
    return lines.isNotEmpty ? lines.first : 'Transaksi';
  }

  // ─── Total ────────────────────────────────────────────────

  static double _extractTotal(List<String> lines) {
    // Priority: GRAND TOTAL > TOTAL BAYAR > TOTAL > JUMLAH > SUBTOTAL
    final patterns = [
      RegExp(r'GRAND\s*TOTAL',        caseSensitive: false),
      RegExp(r'TOTAL\s*BAYAR',        caseSensitive: false),
      RegExp(r'TOTAL',                caseSensitive: false),
      RegExp(r'JUMLAH',               caseSensitive: false),
      RegExp(r'PEMBAYARAN|PAYMENT',   caseSensitive: false),
      RegExp(r'SUB\s*TOTAL|SUBTOTAL', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (int i = 0; i < lines.length; i++) {
        if (!pattern.hasMatch(lines[i])) continue;

        // Try same line first
        final same = _parseAmount(lines[i]);
        if (same != null && same > 0) return same;

        // Then next line
        if (i + 1 < lines.length) {
          final next = _parseAmount(lines[i + 1]);
          if (next != null && next > 0) return next;
        }
      }
    }

    // Fallback: largest reasonable number in document
    double largest = 0;
    for (final line in lines) {
      final n = _parseAmount(line);
      if (n != null && n > largest && n < 100000000) largest = n;
    }
    return largest;
  }

  // ─── Category heuristic ───────────────────────────────────

  static TransactionCategory _guessCategory(
      String merchant, List<String> lines) {
    final text = (merchant + ' ' + lines.join(' ')).toLowerCase();

    if (_any(text, ['indomaret', 'alfamart', 'supermarket', 'hypermart',
        'giant', 'carrefour', 'lottemart', 'minimarket'])) {
      return TransactionCategory.shopping;
    }
    if (_any(text, ['mcd', 'mcdonalds', 'kfc', 'burger', 'pizza', 'resto',
        'cafe', 'warung', 'makan', 'food', 'bakso', 'ayam', 'nasi', 'soto',
        'padang', 'seafood', 'coffee', 'kopi', 'kebab'])) {
      return TransactionCategory.food;
    }
    if (_any(text, ['grab', 'gojek', 'goride', 'gocar', 'taxi', 'parkir',
        'tol', 'spbu', 'pertamina', 'shell', 'bensin', 'bbm'])) {
      return TransactionCategory.transport;
    }
    if (_any(text, ['pln', 'telkom', 'indihome', 'pdam', 'listrik', 'tagihan',
        'wifi', 'internet', 'pulsa', 'data', 'bill'])) {
      return TransactionCategory.bills;
    }
    if (_any(text, ['apotek', 'apotik', 'klinik', 'rumah sakit', 'dokter',
        'hospital', 'farmasi', 'kimia farma', 'health'])) {
      return TransactionCategory.health;
    }
    if (_any(text, ['bioskop', 'cinema', 'cgv', 'game', 'netflix', 'spotify',
        'hiburan', 'entertainment'])) {
      return TransactionCategory.entertainment;
    }
    return TransactionCategory.shopping;
  }

  // ─── Helpers ──────────────────────────────────────────────

  /// Parse Indonesian currency: "Rp 12.500", "12.500,00", "12500"
  static double? _parseAmount(String line) {
    var s = line.replaceAll(RegExp(r'Rp\.?\s*'), '');
    final m = RegExp(r'(\d[\d.,]*)').firstMatch(s);
    if (m == null) return null;
    var n = m.group(1)!;
    if (n.contains(',')) {
      n = n.replaceAll('.', '').replaceAll(',', '.');
    } else {
      n = n.replaceAll('.', '');
    }
    return double.tryParse(n);
  }

  static bool _isNumeric(String s) =>
      RegExp(r'^[\d\s.,:/\-]+$').hasMatch(s);

  static bool _isTotalKeyword(String s) =>
      RegExp(r'total|jumlah|subtotal|grand', caseSensitive: false).hasMatch(s);

  static bool _any(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
