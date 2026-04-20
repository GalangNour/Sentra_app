import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/screens/scan_result_screen.dart';

/// Google ML Kit Text Recognition wrapper.
/// MVP: extract merchant name + total amount only.
class OcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<ParsedReceiptData> processReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    final List<String> lines = [];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }

    final merchant  = _extractMerchant(lines);
    final total     = _extractTotal(lines);
    final category  = _guessCategory(merchant, lines);

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

  // ─── Merchant ─────────────────────────────────────────

  static String _extractMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (line.length > 3 && !_isNumeric(line) && !_isTotalKw(line)) {
        return line.trim();
      }
    }
    return lines.isNotEmpty ? lines.first : 'Transaksi';
  }

  // ─── Total ────────────────────────────────────────────

  static double _extractTotal(List<String> lines) {
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
        final same = _parseAmount(lines[i]);
        if (same != null && same > 0) return same;
        if (i + 1 < lines.length) {
          final next = _parseAmount(lines[i + 1]);
          if (next != null && next > 0) return next;
        }
      }
    }

    double largest = 0;
    for (final line in lines) {
      final n = _parseAmount(line);
      if (n != null && n > largest && n < 100000000) largest = n;
    }
    return largest;
  }

  // ─── Category heuristic ───────────────────────────────

  static TransactionCategory _guessCategory(String merchant, List<String> lines) {
    final text = (merchant + ' ' + lines.join(' ')).toLowerCase();
    if (_any(text, ['indomaret', 'alfamart', 'supermarket', 'hypermart', 'giant', 'carrefour', 'minimarket'])) return TransactionCategory.shopping;
    if (_any(text, ['mcd', 'mcdonalds', 'kfc', 'burger', 'pizza', 'resto', 'cafe', 'warung', 'makan', 'food', 'bakso', 'ayam', 'nasi', 'kopi', 'coffee'])) return TransactionCategory.food;
    if (_any(text, ['grab', 'gojek', 'taxi', 'parkir', 'tol', 'spbu', 'pertamina', 'shell', 'bensin'])) return TransactionCategory.transport;
    if (_any(text, ['pln', 'telkom', 'indihome', 'pdam', 'listrik', 'tagihan', 'wifi', 'internet', 'pulsa'])) return TransactionCategory.bills;
    if (_any(text, ['apotek', 'klinik', 'rumah sakit', 'dokter', 'farmasi', 'kimia farma'])) return TransactionCategory.health;
    if (_any(text, ['bioskop', 'cinema', 'cgv', 'game', 'netflix', 'spotify', 'hiburan'])) return TransactionCategory.entertainment;
    return TransactionCategory.shopping;
  }

  // ─── Helpers ─────────────────────────────────────────

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

  static bool _isNumeric(String s) => RegExp(r'^[\d\s.,:/\-]+$').hasMatch(s);
  static bool _isTotalKw(String s)  => RegExp(r'total|jumlah|subtotal|grand', caseSensitive: false).hasMatch(s);
  static bool _any(String t, List<String> kws) => kws.any((k) => t.contains(k));
}
