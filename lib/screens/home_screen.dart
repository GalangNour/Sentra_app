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
import 'package:sentra_app/screens/add_transaction_screen.dart';
import 'package:sentra_app/screens/installments_list_screen.dart';
import 'package:sentra_app/screens/sentra_brain_screen.dart';
import 'package:sentra_app/widgets/insight_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FinanceSnapshot _snapshot;

  FinanceSnapshot _watchSnapshot() {
    return FinanceSnapshot(
      transactions: context.watch<TransactionsCubit>().state.transactions,
      customCategories: context.watch<CategoriesCubit>().state.customCategories,
      installmentPlans: context
          .watch<InstallmentsCubit>()
          .state
          .installmentPlans,
      currency: context.watch<SettingsCubit>().state.currency,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openAddTransaction({
    TransactionType type = TransactionType.expense,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }

  Future<void> _openInstallments() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InstallmentsListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    _snapshot = _watchSnapshot();
    _snapshot.applyCurrency();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.primaryGradient.createShader(b),
              child: const Text(
                'Sentra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Text(
              'Budget & Keuangan ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _buildHomeTab(),
    );
  }

  // ─── HOME TAB ────────────────────────────────────────────

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildBalanceCard()),
        SliverToBoxAdapter(child: _buildQuickAdd()),
        SliverToBoxAdapter(child: _buildSentraBrainCard()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: InsightSection(snapshot: _snapshot),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.balanceHeroGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(
              ThemeConfig.current.isDark ? 30 : 18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _snapshot.currency.code,
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Fmt.full(_snapshot.balance),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  'Pemasukan',
                  _snapshot.totalIncome,
                  AppColors.income,
                  Icons.arrow_downward_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceElevated),
              Expanded(
                child: _balanceStat(
                  'Pengeluaran',
                  _snapshot.totalExpense,
                  AppColors.expense,
                  Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String label, double amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                Fmt.compact(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: _buildActionButtons(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _secondaryBtn(
                'Pengeluaran',
                AppColors.expense,
                Icons.remove_circle_outline_rounded,
                () => _openAddTransaction(type: TransactionType.expense),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _secondaryBtn(
                'Pemasukan',
                AppColors.income,
                Icons.add_circle_outline_rounded,
                () => _openAddTransaction(type: TransactionType.income),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _secondaryBtn(
            'Cicilan',
            AppColors.warning,
            Icons.payments_rounded,
            _openInstallments,
          ),
        ),
      ],
    );
  }

  Widget _secondaryBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentraBrainCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SentraBrainScreen(snapshot: _snapshot),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sentra Brain',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanya apapun soal keuanganmu',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
