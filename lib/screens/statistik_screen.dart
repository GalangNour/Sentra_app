import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/activity_screen.dart';
import 'package:sentra_app/screens/sentra_brain_screen.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  String _activePeriod = '30 Hari';
  int _touchedPieIndex = -1;

  DateTimeRange get _dateRange {
    final now = DateTime.now();
    switch (_activePeriod) {
      case '7 Hari':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case '30 Hari':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
      case '3 Bulan':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 90)), end: now);
      case '1 Tahun':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 365)), end: now);
      default:
        return DateTimeRange(start: DateTime(2000), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions =
        context.watch<TransactionsCubit>().state.transactions;
    final customCategories =
        context.watch<CategoriesCubit>().state.customCategories;
    final installmentPlans =
        context.watch<InstallmentsCubit>().state.installmentPlans;
    final currency = context.watch<SettingsCubit>().state.currency;
    final range = _dateRange;

    final filteredTransactions = _activePeriod == 'Semua'
        ? allTransactions
        : allTransactions
            .where((tx) =>
                tx.date.isAfter(range.start) && tx.date.isBefore(range.end))
            .toList();

    final snapshot = FinanceSnapshot(
      transactions: filteredTransactions,
      customCategories: customCategories,
      installmentPlans: installmentPlans,
      currency: currency,
    );
    snapshot.applyCurrency();

    final prevEnd = range.start;
    final prevDuration = range.end.difference(range.start);
    final prevStart = prevEnd.subtract(prevDuration);
    final prevTransactions = _activePeriod == 'Semua'
        ? <Transaction>[]
        : allTransactions
            .where((tx) =>
                tx.date.isAfter(prevStart) && tx.date.isBefore(prevEnd))
            .toList();
    final prevSnapshot = FinanceSnapshot(
      transactions: prevTransactions,
      customCategories: customCategories,
      installmentPlans: installmentPlans,
      currency: currency,
    );
    prevSnapshot.applyCurrency();

    final income = snapshot.totalIncome;
    final expense = snapshot.totalExpense;
    final savings = income - expense;

    final prevIncome = prevSnapshot.totalIncome;
    final prevExpense = prevSnapshot.totalExpense;
    final incomeChangePct =
        prevIncome > 0 ? (income - prevIncome) / prevIncome * 100 : null;
    final expenseChangePct =
        prevExpense > 0 ? (expense - prevExpense) / prevExpense * 100 : null;

    final Map<String, double> catTotals = {};
    final Map<String, Color> catColors = {};
    final Map<String, IconData> catIcons = {};
    for (final tx
        in filteredTransactions.where((t) => t.type == TransactionType.expense)) {
      final key = tx.customCategoryId ?? tx.category.name;
      catTotals[key] = (catTotals[key] ?? 0) + tx.amount;
      catColors[key] = snapshot.categoryColor(tx);
      catIcons[key] = snapshot.categoryIcon(tx);
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = catTotals.values.fold(0.0, (a, b) => a + b);

    final trendData = _buildTrendData(filteredTransactions);

    // Installment burden uses all transactions (not period-filtered) so
    // paid-off status is always accurate regardless of the active period chip.
    final installmentSnapshot = FinanceSnapshot(
      transactions: allTransactions,
      customCategories: customCategories,
      installmentPlans: installmentPlans,
      currency: currency,
    );

    final controlScore = income > 0
        ? (100 - (expense / income * 100)).clamp(0.0, 100.0)
        : 0.0;
    final savingScore =
        income > 0 ? (savings / income * 100).clamp(0.0, 100.0) : 0.0;
    final consistencyScore = _calcConsistencyScore(filteredTransactions);
    final healthScore =
        ((controlScore + savingScore + consistencyScore) / 3).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodFilter(),
            const SizedBox(height: 16),
            _buildSummaryCard(
                income, expense, savings, incomeChangePct, expenseChangePct),
            if (installmentSnapshot.totalMonthlyInstallmentBurden > 0) ...[
              const SizedBox(height: 20),
              _buildInstallmentBurdenCard(installmentSnapshot),
            ],
            const SizedBox(height: 20),
            _buildCategorySection(
                sorted, catColors, catIcons, grandTotal, snapshot),
            const SizedBox(height: 20),
            _buildTrendSection(trendData),
            const SizedBox(height: 20),
            _buildInsightBanner(context, snapshot),
            const SizedBox(height: 20),
            _buildHealthScore(
                healthScore, controlScore, savingScore, consistencyScore),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Ringkasan keuanganmu ✦',
            style: TextStyle(
              color: AppColors.textSecondary.withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    const periods = ['7 Hari', '30 Hari', '3 Bulan', '1 Tahun', 'Semua'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = _activePeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _activePeriod = p;
                  _touchedPieIndex = -1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withAlpha(77),
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense, double savings,
      double? incomeChangePct, double? expenseChangePct) {
    final savingsRate = income > 0 ? savings / income * 100 : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Pemasukan',
                income,
                AppColors.income,
                Icons.arrow_downward_rounded,
                incomeChangePct,
                isIncome: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Pengeluaran',
                expense,
                AppColors.expense,
                Icons.arrow_upward_rounded,
                expenseChangePct,
                isIncome: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.balanceGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (savings >= 0 ? AppColors.income : AppColors.expense)
                  .withAlpha(60),
            ),
            boxShadow: [
              BoxShadow(
                color: (savings >= 0 ? AppColors.income : AppColors.expense)
                    .withAlpha(24),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Tabungan',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Fmt.full(savings),
                    style: TextStyle(
                      color: savings >= 0
                          ? AppColors.income
                          : AppColors.expense,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Savings Rate',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${savingsRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: savings >= 0
                          ? AppColors.income
                          : AppColors.expense,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, double amount, Color color, IconData icon,
      double? changePct, {required bool isIncome}) {
    Color? changeColor;
    String? changeText;
    if (changePct != null && _activePeriod != 'Semua') {
      final isPositive = changePct >= 0;
      final isGood = isIncome ? isPositive : !isPositive;
      changeColor = isGood ? AppColors.income : AppColors.expense;
      final arrow = isPositive ? '▲' : '▼';
      changeText =
          '$arrow ${changePct.abs().toStringAsFixed(1)}% dari periode lalu';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            Fmt.compact(amount),
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (changeText != null) ...[
            const SizedBox(height: 4),
            Text(
              changeText,
              style: TextStyle(color: changeColor, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallmentBurdenCard(FinanceSnapshot installmentSnapshot) {
    final plans = installmentSnapshot.activeInstallmentPlans
        .where((p) => p.monthlyAmount != null)
        .toList();
    final total = installmentSnapshot.totalMonthlyInstallmentBurden;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: 10),
              Text(
                'Beban Cicilan Bulanan',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Fmt.full(total),
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'total yang keluar tiap bulan',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ...plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Fmt.compact(p.monthlyAmount!),
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '/bln',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      List<MapEntry<String, double>> sorted,
      Map<String, Color> catColors,
      Map<String, IconData> catIcons,
      double grandTotal,
      FinanceSnapshot snapshot) {
    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data pengeluaran',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final top = sorted.take(6).toList();
    final othersTotal = sorted.length > 6
        ? sorted.skip(6).fold(0.0, (sum, e) => sum + e.value)
        : 0.0;

    final palette = [
      AppColors.primary,
      AppColors.income,
      AppColors.expense,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      AppColors.textMuted,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori Pengeluaran',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ActivityScreen()),
                );
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  sections: List.generate(
                      top.length + (othersTotal > 0 ? 1 : 0), (i) {
                    final isOthers = i == top.length;
                    final value = isOthers ? othersTotal : top[i].value;
                    final isTouched = i == _touchedPieIndex;
                    return PieChartSectionData(
                      color: palette[i % palette.length],
                      value: value,
                      title: '',
                      radius: isTouched ? 70 : 60,
                    );
                  }),
                  pieTouchData: PieTouchData(
                    touchCallback:
                        (FlTouchEvent event, PieTouchResponse? response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                  Text(
                    Fmt.compact(grandTotal),
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend — full width below pie chart
        ...List.generate(top.length, (i) {
          final pct = grandTotal > 0
              ? (top[i].value / grandTotal * 100).round()
              : 0;
          final label = _resolveLabel(top[i].key, snapshot);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: palette[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Fmt.compact(top[i].value),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        }),
        if (othersTotal > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: palette.last, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Lainnya',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textPrimary)),
                ),
                Text(
                  Fmt.compact(othersTotal),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(othersTotal / grandTotal * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _resolveLabel(String key, FinanceSnapshot snapshot) {
    if (key.contains('-')) {
      final c =
          snapshot.customCategories.where((c) => c.id == key).firstOrNull;
      return c?.name ?? 'Kustom';
    } else {
      try {
        return CategoryMeta.label(
          TransactionCategory.values.firstWhere((v) => v.name == key),
        );
      } catch (_) {
        return key;
      }
    }
  }

  Map<DateTime, Map<String, double>> _buildTrendData(
      List<Transaction> txs) {
    final Map<DateTime, Map<String, double>> result = {};
    for (final tx in txs) {
      final DateTime key;
      if (_activePeriod == '7 Hari' || _activePeriod == '30 Hari') {
        key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      } else if (_activePeriod == '3 Bulan') {
        final dayOfWeek = tx.date.weekday;
        final monday = tx.date.subtract(Duration(days: dayOfWeek - 1));
        key = DateTime(monday.year, monday.month, monday.day);
      } else {
        key = DateTime(tx.date.year, tx.date.month);
      }
      result.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      if (tx.type == TransactionType.income) {
        result[key]!['income'] = result[key]!['income']! + tx.amount;
      } else {
        result[key]!['expense'] = result[key]!['expense']! + tx.amount;
      }
    }
    return result;
  }

  Widget _buildTrendSection(Map<DateTime, Map<String, double>> trendData) {
    if (trendData.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Pemasukan vs Pengeluaran',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            alignment: Alignment.center,
            child: Text(
              'Belum cukup data untuk menampilkan tren',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      );
    }

    final sortedKeys = trendData.keys.toList()..sort();
    final incomeSpots = sortedKeys
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), trendData[e.value]!['income']!))
        .toList();
    final expenseSpots = sortedKeys
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), trendData[e.value]!['expense']!))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tren Pemasukan vs Pengeluaran',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 12, height: 3, color: AppColors.income),
          const SizedBox(width: 4),
          Text('Pemasukan',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Container(width: 12, height: 3, color: AppColors.expense),
          const SizedBox(width: 4),
          Text('Pengeluaran',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: sortedKeys.length > 8
                        ? (sortedKeys.length / 4).ceilToDouble()
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= sortedKeys.length) {
                        return const SizedBox();
                      }
                      final date = sortedKeys[idx];
                      final label = _activePeriod == '1 Tahun' ||
                              _activePeriod == 'Semua'
                          ? '${date.month}/${date.year.toString().substring(2)}'
                          : '${date.day}/${date.month}';
                      return Text(label,
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted));
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceElevated,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                          Fmt.compact(s.y),
                          const TextStyle(
                              color: Colors.white, fontSize: 11)))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.income,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.income.withAlpha(26)),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.expense,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.expense.withAlpha(26)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBanner(
      BuildContext context, FinanceSnapshot snapshot) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SentraBrainScreen(snapshot: snapshot),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insight AI',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    'Tanya Sentra Brain tentang statistik keuanganmu',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScore(int healthScore, double controlScore,
      double savingScore, double consistencyScore) {
    final scoreColor = healthScore >= 80
        ? AppColors.income
        : healthScore >= 60
            ? Colors.orange
            : AppColors.expense;
    final scoreLabel = healthScore >= 80
        ? 'Baik'
        : healthScore >= 60
            ? 'Cukup'
            : 'Perlu Perhatian';
    final scoreDesc = healthScore >= 80
        ? 'Keuanganmu dalam kondisi baik! Pertahankan kebiasaan ini ya.'
        : healthScore >= 60
            ? 'Keuanganmu cukup sehat. Ada beberapa area yang bisa ditingkatkan.'
            : 'Keuanganmu perlu perhatian lebih. Coba konsultasi ke Sentra Brain.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skor Kesehatan Keuangan',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$healthScore',
              style: TextStyle(
                  color: scoreColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('/100',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                        color: scoreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildScoreBar('Pengeluaran Terkontrol', controlScore),
        const SizedBox(height: 10),
        _buildScoreBar('Tabungan', savingScore),
        const SizedBox(height: 10),
        _buildScoreBar('Konsistensi', consistencyScore),
        const SizedBox(height: 12),
        Text(scoreDesc,
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            Text('${score.round()}/100',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score / 100),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              backgroundColor: AppColors.surfaceElevated,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  double _calcConsistencyScore(List<Transaction> txs) {
    if (txs.isEmpty) return 0;
    final weeks = <int>{};
    for (final tx in txs) {
      final weekNum = _weekNumber(tx.date);
      weeks.add(tx.date.year * 100 + weekNum);
    }
    final range = _dateRange;
    final totalDays = range.end.difference(range.start).inDays;
    final totalWeeks = (totalDays / 7).ceil().clamp(1, 9999);
    return (weeks.length / totalWeeks * 100).clamp(0.0, 100.0);
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return (diff / 7).ceil();
  }
}
