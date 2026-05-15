import 'package:flutter/material.dart';
import 'package:sentra_app/core/constants/category_meta.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/transaction.dart';

class CategoryBreakdown {
  final String label;
  final IconData icon;
  final Color color;
  final double amount;
  final double percentage;

  const CategoryBreakdown({
    required this.label,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}

class RecapData {
  final double thisWeekExpense;
  final double lastWeekExpense;
  final double changePercent;
  final List<CategoryBreakdown> top3Categories;
  final String? busiestDayName;
  final double busiestDayAmount;
  final Transaction? biggestTransaction;
  final String closingLine;

  const RecapData({
    required this.thisWeekExpense,
    required this.lastWeekExpense,
    required this.changePercent,
    required this.top3Categories,
    this.busiestDayName,
    required this.busiestDayAmount,
    this.biggestTransaction,
    required this.closingLine,
  });
}

class RecapService {
  static const _dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  static RecapData compute({
    required List<Transaction> transactions,
    required List<CustomCategory> customCategories,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(const Duration(days: 6));
    final lastWeekStart = today.subtract(const Duration(days: 13));

    bool inThisWeek(DateTime d) => !d.isBefore(thisWeekStart) && !d.isAfter(now);
    bool inLastWeek(DateTime d) => !d.isBefore(lastWeekStart) && d.isBefore(thisWeekStart);

    final thisWeekExpenses = transactions
        .where((t) => t.type == TransactionType.expense && inThisWeek(t.date))
        .toList();
    final lastWeekExpenses = transactions
        .where((t) => t.type == TransactionType.expense && inLastWeek(t.date))
        .toList();

    final thisWeekTotal = thisWeekExpenses.fold(0.0, (s, t) => s + t.amount);
    final lastWeekTotal = lastWeekExpenses.fold(0.0, (s, t) => s + t.amount);

    final changePercent = lastWeekTotal == 0
        ? (thisWeekTotal > 0 ? 100.0 : 0.0)
        : (thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100.0;

    // Category totals
    final catAmounts = <String, double>{};
    for (final t in thisWeekExpenses) {
      final key = t.customCategoryId ?? t.category.name;
      catAmounts[key] = (catAmounts[key] ?? 0) + t.amount;
    }
    final sortedCats = catAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sortedCats.take(3).map((entry) {
      final pct = thisWeekTotal == 0 ? 0.0 : entry.value / thisWeekTotal;
      return CategoryBreakdown(
        label: _resolveLabel(entry.key, customCategories),
        icon: _resolveIcon(entry.key, customCategories),
        color: _resolveColor(entry.key, customCategories),
        amount: entry.value,
        percentage: pct,
      );
    }).toList();

    // Busiest day
    final dayAmounts = <int, double>{};
    for (final t in thisWeekExpenses) {
      dayAmounts[t.date.weekday] = (dayAmounts[t.date.weekday] ?? 0) + t.amount;
    }
    String? busiestDayName;
    double busiestDayAmount = 0;
    if (dayAmounts.isNotEmpty) {
      final best = dayAmounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      busiestDayName = _dayNames[best.key];
      busiestDayAmount = best.value;
    }

    // Biggest transaction
    Transaction? biggestTx;
    if (thisWeekExpenses.isNotEmpty) {
      biggestTx = thisWeekExpenses.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    return RecapData(
      thisWeekExpense: thisWeekTotal,
      lastWeekExpense: lastWeekTotal,
      changePercent: changePercent,
      top3Categories: top3,
      busiestDayName: busiestDayName,
      busiestDayAmount: busiestDayAmount,
      biggestTransaction: biggestTx,
      closingLine: _generateClosing(thisWeekTotal, changePercent),
    );
  }

  static String _resolveLabel(String key, List<CustomCategory> customs) {
    final custom = customs.where((c) => c.id == key).firstOrNull;
    if (custom != null) return custom.name;
    try {
      return CategoryMeta.label(TransactionCategory.values.firstWhere((e) => e.name == key));
    } catch (_) {
      return 'Lainnya';
    }
  }

  static IconData _resolveIcon(String key, List<CustomCategory> customs) {
    final custom = customs.where((c) => c.id == key).firstOrNull;
    if (custom != null) return custom.icon;
    try {
      return CategoryMeta.icon(TransactionCategory.values.firstWhere((e) => e.name == key));
    } catch (_) {
      return Icons.more_horiz_rounded;
    }
  }

  static Color _resolveColor(String key, List<CustomCategory> customs) {
    final custom = customs.where((c) => c.id == key).firstOrNull;
    if (custom != null) return custom.color;
    try {
      return CategoryMeta.color(TransactionCategory.values.firstWhere((e) => e.name == key));
    } catch (_) {
      return const Color(0xFF8892B0);
    }
  }

  static String _generateClosing(double total, double change) {
    if (total == 0) return 'Minggu yang hemat! Tidak ada pengeluaran tercatat minggu ini.';
    if (change < -20) return 'Luar biasa! Pengeluaranmu turun signifikan. Terus pertahankan disiplin finansialmu!';
    if (change < 0) return 'Kamu berhasil mengontrol pengeluaran lebih baik dari minggu lalu. Bagus!';
    if (change > 30) return 'Pengeluaranmu meningkat cukup banyak minggu ini. Coba evaluasi kebiasaanmu ya.';
    if (change > 0) return 'Pengeluaran sedikit naik, tapi masih dalam batas wajar. Tetap bijak ya!';
    return 'Pengeluaranmu stabil dibanding minggu lalu. Konsistensi adalah kunci!';
  }
}
