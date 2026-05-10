import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';

class StatistikScreen extends StatelessWidget {
  const StatistikScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = FinanceSnapshot(
      transactions: context.watch<TransactionsCubit>().state.transactions,
      customCategories: context.watch<CategoriesCubit>().state.customCategories,
      installmentPlans:
          context.watch<InstallmentsCubit>().state.installmentPlans,
      currency: context.watch<SettingsCubit>().state.currency,
    );
    snapshot.applyCurrency();

    final txs = snapshot.transactions;
    final income = snapshot.totalIncome;
    final expense = snapshot.totalExpense;
    final savings = income - expense;
    final savingsRate = income > 0 ? savings / income * 100 : 0.0;

    final Map<String, double> catTotals = {};
    final Map<String, Color> catColors = {};
    final Map<String, IconData> catIcons = {};
    for (final tx in txs.where((t) => t.type == TransactionType.expense)) {
      final key = tx.customCategoryId ?? tx.category.name;
      catTotals[key] = (catTotals[key] ?? 0) + tx.amount;
      catColors[key] = snapshot.categoryColor(tx);
      catIcons[key] = snapshot.categoryIcon(tx);
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = catTotals.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Pemasukan',
                  income,
                  AppColors.income,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Pengeluaran',
                  expense,
                  AppColors.expense,
                  Icons.arrow_upward_rounded,
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
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
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
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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

          if (sorted.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Pengeluaran per Kategori',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...sorted.take(8).map((e) {
              final color = catColors[e.key] ?? AppColors.primary;
              final icon = catIcons[e.key] ?? Icons.more_horiz_rounded;
              final pct = grandTotal > 0 ? e.value / grandTotal : 0.0;

              String label;
              if (e.key.contains('-')) {
                final c = snapshot.customCategories
                    .where((c) => c.id == e.key)
                    .firstOrNull;
                label = c?.name ?? 'Kustom';
              } else {
                try {
                  label = CategoryMeta.label(
                    TransactionCategory.values.firstWhere(
                      (v) => v.name == e.key,
                    ),
                  );
                } catch (_) {
                  label = e.key;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                Fmt.compact(e.value),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: v,
                                backgroundColor: AppColors.surfaceElevated,
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Belum ada data pengeluaran',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _statCard(String label, double amount, Color color, IconData icon) {
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
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
