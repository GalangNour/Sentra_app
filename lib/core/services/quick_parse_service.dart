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

  static Future<List<ParsedTransaction>> parse(
    String text, {
    bool useAI = true,
  }) async {
    if (debugMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _mockResults(text);
    }

    if (!useAI) return [_parseLocally(text)];

    if (ApiConfig.geminiApiKey != 'MASUKKAN_API_KEY_DISINI' &&
        ApiConfig.geminiApiKey.isNotEmpty) {
      try {
        return await _parseWithGemini(text);
      } on SocketException {
        debugPrint('QuickParse: no internet, fallback to local');
        return [_parseLocally(text)];
      } catch (e) {
        if (_is503(e)) {
          for (int attempt = 1; attempt <= 2; attempt++) {
            await Future.delayed(Duration(milliseconds: 1500 * attempt));
            debugPrint('QuickParse: 503, retry attempt $attempt...');
            try {
              return await _parseWithGemini(text);
            } catch (retryErr) {
              if (!_is503(retryErr) || attempt == 2) {
                debugPrint(
                  'QuickParse: retry $attempt failed ($retryErr), fallback to local',
                );
                break;
              }
            }
          }
        } else {
          debugPrint('QuickParse: Gemini error ($e), fallback to local');
        }
      }
    }
    return [_parseLocally(text)];
  }

  static bool _is503(Object e) {
    final s = e.toString();
    return s.contains('503') ||
        s.contains('UNAVAILABLE') ||
        s.contains('high demand');
  }

  // ─── Mock ─────────────────────────────────────────────────

  static List<ParsedTransaction> _mockResults(String text) {
    final today = DateTime.now();
    return [
      ParsedTransaction(
        title: 'Kopi (mock)',
        amount: 15000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: today.subtract(const Duration(days: 1)),
        rawInput: text,
        warning: 'DEBUG MODE — data dummy, API tidak dipanggil.',
      ),
      ParsedTransaction(
        title: 'Bensin (mock)',
        amount: 30000,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        date: today.subtract(const Duration(days: 1)),
        rawInput: text,
      ),
      ParsedTransaction(
        title: 'Ayam Geprek (mock)',
        amount: 25000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: today,
        rawInput: text,
      ),
    ];
  }

  // ─── Gemini ───────────────────────────────────────────────

  static Future<List<ParsedTransaction>> _parseWithGemini(String text) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConfig.geminiApiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final prompt =
        '''
Kamu adalah parser transaksi keuangan untuk aplikasi finance Indonesia.
Ekstrak SEMUA transaksi yang disebutkan dalam kalimat berikut.

Hari ini: $todayStr
Input: "$text"

Kembalikan HANYA JSON array tanpa teks lain, tanpa markdown:
[{"title":"...","amount":0,"type":"expense","category":"other","note":null,"date":"$todayStr"}]

Aturan wajib:
- Selalu kembalikan array, meski hanya satu transaksi
- Jika ada beberapa transaksi dalam satu input, kembalikan masing-masing sebagai objek terpisah
- title: nama singkat transaksi maks 40 karakter, bersihkan dari angka nominal dan kata waktu
- amount: INTEGER murni. Konversi: "15rb"→15000, "1.5jt"→1500000, "200.000"→200000, "15k"→15000
- type: "income" jika mengandung kata gaji/gajian/terima/dapat/bonus/honor/cashback/refund/dividen/freelance/masuk; selainnya "expense"
- category pilih SATU: food, transport, shopping, entertainment, health, bills, salary, investment, other
  food→makan/minum/kopi/cafe/resto/warung/jajan/snack/pizza/burger/bakso/nasi/cilok/gorengan/siomay/batagor/ayam
  transport→bensin/grab/gojek/ojek/taksi/parkir/tol/kereta/bus
  shopping→baju/sepatu/shopee/tokopedia/lazada/belanja/toko
  entertainment→nonton/bioskop/netflix/spotify/game/liburan/konser
  health→obat/dokter/klinik/apotek/vitamin/puskesmas
  bills→listrik/pln/air/wifi/internet/pulsa/tagihan/token
  salary→gaji/gajian/honor/upah
  investment→investasi/saham/reksa dana/dividen
- note: catatan tambahan jika ada di kalimat untuk transaksi tersebut, atau null
- date: tanggal transaksi format YYYY-MM-DD, hitung relatif dari hari ini ($todayStr)
  "kemarin" → 1 hari sebelum hari ini
  "kemarin lusa" / "dua hari lalu" / "2 hari lalu" → 2 hari sebelum hari ini
  "N hari lalu" → N hari sebelum hari ini
  "minggu lalu" → 7 hari sebelum hari ini
  "bulan lalu" → 30 hari sebelum hari ini
  "tadi" / "tadi pagi" / tidak disebut → hari ini
  Nama hari (Senin/Selasa/dst) → hari tersebut di minggu ini atau minggu lalu (tidak boleh melebihi hari ini)
  Jika beberapa transaksi punya kata waktu berbeda, terapkan ke masing-masing transaksi
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    if (raw.isEmpty) throw Exception('empty response');

    debugPrint('══ QUICKPARSE RAW ══\n$raw\n══════════════════');

    final jsonStr = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final start = jsonStr.indexOf('[');
    final end = jsonStr.lastIndexOf(']');
    if (start == -1 || end <= start)
      throw Exception('no JSON array in response');

    final List<dynamic> arr = jsonDecode(jsonStr.substring(start, end + 1));
    if (arr.isEmpty) throw Exception('empty array in response');

    return arr
        .map((e) => _txFromMap(e as Map<String, dynamic>, text, today))
        .toList();
  }

  static ParsedTransaction _txFromMap(
    Map<String, dynamic> data,
    String rawInput,
    DateTime today,
  ) {
    final type =
        (data['type'] as String? ?? 'expense').toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    final noteRaw = data['note'] as String?;
    return ParsedTransaction(
      title: _toTitleCase((data['title'] as String? ?? rawInput).trim()),
      amount: ((data['amount'] ?? 0) as num).toDouble(),
      type: type,
      category: _categoryFromString(data['category'] as String? ?? '', type),
      note: (noteRaw == null || noteRaw.trim().isEmpty) ? null : noteRaw.trim(),
      date: _parseDate(data['date'] as String?, today),
      rawInput: rawInput,
    );
  }

  static DateTime _parseDate(String? raw, DateTime today) {
    if (raw == null || raw.isEmpty) return today;
    try {
      final d = DateTime.parse(raw);
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
    return ParsedTransaction(
      title: _toTitleCase(_extractTitle(text)),
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
      'terima',
      'dapat',
      'gaji',
      'gajian',
      'masuk',
      'bonus',
      'honor',
      'upah',
      'freelance',
      'dividen',
      'cashback',
      'refund',
    ];
    if (incomeWords.any((w) => lower.contains(w)))
      return TransactionType.income;
    return TransactionType.expense;
  }

  static TransactionCategory _detectCategory(
    String text,
    TransactionType type,
  ) {
    final lower = text.toLowerCase();
    if (type == TransactionType.income) {
      if (lower.contains('gaji') ||
          lower.contains('gajian') ||
          lower.contains('upah'))
        return TransactionCategory.salary;
      if (lower.contains('invest') || lower.contains('dividen'))
        return TransactionCategory.investment;
      return TransactionCategory.other;
    }
    const Map<TransactionCategory, List<String>> cats = {
      TransactionCategory.food: [
        'makan',
        'minum',
        'kopi',
        'cafe',
        'restoran',
        'warung',
        'nasi',
        'bakso',
        'ayam',
        'pizza',
        'burger',
        'sushi',
        'martabak',
        'indomie',
        'snack',
        'jajan',
        'sarapan',
        'mcd',
        'kfc',
        'boba',
      ],
      TransactionCategory.transport: [
        'bensin',
        'bbm',
        'grab',
        'gojek',
        'ojek',
        'taksi',
        'taxi',
        'bus',
        'kereta',
        'parkir',
        'tol',
      ],
      TransactionCategory.shopping: [
        'shopee',
        'tokopedia',
        'lazada',
        'baju',
        'sepatu',
        'belanja',
        'online',
      ],
      TransactionCategory.entertainment: [
        'nonton',
        'bioskop',
        'netflix',
        'spotify',
        'game',
        'liburan',
        'konser',
      ],
      TransactionCategory.health: [
        'obat',
        'dokter',
        'klinik',
        'rumah sakit',
        'vitamin',
        'apotek',
      ],
      TransactionCategory.bills: [
        'listrik',
        'air',
        'internet',
        'wifi',
        'pln',
        'pdam',
        'tagihan',
        'pulsa',
        'token',
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
      RegExp(
        r'[\d]+(?:[.,]\d+)?\s*(?:juta?|jt|ribu?|rb|k)\b',
        caseSensitive: false,
      ),
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

  static const _particles = {
    'di', 'ke', 'dari', 'dan', 'atau', 'yang', 'untuk', 'dengan',
    'oleh', 'pada', 'dalam',
  };

  static String _toTitleCase(String s) {
    final words = s.trim().split(RegExp(r'\s+'));
    final result = <String>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;
      final lower = word.toLowerCase();
      if (i > 0 && _particles.contains(lower)) {
        result.add(lower);
      } else {
        result.add(lower[0].toUpperCase() + lower.substring(1));
      }
    }
    return result.join(' ');
  }

  static TransactionCategory _categoryFromString(
    String s,
    TransactionType type,
  ) {
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
