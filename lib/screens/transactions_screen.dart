import 'package:flutter/material.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/screens/transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _state = AppState.instance;
  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;

  List<Transaction> get _filteredTransactions {
    return _state.transactions.where((tx) {
      if (_typeFilter != null && tx.type != _typeFilter) {
        return false;
      }

      final range = _dateRange;
      if (range != null) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        if (txDate.isBefore(start) || txDate.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _openDetail(Transaction tx) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceCard,
          ),
          scaffoldBackgroundColor: AppColors.background,
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = _filteredTransactions;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Semua Transaksi')),
      body: Column(
        children: [
          _buildFilters(txs.length),
          Expanded(
            child: txs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: txs.length,
                    itemBuilder: (_, index) => _buildTxCard(txs[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$resultCount transaksi ditemukan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'Semua',
                  selected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Pengeluaran',
                  selected: _typeFilter == TransactionType.expense,
                  color: AppColors.expense,
                  onTap: () =>
                      setState(() => _typeFilter = TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Pemasukan',
                  selected: _typeFilter == TransactionType.income,
                  color: AppColors.income,
                  onTap: () =>
                      setState(() => _typeFilter = TransactionType.income),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dateRange == null
                                ? 'Filter tanggal'
                                : '${Fmt.date(_dateRange!.start)} - ${Fmt.date(_dateRange!.end)}',
                            style: TextStyle(
                              color: _dateRange == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _dateRange = null),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final accent = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(22) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent.withAlpha(90) : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.textMuted,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ubah filter tanggal atau jenis transaksi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxCard(Transaction tx, int index) {
    final color = _state.categoryColor(tx);
    final icon = _state.categoryIcon(tx);
    final label = _state.categoryLabel(tx);
    final isExpense = tx.type == TransactionType.expense;

    return GestureDetector(
      onTap: () => _openDetail(tx),
      child: Container(
        margin: EdgeInsets.only(top: index == 0 ? 0 : 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withAlpha(64)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (tx.fromScan)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceCard,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (tx.installmentPlanId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Cicilan',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        Fmt.date(tx.date),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}${Fmt.compact(tx.amount)}',
                  style: TextStyle(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
}
