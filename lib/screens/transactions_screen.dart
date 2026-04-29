import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/transaction_detail_screen.dart';
import 'package:sentra_app/widgets/transaction_list_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;

  List<Transaction> get _filteredTransactions {
    final transactions = context.watch<TransactionsCubit>().state.transactions;
    return transactions.where((tx) {
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
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.surfaceCard,
          ),
          scaffoldBackgroundColor: AppColors.background,
          dialogTheme: DialogThemeData(backgroundColor: AppColors.surfaceCard),
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
    return TransactionListItem(
      transaction: tx,
      dateLabel: Fmt.date(tx.date),
      onTap: () => _openDetail(tx),
      margin: EdgeInsets.only(top: index == 0 ? 0 : 10),
    );
  }
}
