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
import 'package:sentra_app/screens/sentra_brain_screen.dart';
import 'package:sentra_app/screens/transaction_detail_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _activeFilter = 'Semua';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  static const _monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── SNAPSHOT ──────────────────────────────────────────────

  FinanceSnapshot _buildSnapshot() {
    return FinanceSnapshot(
      transactions: context.watch<TransactionsCubit>().state.transactions,
      customCategories:
          context.watch<CategoriesCubit>().state.customCategories,
      installmentPlans:
          context.watch<InstallmentsCubit>().state.installmentPlans,
      currency: context.watch<SettingsCubit>().state.currency,
    );
  }

  // ─── FILTERING ─────────────────────────────────────────────

  List<Transaction> _getFiltered(FinanceSnapshot snapshot) {
    var txs = List<Transaction>.from(snapshot.transactions);
    if (_activeFilter == 'Pengeluaran') {
      txs = txs.where((tx) => tx.type == TransactionType.expense).toList();
    } else if (_activeFilter == 'Pemasukan') {
      txs = txs.where((tx) => tx.type == TransactionType.income).toList();
    } else if (_activeFilter != 'Semua') {
      txs = txs
          .where((tx) => snapshot.categoryLabel(tx) == _activeFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      txs = txs
          .where(
            (tx) =>
                tx.title.toLowerCase().contains(q) ||
                snapshot.categoryLabel(tx).toLowerCase().contains(q),
          )
          .toList();
    }
    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

  Map<DateTime, List<Transaction>> _group(List<Transaction> txs) {
    final result = <DateTime, List<Transaction>>{};
    for (final tx in txs) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      result.putIfAbsent(key, () => []).add(tx);
    }
    final sorted = result.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  List<String> _categories(FinanceSnapshot snapshot) {
    final seen = <String>{};
    for (final tx in snapshot.transactions) {
      seen.add(snapshot.categoryLabel(tx));
    }
    return seen.toList()..sort();
  }

  // ─── HELPERS ───────────────────────────────────────────────

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt == today) return 'Hari ini';
    if (dt == yesterday) return 'Kemarin';
    return '${dt.day} ${_monthNames[dt.month]} ${dt.year}';
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─── APPBAR ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(List<String> categories) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Cari transaksi...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      );
    }
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Riwayat transaksi kamu ✦',
            style: TextStyle(
              color: AppColors.textSecondary.withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _isSearching = true);
          },
        ),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: AppColors.textSecondary),
          onPressed: () => _showFilterSheet(categories),
        ),
      ],
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snapshot = _buildSnapshot();
    snapshot.applyCurrency();

    final filtered = _getFiltered(snapshot);
    final grouped = _group(filtered);
    final categories = _categories(snapshot);
    final isEmpty = filtered.isEmpty;

    final totalIncome = filtered
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final totalExpense = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    // Build flat list: date header + transactions interleaved
    final listWidgets = <Widget>[];
    for (final entry in grouped.entries) {
      listWidgets.add(_buildDateHeader(entry.key, entry.value));
      for (int i = 0; i < entry.value.length; i++) {
        listWidgets.add(
          _buildRow(
            tx: entry.value[i],
            snapshot: snapshot,
            index: i,
            showDivider: i < entry.value.length - 1,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(categories),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards
          _buildSummaryCards(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            count: filtered.length,
          ),
          // Sentra Brain banner
          if (!isEmpty) _buildSentraBrainBanner(snapshot),
          // Filter chips (sticky — above ListView, not scrollable)
          _buildFilterChipsBar(categories),
          Divider(height: 1, thickness: 0.5, color: AppColors.surfaceBorder),
          // Transaction list
          Expanded(
            child: isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: listWidgets,
                  ),
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY CARDS ─────────────────────────────────────────

  Widget _buildSummaryCards({
    required double totalIncome,
    required double totalExpense,
    required int count,
  }) {
    final balance = totalIncome - totalExpense;
    final isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              label: 'Pemasukan',
              value: Fmt.compact(totalIncome),
              valueColor: AppColors.income,
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.income,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              label: 'Pengeluaran',
              value: Fmt.compact(totalExpense),
              valueColor: AppColors.expense,
              icon: Icons.arrow_upward_rounded,
              iconColor: AppColors.expense,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              label: 'Selisih',
              value: Fmt.compact(balance.abs()),
              valueColor: isPositive ? AppColors.income : AppColors.expense,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.primary,
              sub: '$count transaksi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  // ─── SENTRA BRAIN BANNER ───────────────────────────────────

  Widget _buildSentraBrainBanner(FinanceSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SentraBrainScreen(
                snapshot: snapshot,
                initialPrompt: 'Analisis aktivitas dan pola transaksi aku',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanya Sentra Brain tentang aktivitasmu',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Analisis pola, insight, dan saran hemat',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FILTER CHIPS BAR ──────────────────────────────────────

  Widget _buildFilterChipsBar(List<String> categories) {
    final chips = ['Semua', 'Pengeluaran', 'Pemasukan', ...categories];
    return Container(
      color: AppColors.background,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = chips[i];
          final selected = _activeFilter == f;
          final Color activeColor = f == 'Pengeluaran'
              ? AppColors.expense
              : f == 'Pemasukan'
              ? AppColors.income
              : AppColors.primary;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _activeFilter = f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? activeColor
                      : AppColors.primary.withAlpha(77),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f == 'Pengeluaran')
                    Text('▼ ',
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.expense,
                            fontSize: 9))
                  else if (f == 'Pemasukan')
                    Text('▲ ',
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.income,
                            fontSize: 9)),
                  Text(
                    f,
                    style: TextStyle(
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── DATE HEADER ───────────────────────────────────────────

  Widget _buildDateHeader(DateTime date, List<Transaction> txs) {
    final net = txs.fold(0.0, (s, tx) =>
        s + (tx.type == TransactionType.income ? tx.amount : -tx.amount));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Text(
            _dateLabel(date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            Fmt.compact(net.abs()),
            style: TextStyle(
              color: net >= 0 ? AppColors.income : AppColors.expense,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRANSACTION ROW ───────────────────────────────────────

  Widget _buildRow({
    required Transaction tx,
    required FinanceSnapshot snapshot,
    required int index,
    required bool showDivider,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(tx.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 150 + index * 30),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Dismissible(
            key: Key('d_${tx.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              color: AppColors.expense,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_rounded, color: Colors.white),
            ),
            confirmDismiss: (_) => showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceCard,
                title: Text('Hapus Transaksi?',
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text(
                  'Transaksi "${tx.title}" akan dihapus permanen.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Batal',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Hapus',
                        style: TextStyle(color: AppColors.expense)),
                  ),
                ],
              ),
            ),
            onDismissed: (_) {
              HapticFeedback.mediumImpact();
              context.read<TransactionsCubit>().deleteTransaction(tx.id);
            },
            child: _TxRow(
              tx: tx,
              snapshot: snapshot,
              timeLabel: _timeLabel(tx.date),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transaction: tx),
                ));
              },
            ),
          ),
          if (showDivider)
            Divider(
                height: 1,
                thickness: 0.5,
                indent: 68,
                color: AppColors.surfaceBorder),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────

  Widget _buildEmptyState() {
    final IconData icon;
    final String title;
    final String sub;
    if (_searchQuery.isNotEmpty) {
      icon = Icons.search_off_rounded;
      title = 'Tidak ada transaksi';
      sub = 'untuk "$_searchQuery"';
    } else if (_activeFilter != 'Semua') {
      icon = Icons.filter_alt_off_rounded;
      title = 'Tidak ada transaksi $_activeFilter';
      sub = 'Coba pilih filter lain';
    } else {
      icon = Icons.receipt_long_rounded;
      title = 'Belum ada transaksi';
      sub = 'Tambah transaksi pertamamu! 💸';
    }
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
              child: Icon(icon, color: AppColors.textMuted, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ─── FILTER BOTTOM SHEET ───────────────────────────────────

  void _showFilterSheet(List<String> allCategories) {
    HapticFeedback.selectionClick();
    String tempFilter = _activeFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20,
              MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Filter Transaksi',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Text('TIPE',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: ['Semua', 'Pengeluaran', 'Pemasukan'].map((f) {
                    final sel = tempFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => tempFilter = f);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (allCategories.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('KATEGORI',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allCategories.map((cat) {
                      final sel = tempFilter == cat;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => tempFilter = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => tempFilter = 'Semua');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.surfaceBorder),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          setState(() => _activeFilter = tempFilter);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Terapkan',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── TRANSACTION ROW WIDGET ───────────────────────────────────

class _TxRow extends StatelessWidget {
  final Transaction tx;
  final FinanceSnapshot snapshot;
  final String timeLabel;
  final VoidCallback onTap;

  const _TxRow({
    required this.tx,
    required this.snapshot,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final catColor = snapshot.categoryColor(tx);
    final catIcon = snapshot.categoryIcon(tx);
    final catLabel = snapshot.categoryLabel(tx);
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: catColor.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Icon(catIcon, color: catColor, size: 19),
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
                  const SizedBox(height: 2),
                  Text(
                    '$catLabel · $timeLabel',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${Fmt.full(tx.amount)}',
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
