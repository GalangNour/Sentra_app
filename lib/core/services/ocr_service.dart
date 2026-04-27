import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentra_app/core/config/api_config.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

class OcrService {
  static final _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ─── Public entry point ───────────────────────────────────────────────────

  static Future<ParsedReceiptData> processReceipt(String imagePath) async {
    if (ApiConfig.geminiApiKey != 'MASUKKAN_API_KEY_DISINI' &&
        ApiConfig.geminiApiKey.isNotEmpty) {
      try {
        return await _processWithGemini(imagePath);
      } on SocketException {
        // No internet — fall back to offline ML Kit silently
        debugPrint('OCR: no internet, falling back to ML Kit');
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('API_KEY') ||
            msg.contains('invalid') ||
            msg.contains('401') ||
            msg.contains('403')) {
          throw Exception(
            'API key Gemini tidak valid. Periksa kembali key di api_config.dart.',
          );
        }
        // Rate limit or quota → fall back to ML Kit but warn the user
        final isRateLimit =
            msg.contains('429') ||
            msg.contains('quota') ||
            msg.contains('RESOURCE_EXHAUSTED') ||
            msg.contains('limit');
        debugPrint('OCR: Gemini failed ($msg), falling back to ML Kit');
        final fallback = await _processWithMlKit(imagePath);
        return ParsedReceiptData(
          merchant: fallback.merchant,
          total: fallback.total,
          date: fallback.date,
          category: fallback.category,
          imagePath: fallback.imagePath,
          rawText: fallback.rawText,
          source: 'mlkit',
          candidateAmounts: fallback.candidateAmounts,
          warning: isRateLimit
              ? 'Gemini sedang terbatas — hasil dari OCR offline. Pilih nominal yang benar di bawah.'
              : 'Gemini gagal — hasil dari OCR offline. Pilih nominal yang benar di bawah.',
        );
      }
    }
    // Offline ML Kit fallback
    return await _processWithMlKit(imagePath);
  }

  static Future<void> close() => _recognizer.close();

  // ─── Gemini Vision ────────────────────────────────────────────────────────

  static Future<ParsedReceiptData> _processWithGemini(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final mimeType = imagePath.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConfig.geminiApiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );

    const prompt = '''
Baca struk atau nota belanja dalam gambar ini.
Kembalikan HANYA JSON berikut tanpa teks lain, tanpa markdown, tanpa penjelasan:
{"merchant":"nama toko","total":50000,"category":"shopping"}

Aturan wajib:
- total: angka INTEGER murni (tanpa Rp, titik, koma, spasi)
  → Ambil dari baris: Grand Total / Total Bayar / Total Pembayaran / Jumlah Bayar / Total Belanja
  → JANGAN ambil: Subtotal, diskon, harga satuan, jumlah item, nomor telepon
  → Jika tidak ditemukan, tulis 0
- merchant: nama toko atau restoran di bagian atas struk. Jika tidak jelas, tulis "Transaksi"
- category: PILIH SATU dari daftar ini persis:
  food, transport, shopping, entertainment, health, bills, other
''';

    final response = await model.generateContent([
      Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
    ]);

    final raw = response.text ?? '';
    if (raw.isEmpty) throw Exception('Gemini mengembalikan respons kosong');

    // Debug: always print raw Gemini response to console
    debugPrint('══ GEMINI RAW RESPONSE ══\n$raw\n══════════════════════');

    // Strip markdown code fences if Gemini wraps the JSON anyway
    final jsonStr = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Extract the first { ... } block from the response
    final jsonStart = jsonStr.indexOf('{');
    final jsonEnd = jsonStr.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw Exception('Gemini tidak mengembalikan JSON yang valid: $jsonStr');
    }
    final cleanJson = jsonStr.substring(jsonStart, jsonEnd + 1);

    debugPrint('══ GEMINI PARSED JSON ══\n$cleanJson\n══════════════════════');

    final Map<String, dynamic> data = jsonDecode(cleanJson);

    final result = ParsedReceiptData(
      merchant: (data['merchant'] as String? ?? 'Transaksi').trim(),
      total: ((data['total'] ?? 0) as num).toDouble(),
      date: DateTime.now(),
      category: _categoryFromString(data['category'] as String? ?? ''),
      imagePath: imagePath,
      rawText: raw,
      source: 'gemini',
    );

    debugPrint(
      '══ GEMINI RESULT ══ merchant="${result.merchant}" total=${result.total} category=${result.category}',
    );
    return result;
  }

  // ─── ML Kit fallback ──────────────────────────────────────────────────────

  static Future<ParsedReceiptData> _processWithMlKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText result = await _recognizer.processImage(inputImage);

    final List<String> lines = [];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }

    final merchant = _extractMerchant(lines);
    final total = _extractTotal(lines);
    final category = _guessCategory(merchant, lines);
    final candidates = _extractAllAmounts(lines);

    debugPrint(
      '══ MLKIT RESULT ══ merchant="$merchant" total=$total candidates=$candidates',
    );
    return ParsedReceiptData(
      merchant: merchant,
      total: total,
      date: DateTime.now(),
      category: category,
      source: 'mlkit',
      imagePath: imagePath,
      rawText: lines.join('\n'),
      candidateAmounts: candidates,
    );
  }

  // ─── Category ─────────────────────────────────────────────────────────────

  static TransactionCategory _categoryFromString(String s) {
    return switch (s.toLowerCase().trim()) {
      'food' => TransactionCategory.food,
      'transport' => TransactionCategory.transport,
      'shopping' => TransactionCategory.shopping,
      'entertainment' => TransactionCategory.entertainment,
      'health' => TransactionCategory.health,
      'bills' => TransactionCategory.bills,
      _ => TransactionCategory.other,
    };
  }

  // ─── ML Kit helpers ───────────────────────────────────────────────────────

  static String _extractMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (line.length > 3 && !_isNumeric(line) && !_isTotalKw(line)) {
        return line.trim();
      }
    }
    return lines.isNotEmpty ? lines.first : 'Transaksi';
  }

  static double _extractTotal(List<String> lines) {
    final patterns = [
      RegExp(r'GRAND\s*TOTAL', caseSensitive: false),
      RegExp(r'TOTAL\s*BAYAR', caseSensitive: false),
      RegExp(r'TOTAL\s*PEMBAYARAN', caseSensitive: false),
      RegExp(r'YANG\s*HARUS\s*DIBAYAR', caseSensitive: false),
      RegExp(r'JUMLAH\s*BAYAR', caseSensitive: false),
      RegExp(r'TOTAL\s*BELANJA', caseSensitive: false),
      RegExp(r'TOTAL', caseSensitive: false),
      RegExp(r'JUMLAH', caseSensitive: false),
      RegExp(r'PEMBAYARAN|PAYMENT', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (int i = lines.length - 1; i >= 0; i--) {
        final line = lines[i];
        if (_isNonMonetaryLine(line)) continue;
        if (!pattern.hasMatch(line)) continue;
        if (pattern.pattern == r'TOTAL' &&
            RegExp(
              r'SUB\s*TOTAL|SUBTOTAL|TOTAL\s*ITEM|TOTAL\s*DISC',
              caseSensitive: false,
            ).hasMatch(line)) {
          continue;
        }

        final same = _parseCurrencyAmount(line);
        if (same != null && same >= 1000) return same;

        if (i + 1 < lines.length) {
          final next = _parseCurrencyAmount(lines[i + 1]);
          if (next != null && next >= 1000) return next;
        }
      }
    }

    double largest = 0;
    final mid = lines.length ~/ 2;
    for (int i = mid; i < lines.length; i++) {
      if (_isNonMonetaryLine(lines[i])) continue;
      final n = _parseCurrencyAmount(lines[i]);
      if (n != null && n > largest && n < 50000000) largest = n;
    }
    if (largest >= 1000) return largest;

    for (final line in lines) {
      if (_isNonMonetaryLine(line)) continue;
      final n = _parseCurrencyAmount(line);
      if (n != null && n > largest && n < 50000000) largest = n;
    }
    return largest;
  }

  static TransactionCategory _guessCategory(
    String merchant,
    List<String> lines,
  ) {
    final text = '$merchant ${lines.join(' ')}'.toLowerCase();
    if (_any(text, [
      'indomaret',
      'alfamart',
      'supermarket',
      'hypermart',
      'giant',
      'carrefour',
      'minimarket',
    ]))
      return TransactionCategory.shopping;
    if (_any(text, [
      'mcd',
      'mcdonalds',
      'kfc',
      'burger',
      'pizza',
      'resto',
      'cafe',
      'warung',
      'makan',
      'food',
      'bakso',
      'ayam',
      'nasi',
      'kopi',
      'coffee',
    ]))
      return TransactionCategory.food;
    if (_any(text, [
      'grab',
      'gojek',
      'taxi',
      'parkir',
      'tol',
      'spbu',
      'pertamina',
      'shell',
      'bensin',
    ]))
      return TransactionCategory.transport;
    if (_any(text, [
      'pln',
      'telkom',
      'indihome',
      'pdam',
      'listrik',
      'tagihan',
      'wifi',
      'internet',
      'pulsa',
    ]))
      return TransactionCategory.bills;
    if (_any(text, [
      'apotek',
      'klinik',
      'rumah sakit',
      'dokter',
      'farmasi',
      'kimia farma',
    ]))
      return TransactionCategory.health;
    if (_any(text, [
      'bioskop',
      'cinema',
      'cgv',
      'game',
      'netflix',
      'spotify',
      'hiburan',
    ]))
      return TransactionCategory.entertainment;
    return TransactionCategory.shopping;
  }

  static bool _isNonMonetaryLine(String line) {
    return RegExp(
      r'KRITIK|SARAN|SMS|\bWA\b|TELP|\bHP\b|HOTLINE|MEMBER|NPWP|'
      r'KASIR|BON|TGL|TANGGAL|NO\.?\s*BON|V\.\d|VERSION|VERSI|'
      r'ALFAMART|INDOMARET|PT\.|JAYA|ALFARIA|TRIJAYA',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static double? _parseCurrencyAmount(String line) {
    var s = line.replaceAll(RegExp(r'Rp\.?\s*', caseSensitive: false), '');
    // OCR artifact: "40, 400" or "40. 400" → "40,400" / "40.400"
    s = s.replaceAllMapped(
      RegExp(r'(\d)\s*([.,])\s*(\d)'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );
    final matches = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,})',
    ).allMatches(s);
    if (matches.isEmpty) return null;
    double? best;
    for (final m in matches) {
      final parsed = _parseNumber(m.group(1)!);
      if (parsed != null && (best == null || parsed > best)) best = parsed;
    }
    return best;
  }

  static List<double> _extractAllAmounts(List<String> lines) {
    final seen = <double>{};
    final result = <double>[];
    for (final line in lines) {
      if (_isNonMonetaryLine(line)) continue;
      final n = _parseCurrencyAmount(line);
      if (n != null && n >= 1000 && n < 100000000 && seen.add(n)) {
        result.add(n);
      }
    }
    result.sort((a, b) => b.compareTo(a));
    return result;
  }

  static double? _parseNumber(String n) {
    if (n.contains(',') && n.contains('.')) {
      final lastDot = n.lastIndexOf('.');
      final lastComma = n.lastIndexOf(',');
      if (lastComma > lastDot) {
        n = n.replaceAll('.', '').replaceAll(',', '.');
      } else {
        n = n.replaceAll(',', '');
      }
    } else if (n.contains(',')) {
      if (RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(n)) {
        n = n.replaceAll(',', '');
      } else {
        n = n.replaceAll(',', '.');
      }
    } else {
      n = n.replaceAll('.', '');
    }
    return double.tryParse(n);
  }

  static bool _isNumeric(String s) => RegExp(r'^[\d\s.,:/\-]+$').hasMatch(s);
  static bool _isTotalKw(String s) =>
      RegExp(r'total|jumlah|subtotal|grand', caseSensitive: false).hasMatch(s);
  static bool _any(String t, List<String> kws) => kws.any((k) => t.contains(k));
}
