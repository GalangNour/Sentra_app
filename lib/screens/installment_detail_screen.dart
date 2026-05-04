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
import 'package:sentra_app/screens/transaction_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final InstallmentPlan plan;

  const InstallmentDetailScreen({super.key, required this.plan});

  @override
  State<InstallmentDetailScreen> createState() =>
      _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  static const _prefKey = 'installment_hide_amounts';
  late FinanceSnapshot _snapshot;
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

  InstallmentPlan get _plan =>
      _snapshot.installmentById(widget.plan.id) ?? widget.plan;

  List<Transaction> get _payments => _snapshot.installmentPayments(_plan.id);
  double get _paid => _snapshot.installmentPaidAmount(_plan.id);
  double get _remaining => _snapshot.installmentRemaining(_plan.id);
  double get _progress => _snapshot.installmentProgress(_plan.id);
  bool get _isPaidOff => _snapshot.installmentIsPaidOff(_plan.id);

  String _money(double amount, {bool compact = false}) {
    if (_hideAmounts) return '••••••';
    return compact ? Fmt.compact(amount) : Fmt.full(amount);
  }

  Future<void> _openAddPayment() async {
    if (_isPaidOff) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: TransactionType.expense,
          initialInstallmentPlanId: _plan.id,
        ),
      ),
    );
  }

  Future<void> _openTransaction(Transaction tx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
  }

  Future<void> _editPlan() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddInstallmentScreen(editPlan: _plan),
      ),
    );
  }

  Future<void> _deletePlan() async {
    HapticFeedback.mediumImpact();
    final option = await showDialog<_DeleteOption>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        planName: _plan.name,
        paymentCount: _payments.length,
        paidAmount: _paid,
      ),
    );
    if (option == null || !mounted) return;

    if (option == _DeleteOption.planAndPayments) {
      if (!mounted) return;
      await context
          .read<TransactionsCubit>()
          .deleteTransactionsByPlanId(_plan.id);
    }
    if (!mounted) return;
    await context.read<InstallmentsCubit>().deleteInstallmentPlan(_plan.id);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _snapshot = _watchSnapshot();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
                  if (_plan.note != null && _plan.note!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildNoteCard(),
                  ],
                  const SizedBox(height: 24),
                  _buildPaymentHeader(),
                  const SizedBox(height: 12),
                  if (_payments.isEmpty)
                    _buildEmptyPayments()
                  else
                    ..._payments.map(_buildPaymentCard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      title: Text(
        'Detail Cicilan',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
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
        IconButton(
          tooltip: 'Edit cicilan',
          onPressed: _editPlan,
          icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
        ),
        IconButton(
          tooltip: 'Hapus cicilan',
          onPressed: _deletePlan,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
        ),
        if (!_isPaidOff)
          GestureDetector(
            onTap: _openAddPayment,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(70)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, size: 14, color: AppColors.warning),
                  SizedBox(width: 5),
                  Text(
                    'Bayar',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withAlpha(24), AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.warning,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plan.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPaidOff ? 'Lunas' : 'Masih berjalan',
                      style: TextStyle(
                        color: _isPaidOff
                            ? AppColors.income
                            : AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Sisa cicilan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _money(_remaining),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isPaidOff ? AppColors.income : AppColors.warning,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% selesai',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          _summaryRow('Total Cicilan', _money(_plan.totalAmount)),
          _divider(),
          _summaryRow(
            'Sudah Dibayar',
            _money(_paid),
            valueColor: AppColors.income,
          ),
          _divider(),
          _summaryRow(
            'Sisa',
            _money(_remaining),
            valueColor: AppColors.warning,
          ),
          _divider(),
          _summaryRow('Dibuat', Fmt.date(_plan.createdAt)),
          _divider(),
          _summaryRow('Jumlah Pembayaran', '${_payments.length} transaksi'),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sticky_note_2_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Catatan Cicilan',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _plan.note!,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Pembayaran',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!_isPaidOff)
          TextButton(onPressed: _openAddPayment, child: const Text('Tambah')),
      ],
    );
  }

  Widget _buildEmptyPayments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada pembayaran',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Setelah kamu mencatat pengeluaran untuk cicilan ini, histori pembayarannya akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Transaction tx) {
    return GestureDetector(
      onTap: () => _openTransaction(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payments_rounded,
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
                    tx.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Fmt.date(tx.date),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '-${_money(tx.amount, compact: true)}',
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.surfaceBorder, height: 16, thickness: 1);
}

// ─── Delete dialog ─────────────────────────────────────

enum _DeleteOption { planOnly, planAndPayments }

class _DeleteConfirmDialog extends StatefulWidget {
  final String planName;
  final int paymentCount;
  final double paidAmount;

  const _DeleteConfirmDialog({
    required this.planName,
    required this.paymentCount,
    required this.paidAmount,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  _DeleteOption _selected = _DeleteOption.planOnly;

  @override
  Widget build(BuildContext context) {
    final hasPayments = widget.paymentCount > 0;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hapus Cicilan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.planName,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (hasPayments) ...[
              const SizedBox(height: 20),
              // Info about payments
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.paymentCount} pembayaran tercatat · total ${Fmt.compact(widget.paidAmount)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih cara menghapus:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              // Option 1: plan only
              _optionTile(
                value: _DeleteOption.planOnly,
                title: 'Hapus plan saja',
                subtitle:
                    'Pembayaran tetap tercatat sebagai pengeluaran biasa. Saldo tidak berubah.',
                icon: Icons.layers_clear_rounded,
                iconColor: AppColors.warning,
              ),
              const SizedBox(height: 8),
              // Option 2: plan + payments
              _optionTile(
                value: _DeleteOption.planAndPayments,
                title: 'Hapus plan + semua pembayaran',
                subtitle:
                    'Saldo akan naik ${Fmt.compact(widget.paidAmount)} karena ${widget.paymentCount} transaksi dihapus.',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.expense,
                isWarning: true,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Belum ada pembayaran yang tercatat. Plan ini akan dihapus permanen.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(
                      hasPayments ? _selected : _DeleteOption.planOnly,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(220),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Hapus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required _DeleteOption value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool isWarning = false,
  }) {
    final selected = _selected == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? iconColor.withAlpha(15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? iconColor.withAlpha(120) : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isWarning && selected
                          ? AppColors.expense
                          : AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? iconColor : AppColors.surfaceBorder,
                  width: 2,
                ),
                color: selected ? iconColor : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
