import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/screens/add_transaction_screen.dart';
import 'package:sentra_app/screens/transaction_detail_screen.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final InstallmentPlan plan;

  const InstallmentDetailScreen({super.key, required this.plan});

  @override
  State<InstallmentDetailScreen> createState() =>
      _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  final _state = AppState.instance;

  InstallmentPlan get _plan =>
      _state.installmentById(widget.plan.id) ?? widget.plan;

  List<Transaction> get _payments => _state.installmentPayments(_plan.id);
  double get _paid => _state.installmentPaidAmount(_plan.id);
  double get _remaining => _state.installmentRemaining(_plan.id);
  double get _progress => _state.installmentProgress(_plan.id);
  bool get _isPaidOff => _state.installmentIsPaidOff(_plan.id);

  Future<void> _openAddPayment() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: TransactionType.expense,
          initialInstallmentPlanId: _plan.id,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openTransaction(Transaction tx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
            Fmt.full(_remaining),
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
          _summaryRow('Total Cicilan', Fmt.full(_plan.totalAmount)),
          _divider(),
          _summaryRow(
            'Sudah Dibayar',
            Fmt.full(_paid),
            valueColor: AppColors.income,
          ),
          _divider(),
          _summaryRow(
            'Sisa',
            Fmt.full(_remaining),
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
            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textMuted,
            ),
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
                  '-${Fmt.compact(tx.amount)}',
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
