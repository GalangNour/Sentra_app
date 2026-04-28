import 'dart:async';

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
import 'package:sentra_app/screens/add_transaction_screen.dart';
import 'package:sentra_app/screens/camera_screen.dart';
import 'package:sentra_app/screens/installment_detail_screen.dart';
import 'package:sentra_app/screens/settings_screen.dart';
import 'package:sentra_app/screens/transaction_detail_screen.dart';
import 'package:sentra_app/screens/installments_list_screen.dart';
import 'package:sentra_app/screens/quick_input_screen.dart';
import 'package:sentra_app/screens/transactions_screen.dart';
import 'package:sentra_app/widgets/transaction_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;
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
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    HapticFeedback.mediumImpact();
    await _fabCtrl.forward();
    await _fabCtrl.reverse();
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const CameraScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
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

  Future<void> _openDetail(Transaction tx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openAddInstallment() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddInstallmentScreen()));
  }

  Future<void> _openInstallmentDetail(InstallmentPlan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InstallmentDetailScreen(plan: plan)),
    );
  }

  Future<void> _openQuickInput() async {
    HapticFeedback.selectionClick();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuickInputScreen()));
  }

  Future<void> _openAllTransactions() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TransactionsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    _snapshot = _watchSnapshot();
    _snapshot.applyCurrency();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tabIndex,
        children: [_buildHomeTab(), _buildStatsTab()],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── HOME TAB ────────────────────────────────────────────

  Widget _buildHomeTab() {
    final txs = _snapshot.transactions;
    final recentTxs = txs.take(5).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildBalanceCard()),
        SliverToBoxAdapter(child: _buildQuickAdd()),
        SliverToBoxAdapter(child: _buildInstallmentSection()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terakhir',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (txs.isNotEmpty)
                  TextButton(
                    onPressed: _openAllTransactions,
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (txs.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyState())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              if (i >= recentTxs.length) return const SizedBox(height: 100);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTxCard(recentTxs[i], i),
              );
            }, childCount: recentTxs.length + 1),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient.createShader(b),
                child: const Text(
                  'Sentra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                'Budget & Keuangan',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              _headerBtn(Icons.settings_outlined, onTap: _openSettings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3E), Color(0xFF252D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiActionsCard(
            onQuickInput: _openQuickInput,
            onScan: _openCamera,
          ),
          const SizedBox(height: 10),
          _buildSecondaryActions(),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: _secondaryBtn(
            '− Pengeluaran',
            AppColors.expense,
            Icons.remove_circle_outline_rounded,
            () => _openAddTransaction(type: TransactionType.expense),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _secondaryBtn(
            '+ Pemasukan',
            AppColors.income,
            Icons.add_circle_outline_rounded,
            () => _openAddTransaction(type: TransactionType.income),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentSection() {
    final plans = _snapshot.activeInstallmentPlans;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cicilan Aktif',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (plans.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${plans.length} aktif',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
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
                        child: Text(
                          'Belum ada cicilan aktif',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambahkan utang atau cicilan, lalu saat membuat pengeluaran pilih cicilan yang ingin dibayar.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InstallmentsListScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withAlpha(26),
                      AppColors.surfaceCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.warning.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa total cicilan',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Fmt.full(_snapshot.totalInstallmentOutstanding),
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba Ketik Cepat dengan AI atau\nscan struk belanjamu di atas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(Transaction tx, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: AppColors.expense.withAlpha(38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.expense,
          ),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              title: Text(
                'Hapus transaksi?',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: AppColors.expense),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          await context.read<TransactionsCubit>().deleteTransaction(tx.id);
        },
        child: TransactionListItem(
          transaction: tx,
          dateLabel: Fmt.timeAgo(tx.date),
          onTap: () => _openDetail(tx),
          margin: const EdgeInsets.only(top: 10),
        ),
      ),
    );
  }

  // ─── STATS TAB ───────────────────────────────────────────

  Widget _buildStatsTab() {
    final txs = _snapshot.transactions;
    final income = _snapshot.totalIncome;
    final expense = _snapshot.totalExpense;
    final savings = income - expense;
    final savingsRate = income > 0 ? savings / income * 100 : 0.0;

    final Map<String, double> catTotals = {};
    final Map<String, Color> catColors = {};
    final Map<String, IconData> catIcons = {};
    for (final tx in txs.where((t) => t.type == TransactionType.expense)) {
      final key = tx.customCategoryId ?? tx.category.name;
      catTotals[key] = (catTotals[key] ?? 0) + tx.amount;
      catColors[key] = _snapshot.categoryColor(tx);
      catIcons[key] = _snapshot.categoryIcon(tx);
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = catTotals.values.fold(0.0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ringkasan keuangan kamu',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),

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
              gradient: savings >= 0
                  ? AppColors.incomeGradient
                  : AppColors.expenseGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (savings >= 0 ? AppColors.income : AppColors.expense)
                      .withAlpha(51),
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
                    const Text(
                      'Total Tabungan',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.full(savings),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Savings Rate',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${savingsRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
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
                final c = _snapshot.customCategories
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
                            builder: (_, v, __) => ClipRRect(
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

  Widget _buildInstallmentCard(InstallmentPlan plan) {
    final remaining = _snapshot.installmentRemaining(plan.id);
    final paid = _snapshot.installmentPaidAmount(plan.id);
    final progress = _snapshot.installmentProgress(plan.id);
    return GestureDetector(
      onTap: () => _openInstallmentDetail(plan),
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
                  width: 38,
                  height: 38,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sisa ${Fmt.full(remaining)} dari ${Fmt.full(plan.totalAmount)}',
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
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
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sudah dibayar ${Fmt.compact(paid)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Beranda',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: ScaleTransition(
                  scale: _fabScale,
                  child: GestureDetector(
                    onTap: () async {
                      await _fabCtrl.forward();
                      await _fabCtrl.reverse();
                      if (mounted) _openQuickInput();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(115),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _navItem(
                  1,
                  Icons.bar_chart_rounded,
                  Icons.bar_chart_outlined,
                  'Statistik',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int idx,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final sel = _tabIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = idx),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary.withAlpha(31) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sel ? activeIcon : inactiveIcon,
              color: sel ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: sel ? AppColors.primary : AppColors.textMuted,
              fontSize: 11,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _AiActionsCard ──────────────────────────────────────

class _AiActionsCard extends StatefulWidget {
  final VoidCallback onQuickInput;
  final VoidCallback onScan;
  const _AiActionsCard({required this.onQuickInput, required this.onScan});

  @override
  State<_AiActionsCard> createState() => _AiActionsCardState();
}

class _AiActionsCardState extends State<_AiActionsCard> {
  static const _examples = [
    'kemarin beli kopi 15rb',
    'bensin 30k tadi pagi, beli lagi 20k',
    'gajian bulan ini 5jt',
    'bayar listrik 200rb',
    'nonton bioskop 54rb',
  ];

  int _idx = 0;
  int _chars = 0;
  bool _erasing = false;
  bool _cursorOn = true;
  Timer? _typeTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) { if (mounted) setState(() => _cursorOn = !_cursorOn); },
    );
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    _typeTimer = Timer(
      _erasing
          ? const Duration(milliseconds: 32)
          : const Duration(milliseconds: 72),
      _onTick,
    );
  }

  void _onTick() {
    if (!mounted) return;
    final text = _examples[_idx];
    if (!_erasing) {
      if (_chars < text.length) {
        setState(() => _chars++);
        _scheduleNext();
      } else {
        _typeTimer = Timer(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          setState(() => _erasing = true);
          _scheduleNext();
        });
      }
    } else {
      if (_chars > 0) {
        setState(() => _chars--);
        _scheduleNext();
      } else {
        setState(() {
          _erasing = false;
          _idx = (_idx + 1) % _examples.length;
        });
        _typeTimer = Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          _scheduleNext();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typed = _examples[_idx].substring(0, _chars);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(22),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Gradient header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 6),
                const Text(
                  'AI · Catat Transaksi Cepat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // ── Ketik Cepat row ──
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onQuickInput();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketik Cepat',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: typed.isEmpty
                                    ? 'Ceritakan transaksimu...'
                                    : '"$typed',
                                style: TextStyle(
                                  color: typed.isEmpty
                                      ? AppColors.textMuted
                                      : AppColors.primaryLight,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (typed.isNotEmpty)
                                TextSpan(
                                  text: _cursorOn ? '|' : ' ',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          // ── Divider ──
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 74),
            color: AppColors.surfaceBorder,
          ),
          // ── Scan Struk row ──
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onScan();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Scan Struk',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OCR',
                                style: TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Foto struk belanja, data terisi otomatis',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
