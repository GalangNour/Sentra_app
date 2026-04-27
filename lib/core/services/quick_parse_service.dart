import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sentra_app/core/config/api_config.dart';
import 'package:sentra_app/core/models/parsed_transaction.dart';
import 'package:sentra_app/core/models/transaction.dart';

class QuickParseService {
  // Set true selama development untuk skip API call dan hemat quota.
  static const bool debugMode = false;

  static Future<ParsedTransaction> parse(String text) async {
    if (debugMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _mockResult(text);
    }

    if (ApiConfig.geminiApiKey != 'MASUKKAN_API_KEY_DISINI' &&
        ApiConfig.geminiApiKey.isNotEmpty) {
      try {
        return await _parseWithGemini(text);
      } on SocketException {
        debugPrint('QuickParse: no internet, fallback to local');
        return _parseLocally(text);
      } catch (e) {
        if (_is503(e)) {
          // Retry up to 2x with delay before giving up
          for (int attempt = 1; attempt <= 2; attempt++) {
            await Future.delayed(Duration(milliseconds: 1500 * attempt));
            debugPrint('QuickParse: 503, retry attempt $attempt...');
            try {
              return await _parseWithGemini(text);
            } catch (retryErr) {
              if (!_is503(retryErr) || attempt == 2) {
                debugPrint('QuickParse: retry $attempt failed ($retryErr), fallback to local');
                break;
              }
            }
          }
        } else {
          debugPrint('QuickParse: Gemini error ($e), fallback to local');
        }
      }
    }
    return _parseLocally(text);
  }

  static bool _is503(Object e) {
    final s = e.toString();
    return s.contains('503') || s.contains('UNAVAILABLE') || s.contains('high demand');
  }

  // ─── Mock ─────────────────────────────────────────────────

  static ParsedTransaction _mockResult(String text) {
    final today = DateTime.now();
    return ParsedTransaction(
      title: 'Cilok (mock)',
      amount: 10000,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: today.subtract(const Duration(days: 1)),
      rawInput: text,
      warning: 'DEBUG MODE — data dummy, API tidak dipanggil.',
    );
  }

  // ─── Gemini ───────────────────────────────────────────────

  static Future<ParsedTransaction> _parseWithGemini(String text) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConfig.geminiApiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final prompt = '''
Kamu adalah parser transaksi keuangan untuk aplikasi finance Indonesia.
Ekstrak informasi dari kalimat berikut.

Hari ini: $todayStr
Input: "$text"

Kembalikan HANYA JSON ini tanpa teks lain, tanpa markdown:
{"title":"...","amount":0,"type":"expense","category":"other","note":null,"date":"$todayStr"}

Aturan wajib:
- title: nama singkat transaksi maks 40 karakter, bersihkan dari angka nominal dan kata waktu
- amount: INTEGER murni. Konversi: "15rb"→15000, "1.5jt"→1500000, "200.000"→200000, "15k"→15000
- type: "income" jika mengandung kata gaji/gajian/terima/dapat/bonus/honor/cashback/refund/dividen/freelance/masuk; selainnya "expense"
- category pilih SATU: food, transport, shopping, entertainment, health, bills, salary, investment, other
  food→makan/minum/kopi/cafe/resto/warung/jajan/snack/pizza/burger/bakso/nasi/cilok/gorengan/siomay/batagor
  transport→bensin/grab/gojek/ojek/taksi/parkir/tol/kereta/bus
  shopping→baju/sepatu/shopee/tokopedia/lazada/belanja/toko
  entertainment→nonton/bioskop/netflix/spotify/game/liburan/konser
  health→obat/dokter/klinik/apotek/vitamin/puskesmas
  bills→listrik/pln/air/wifi/internet/pulsa/tagihan/token
  salary→gaji/gajian/honor/upah
  investment→investasi/saham/reksa dana/dividen
- note: catatan tambahan jika ada di kalimat, atau null
- date: tanggal transaksi format YYYY-MM-DD, hitung relatif dari hari ini ($todayStr)
  "kemarin" → 1 hari sebelum hari ini
  "kemarin lusa" / "dua hari lalu" / "2 hari lalu" → 2 hari sebelum hari ini
  "N hari lalu" → N hari sebelum hari ini
  "minggu lalu" → 7 hari sebelum hari ini
  "bulan lalu" → 30 hari sebelum hari ini
  "tadi" / "tadi pagi" / "tadi malam" / tidak disebut → hari ini
  Nama hari (Senin/Selasa/dst) → hari tersebut di minggu ini atau minggu lalu (tidak boleh melebihi hari ini)
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    if (raw.isEmpty) throw Exception('empty response');

    debugPrint('══ QUICKPARSE RAW ══\n$raw\n══════════════════');

    final jsonStr = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final start = jsonStr.indexOf('{');
    final end = jsonStr.lastIndexOf('}');
    if (start == -1 || end <= start) throw Exception('no JSON in response');

    final Map<String, dynamic> data = jsonDecode(jsonStr.substring(start, end + 1));

    final type = (data['type'] as String? ?? 'expense').toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    return ParsedTransaction(
      title: (data['title'] as String? ?? text).trim(),
      amount: ((data['amount'] ?? 0) as num).toDouble(),
      type: type,
      category: _categoryFromString(data['category'] as String? ?? '', type),
      note: (data['note'] as String?)?.trim().isEmpty == true ? null : data['note'] as String?,
      date: _parseDate(data['date'] as String?, today),
      rawInput: text,
    );
  }

  static DateTime _parseDate(String? raw, DateTime today) {
    if (raw == null || raw.isEmpty) return today;
    try {
      final d = DateTime.parse(raw);
      // Clamp to today — reject future dates from hallucination
      return d.isAfter(today) ? today : d;
    } catch (_) {
      return today;
    }
  }

  // ─── Local fallback ───────────────────────────────────────

  static ParsedTransaction _parseLocally(String text) {
    final amount = _extractAmount(text) ?? 0;
    final type = _detectType(text);
    final category = _detectCategory(text, type);
    final title = _extractTitle(text);
    return ParsedTransaction(
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.now(),
      rawInput: text,
      warning: 'Parsed offline — periksa kembali hasilnya.',
    );
  }

  static double? _extractAmount(String text) {
    var m = RegExp(
      r'([\d]+(?:[.,]\d+)?)\s*(?:juta?|jt)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (m != null) {
      final n = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (n != null) return n * 1000000;
    }
    m = RegExp(
      r'([\d]+(?:[.,]\d+)?)\s*(?:ribu?|rb|k)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (m != null) {
      final n = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (n != null) return n * 1000;
    }
    m = RegExp(r'\b(\d{1,3}(?:\.\d{3})+)\b').firstMatch(text);
    if (m != null) {
      final n = double.tryParse(m.group(1)!.replaceAll('.', ''));
      if (n != null) return n;
    }
    m = RegExp(r'\b(\d{4,})\b').firstMatch(text);
    if (m != null) return double.tryParse(m.group(1)!);
    return null;
  }

  static TransactionType _detectType(String text) {
    final lower = text.toLowerCase();
    const incomeWords = [
      'terima', 'dapat', 'gaji', 'gajian', 'masuk', 'bonus',
      'honor', 'upah', 'freelance', 'dividen', 'cashback', 'refund',
    ];
    if (incomeWords.any((w) => lower.contains(w))) return TransactionType.income;
    return TransactionType.expense;
  }

  static TransactionCategory _detectCategory(
    String text,
    TransactionType type,
  ) {
    final lower = text.toLowerCase();
    if (type == TransactionType.income) {
      if (lower.contains('gaji') || lower.contains('gajian') || lower.contains('upah')) {
        return TransactionCategory.salary;
      }
      if (lower.contains('invest') || lower.contains('dividen')) return TransactionCategory.investment;
      return TransactionCategory.other;
    }
    const Map<TransactionCategory, List<String>> cats = {
      TransactionCategory.food: [
        'makan', 'minum', 'kopi', 'cafe', 'restoran', 'warung', 'nasi', 'bakso',
        'ayam', 'pizza', 'burger', 'sushi', 'martabak', 'indomie', 'snack',
        'jajan', 'sarapan', 'mcd', 'kfc', 'boba',
      ],
      TransactionCategory.transport: [
        'bensin', 'bbm', 'grab', 'gojek', 'ojek', 'taksi', 'taxi',
        'bus', 'kereta', 'parkir', 'tol',
      ],
      TransactionCategory.shopping: [
        'shopee', 'tokopedia', 'lazada', 'baju', 'sepatu', 'belanja', 'online',
      ],
      TransactionCategory.entertainment: [
        'nonton', 'bioskop', 'netflix', 'spotify', 'game', 'liburan', 'konser',
      ],
      TransactionCategory.health: [
        'obat', 'dokter', 'klinik', 'rumah sakit', 'vitamin', 'apotek',
      ],
      TransactionCategory.bills: [
        'listrik', 'air', 'internet', 'wifi', 'pln', 'pdam',
        'tagihan', 'pulsa', 'token',
      ],
    };
    for (final entry in cats.entries) {
      if (entry.value.any((w) => lower.contains(w))) return entry.key;
    }
    return TransactionCategory.other;
  }

  static String _extractTitle(String text) {
    var t = text.trim();
    t = t.replaceAll(
      RegExp(r'[\d]+(?:[.,]\d+)?\s*(?:juta?|jt|ribu?|rb|k)\b', caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'\b\d{1,3}(?:\.\d{3})+\b'), '');
    t = t.replaceAll(RegExp(r'\b\d{4,}\b'), '');
    t = t.replaceAll(
      RegExp(r'^(?:beli|bayar|dapat|terima)\s+', caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? text.trim() : t;
  }

  static TransactionCategory _categoryFromString(String s, TransactionType type) {
    return switch (s.toLowerCase().trim()) {
      'food' => TransactionCategory.food,
      'transport' => TransactionCategory.transport,
      'shopping' => TransactionCategory.shopping,
      'entertainment' => TransactionCategory.entertainment,
      'health' => TransactionCategory.health,
      'bills' => TransactionCategory.bills,
      'salary' => TransactionCategory.salary,
      'investment' => TransactionCategory.investment,
      _ => TransactionCategory.other,
    };
  }
}
