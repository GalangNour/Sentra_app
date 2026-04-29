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
import 'package:sentra_app/screens/add_installment_screen.dart';
import 'package:sentra_app/screens/installment_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstallmentsListScreen extends StatefulWidget {
  const InstallmentsListScreen({super.key});

  @override
  State<InstallmentsListScreen> createState() => _InstallmentsListScreenState();
}

class _InstallmentsListScreenState extends State<InstallmentsListScreen> {
  static const _prefKey = 'installment_hide_amounts';
  bool _hideAmounts = false;

  @override
  void initState() {
    super.initState();
    _loadHideState();
  }

  Future<void> _loadHideState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hideAmounts = prefs.getBool(_prefKey) ?? false);
    }
  }

  Future<void> _toggleHideAmounts() async {
    final newVal = !_hideAmounts;
    setState(() => _hideAmounts = newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, newVal);
  }

  FinanceSnapshot _snapshot(BuildContext context) {
    final s = FinanceSnapshot(
      transactions: context.watch<TransactionsCubit>().state.transactions,
      customCategories: context.watch<CategoriesCubit>().state.customCategories,
      installmentPlans: context
          .watch<InstallmentsCubit>()
          .state
          .installmentPlans,
      currency: context.watch<SettingsCubit>().state.currency,
    );
    s.applyCurrency();
    return s;
  }

  String _money(double amount, {bool compact = false}) {
    if (_hideAmounts) return '••••••';
    return compact ? Fmt.compact(amount) : Fmt.full(amount);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot(context);
    final plans = snapshot.activeInstallmentPlans;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (plans.isNotEmpty) _buildSummary(context, snapshot),
            Expanded(
              child: plans.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: plans.length,
                      itemBuilder: (_, i) =>
                          _buildCard(context, plans[i], snapshot),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddInstallmentScreen()),
          );
        },
        backgroundColor: AppColors.warning,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Cicilan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Cicilan Aktif',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: _hideAmounts ? 'Tampilkan nominal' : 'Sembunyikan nominal',
            onPressed: _toggleHideAmounts,
            icon: Icon(
              _hideAmounts
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, FinanceSnapshot snapshot) {
    final plans = snapshot.activeInstallmentPlans;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withAlpha(26), AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total sisa ${plans.length} cicilan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(snapshot.totalInstallmentOutstanding),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.textMuted,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada cicilan aktif',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap tombol di bawah untuk menambahkan',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    InstallmentPlan plan,
    FinanceSnapshot snapshot,
  ) {
    final remaining = snapshot.installmentRemaining(plan.id);
    final paid = snapshot.installmentPaidAmount(plan.id);
    final progress = snapshot.installmentProgress(plan.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InstallmentDetailScreen(plan: plan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sisa ${_money(remaining)} dari ${_money(plan.totalAmount)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sudah dibayar ${_money(paid, compact: true)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
