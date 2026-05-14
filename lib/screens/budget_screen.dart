import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/constants/category_meta.dart';
import 'package:sentra_app/core/models/budget_item.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/formatters.dart';
import 'package:sentra_app/features/budgets/cubit/budgets_cubit.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/widgets/add_budget_sheet.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const _months = [
    '',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  FinanceSnapshot _buildSnapshot(BuildContext context) {
    return FinanceSnapshot(
      transactions: context.watch<TransactionsCubit>().state.transactions,
      customCategories:
          context.watch<CategoriesCubit>().state.customCategories,
      installmentPlans:
          context.watch<InstallmentsCubit>().state.installmentPlans,
      currency: context.watch<SettingsCubit>().state.currency,
      budgets: context.watch<BudgetsCubit>().state.budgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = _buildSnapshot(context);
    snap.applyCurrency();

    final now = DateTime.now();
    final budgets = snap.budgetsThisMonth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_months[now.month]} ${now.year} ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          AddBudgetSheet.show(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: budgets.isEmpty
          ? _buildEmptyState(context)
          : _buildBudgetList(context, snap, budgets),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada budget',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Atur limit pengeluaran per kategori\nuntuk kontrol keuanganmu.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                AddBudgetSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Atur Budget Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    FinanceSnapshot snap,
    List<BudgetItem> budgets,
  ) {
    final customCategories = context.read<CategoriesCubit>().state.customCategories;

    final overBudget = budgets.where((b) => snap.budgetProgress(b) > 1).toList();
    final warning = budgets
        .where((b) {
          final p = snap.budgetProgress(b);
          return p > 0.8 && p <= 1;
        })
        .toList();
    final normal = budgets
        .where((b) => snap.budgetProgress(b) <= 0.8)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (overBudget.isNotEmpty) ...[
          _sectionLabel('Melebihi Limit', AppColors.expense),
          const SizedBox(height: 10),
          for (final b in overBudget) ...[
            _budgetCard(context, snap, b, customCategories),
            const SizedBox(height: 10),
          ],
        ],
        if (warning.isNotEmpty) ...[
          if (overBudget.isNotEmpty) const SizedBox(height: 8),
          _sectionLabel('Hampir Habis', AppColors.warning),
          const SizedBox(height: 10),
          for (final b in warning) ...[
            _budgetCard(context, snap, b, customCategories),
            const SizedBox(height: 10),
          ],
        ],
        if (normal.isNotEmpty) ...[
          if (overBudget.isNotEmpty || warning.isNotEmpty)
            const SizedBox(height: 8),
          _sectionLabel('Aman', AppColors.income),
          const SizedBox(height: 10),
          for (final b in normal) ...[
            _budgetCard(context, snap, b, customCategories),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _budgetCard(
    BuildContext context,
    FinanceSnapshot snap,
    BudgetItem budget,
    List<CustomCategory> customCategories,
  ) {
    final progress = snap.budgetProgress(budget).clamp(0.0, 1.5);
    final spent = snap.spentForBudget(budget);
    final color = _budgetColor(snap.budgetProgress(budget));

    String label;
    IconData icon;
    Color catColor;

    if (budget.customCategoryId != null) {
      final custom = customCategories.firstWhere(
        (c) => c.id == budget.customCategoryId,
        orElse: () => CustomCategory(
          id: '',
          name: 'Kustom',
          iconCode: Icons.label_rounded.codePoint,
          fontFamily: 'MaterialIcons',
          colorValue: AppColors.primary.toARGB32(),
          type: TransactionType.expense,
        ),
      );
      label = custom.name;
      icon = custom.icon;
      catColor = custom.color;
    } else {
      label = CategoryMeta.label(budget.category!);
      icon = CategoryMeta.icon(budget.category!);
      catColor = CategoryMeta.color(budget.category!);
    }

    final pctText = '${(snap.budgetProgress(budget) * 100).toStringAsFixed(0)}%';

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, budget, label),
      onTap: () {
        HapticFeedback.selectionClick();
        AddBudgetSheet.show(context, existingBudget: budget);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withAlpha(64)),
                  ),
                  child: Icon(icon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Fmt.compact(spent)} dari ${Fmt.compact(budget.limit)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(64)),
                  ),
                  child: Text(
                    pctText,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _budgetColor(double progress) {
    if (progress > 1.0) return AppColors.expense;
    if (progress > 0.8) return AppColors.warning;
    return AppColors.income;
  }

  void _confirmDelete(
    BuildContext context,
    BudgetItem budget,
    String label,
  ) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Hapus Budget',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Hapus budget untuk "$label"?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BudgetsCubit>().deleteBudget(budget.id);
              HapticFeedback.mediumImpact();
            },
            child: Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
