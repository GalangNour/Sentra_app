import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/ai_insight.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/services/ai_service.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/utils/formatters.dart';

class InsightService {
  static const _cacheDuration = Duration(hours: 24);
  static const _lastGeneratedKey = '_last_generated';

  static Future<void> clearCache(Box box) async {
    await box.clear();
    debugPrint('[InsightService] cache dihapus');
  }

  static bool needsRefresh(Box box) {
    final lastStr = box.get(_lastGeneratedKey) as String?;
    if (lastStr == null) {
      debugPrint('[InsightService] needsRefresh=true (belum pernah generate)');
      return true;
    }
    final last = DateTime.parse(lastStr);
    final age = DateTime.now().difference(last);
    final stale = age > _cacheDuration;
    debugPrint('[InsightService] needsRefresh=$stale (umur cache: ${age.inMinutes} menit)');
    return stale;
  }

  static List<AiInsight> getCached(Box box) {
    final result = <AiInsight>[];
    for (final key in box.keys) {
      if (key == _lastGeneratedKey) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        result.add(AiInsight.fromMap(Map<String, dynamic>.from(raw as Map)));
      } catch (e) {
        debugPrint('[InsightService] getCached: gagal parse key=$key → $e');
      }
    }
    result.sort((a, b) => a.generatedAt.compareTo(b.generatedAt));
    debugPrint('[InsightService] getCached: ${result.length} insight dari cache');
    return result;
  }

  static Future<List<AiInsight>> generateAndCache(
    Box box,
    FinanceSnapshot snapshot,
  ) async {
    debugPrint('[InsightService] generateAndCache: mulai...');
    try {
      final systemContext = _buildInsightContext(snapshot);
      debugPrint('[InsightService] systemContext length=${systemContext.length}');

      debugPrint('[InsightService] memanggil AiService.sendMessage...');
      final raw = await AiService.sendMessage(
        systemContext: systemContext,
        history: [],
        userMessage: 'Generate insight keuangan untuk user ini sekarang.',
        maxOutputTokens: 8192,
      );
      debugPrint('[InsightService] raw response (${raw.length} chars): ${raw.substring(0, raw.length.clamp(0, 300))}');

      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      debugPrint('[InsightService] cleaned JSON: ${cleaned.substring(0, cleaned.length.clamp(0, 300))}');

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final insightsList = parsed['insights'] as List?;
      debugPrint('[InsightService] jumlah insight dari AI: ${insightsList?.length ?? 0}');

      if (insightsList == null || insightsList.isEmpty) {
        debugPrint('[InsightService] insights kosong, pakai cache');
        return getCached(box);
      }

      final now = DateTime.now();
      final insights = insightsList.take(3).map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return AiInsight(
          icon: m['icon'] as String? ?? '💡',
          title: m['title'] as String? ?? '',
          subtitle: m['subtitle'] as String? ?? '',
          type: m['type'] as String? ?? 'tip',
          tapPrompt: m['tapPrompt'] as String? ?? '',
          generatedAt: now,
        );
      }).toList();

      // Replace old insights
      final oldKeys = box.keys.where((k) => k != _lastGeneratedKey).toList();
      for (final k in oldKeys) {
        await box.delete(k);
      }
      for (int i = 0; i < insights.length; i++) {
        await box.put('insight_$i', insights[i].toMap());
        debugPrint('[InsightService] disimpan: [${insights[i].icon}] ${insights[i].title}');
      }
      await box.put(_lastGeneratedKey, now.toIso8601String());

      debugPrint('[InsightService] generateAndCache selesai: ${insights.length} insight');
      return insights;
    } catch (e, st) {
      debugPrint('[InsightService] ERROR: $e');
      debugPrint('[InsightService] stacktrace: $st');
      return getCached(box);
    }
  }

  static String _buildInsightContext(FinanceSnapshot snapshot) {
    final now = DateTime.now();

    final thisMonth = snapshot.transactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();
    final lastMonth = snapshot.transactions.where((tx) {
      final prev = DateTime(now.year, now.month - 1);
      return tx.date.year == prev.year && tx.date.month == prev.month;
    }).toList();

    double sumByType(List<Transaction> txs, TransactionType t) =>
        txs.where((tx) => tx.type == t).fold(0.0, (s, tx) => s + tx.amount);

    final thisIncome = sumByType(thisMonth, TransactionType.income);
    final thisExpense = sumByType(thisMonth, TransactionType.expense);
    final lastExpense = sumByType(lastMonth, TransactionType.expense);

    final Map<String, double> catTotals = {};
    for (final tx in thisMonth.where((t) => t.type == TransactionType.expense)) {
      final label = snapshot.categoryLabel(tx);
      catTotals[label] = (catTotals[label] ?? 0) + tx.amount;
    }
    final sortedCats = (catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5);

    final catLines = sortedCats.isEmpty
        ? '(belum ada pengeluaran)'
        : sortedCats.map((e) => '- ${e.key}: ${Fmt.full(e.value)}').join('\n');

    final recent = snapshot.transactions.take(15).toList();
    final txLines = recent.isEmpty
        ? '(belum ada transaksi)'
        : recent.asMap().entries.map((e) {
            final tx = e.value;
            final typeStr = tx.type == TransactionType.income ? 'Masuk' : 'Keluar';
            return '${e.key + 1}. [${Fmt.date(tx.date)}] ${tx.title} — $typeStr ${Fmt.full(tx.amount)} (${snapshot.categoryLabel(tx)})';
          }).join('\n');

    final monthName = _monthName(now.month);

    return '''Kamu adalah analis keuangan personal. Berikut adalah data keuangan user untuk bulan $monthName ${now.year}:

RINGKASAN KEUANGAN:
- Pemasukan bulan ini: ${Fmt.full(thisIncome)}
- Pengeluaran bulan ini: ${Fmt.full(thisExpense)}
- Pengeluaran bulan lalu: ${Fmt.full(lastExpense)}
- Total saldo: ${Fmt.full(snapshot.balance)}

PENGELUARAN PER KATEGORI BULAN INI:
$catLines

15 TRANSAKSI TERBARU:
$txLines

TUGAS:
Generate tepat 3 insight keuangan yang actionable dan personal berdasarkan data di atas.

FORMAT RESPONS (JSON valid saja, tidak ada teks lain, tidak ada markdown code block):
{
  "insights": [
    {
      "icon": "🍔",
      "title": "Pengeluaran makan naik 23%",
      "subtitle": "dari bulan lalu",
      "type": "warning",
      "tapPrompt": "Kenapa pengeluaran makan aku naik bulan ini?"
    }
  ]
}

ATURAN:
- Selalu berdasarkan data nyata — jangan generik
- "warning": pengeluaran naik, mendekati limit, pola boros
- "tip": saran hemat spesifik berdasarkan data
- "action": ajakan melakukan sesuatu yang beneficial
- title maksimal 35 karakter
- subtitle maksimal 45 karakter
- tapPrompt adalah pertanyaan natural yang akan dikirim ke chatbot keuangan
- Gunakan angka spesifik dari data jika memungkinkan
- Bahasa Indonesia santai
- Kembalikan HANYA JSON valid, tidak ada teks lain di luar JSON''';
  }

  static String _monthName(int month) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
  }
}
