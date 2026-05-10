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

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  // ── Daily state ──
  String _activeFilter = 'Semua';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // ── Tab state ──
  late TabController _tabController;

  // ── Calendar state ──
  late DateTime _calendarMonth;
  DateTime? _selectedDay;

  static const _monthNames = [
    '',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const _shortMonthNames = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        setState(() {
          if (_tabController.index == 1) {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          }
        });
      });
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  // ─── DAILY HELPERS ─────────────────────────────────────────

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
          .where((tx) =>
              tx.title.toLowerCase().contains(q) ||
              snapshot.categoryLabel(tx).toLowerCase().contains(q))
          .toList();
    }
    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

  Map<DateTime, List<Transaction>> _groupByDay(List<Transaction> txs) {
    final result = <DateTime, List<Transaction>>{};
    for (final tx in txs) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      result.putIfAbsent(key, () => []).add(tx);
    }
    return result;
  }

  Map<DateTime, List<Transaction>> _groupSorted(List<Transaction> txs) {
    final grouped = _groupByDay(txs);
    final sorted = grouped.entries.toList()
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

  // ─── CALENDAR HELPERS ──────────────────────────────────────

  List<Transaction> _txsForMonth(FinanceSnapshot snapshot) {
    return snapshot.transactions
        .where((tx) =>
            tx.date.year == _calendarMonth.year &&
            tx.date.month == _calendarMonth.month)
        .toList();
  }

  String _shortAmount(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return m % 1 == 0 ? '${m.toInt()}jt' : '${m.toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toInt()}rb';
    }
    return amount.toInt().toString();
  }

  // ─── SHARED HELPERS ────────────────────────────────────────

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt == today) return 'Hari ini';
    if (dt == yesterday) return 'Kemarin';
    return '${dt.day} ${_shortMonthNames[dt.month]} ${dt.year}';
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─── APPBAR ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(List<String> categories) {
    final isDaily = _tabController.index == 0;
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
        if (isDaily) ...[
          IconButton(
            icon:
                Icon(Icons.search_rounded, color: AppColors.textSecondary),
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
      ],
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snapshot = _buildSnapshot();
    snapshot.applyCurrency();

    final categories = _categories(snapshot);
    final isDaily = _tabController.index == 0;

    double totalIncome, totalExpense;
    int count;
    if (isDaily) {
      final filtered = _getFiltered(snapshot);
      totalIncome = filtered
          .where((tx) => tx.type == TransactionType.income)
          .fold(0.0, (s, tx) => s + tx.amount);
      totalExpense = filtered
          .where((tx) => tx.type == TransactionType.expense)
          .fold(0.0, (s, tx) => s + tx.amount);
      count = filtered.length;
    } else {
      final monthTxs = _txsForMonth(snapshot);
      totalIncome = monthTxs
          .where((tx) => tx.type == TransactionType.income)
          .fold(0.0, (s, tx) => s + tx.amount);
      totalExpense = monthTxs
          .where((tx) => tx.type == TransactionType.expense)
          .fold(0.0, (s, tx) => s + tx.amount);
      count = monthTxs.length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(categories),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCards(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            count: count,
          ),
          _buildTabSwitcher(),
          Divider(height: 1, thickness: 0.5, color: AppColors.surfaceBorder),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDailyTab(snapshot, categories),
                _buildCalendarTab(snapshot),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB SWITCHER ──────────────────────────────────────────

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            _tabBtn(0, 'Harian', Icons.list_rounded),
            _tabBtn(1, 'Kalender', Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int index, String label, IconData icon) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
            Text(sub,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DAILY TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildDailyTab(
      FinanceSnapshot snapshot, List<String> categories) {
    final filtered = _getFiltered(snapshot);
    final grouped = _groupSorted(filtered);
    final isEmpty = filtered.isEmpty;

    final listWidgets = <Widget>[];
    for (final entry in grouped.entries) {
      listWidgets.add(_buildDateHeader(entry.key, entry.value));
      for (int i = 0; i < entry.value.length; i++) {
        listWidgets.add(_buildRow(
          tx: entry.value[i],
          snapshot: snapshot,
          index: i,
          showDivider: i < entry.value.length - 1,
        ));
      }
    }

    return Column(
      children: [
        if (!isEmpty) _buildSentraBrainBanner(snapshot),
        _buildFilterChipsBar(categories),
        Divider(height: 1, thickness: 0.5, color: AppColors.surfaceBorder),
        Expanded(
          child: isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: listWidgets,
                ),
        ),
      ],
    );
  }

  // ─── Sentra Brain Banner ────────────────────────────────────

  Widget _buildSentraBrainBanner(FinanceSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          final now = DateTime.now();
          final monthTxs = snapshot.transactions
              .where((tx) =>
                  tx.date.year == now.year && tx.date.month == now.month)
              .toList();
          final income = monthTxs
              .where((tx) => tx.type == TransactionType.income)
              .fold(0.0, (s, tx) => s + tx.amount);
          final expense = monthTxs
              .where((tx) => tx.type == TransactionType.expense)
              .fold(0.0, (s, tx) => s + tx.amount);

          final Map<String, double> catTotals = {};
          for (final tx in monthTxs
              .where((t) => t.type == TransactionType.expense)) {
            final label = snapshot.categoryLabel(tx);
            catTotals[label] = (catTotals[label] ?? 0) + tx.amount;
          }
          final sorted = catTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final Map<String, dynamic> initialParsed;
          if (sorted.isEmpty) {
            initialParsed = {
              'type': 'text',
              'text':
                  'Belum ada pengeluaran bulan ini. Coba tanya aku apa saja tentang keuanganmu! 💬',
            };
          } else {
            final items = sorted.take(6).map((e) => {
                  'label': e.key,
                  'value': e.value,
                  'percentage': expense > 0
                      ? ((e.value / expense) * 100).round()
                      : 0,
                }).toList();
            initialParsed = {
              'type': 'chart',
              'text':
                  'Ringkasan aktivitasmu bulan ini 📊\n\nPemasukan  ${Fmt.compact(income)}  •  Pengeluaran  ${Fmt.compact(expense)}',
              'chart': {'total': expense, 'items': items},
              'actions': ['Tips hemat untukku', 'Prediksi saldo akhir bulan'],
            };
          }

          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SentraBrainScreen(
              snapshot: snapshot,
              initialParsed: initialParsed,
            ),
          ));
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

  // ─── Filter Chips Bar ───────────────────────────────────────

  Widget _buildFilterChipsBar(List<String> categories) {
    final chips = ['Semua', 'Pengeluaran', 'Pemasukan', ...categories];
    return Container(
      color: AppColors.background,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
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

  // ─── Date Header ────────────────────────────────────────────

  Widget _buildDateHeader(DateTime date, List<Transaction> txs) {
    final net = txs.fold(
        0.0,
        (s, tx) =>
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

  // ─── Transaction Row ────────────────────────────────────────

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
          _SwipeDeleteRow(
            onConfirm: () => showDialog<bool>(
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
            onDelete: () {
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

  // ─── Empty State ────────────────────────────────────────────

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

  // ─── Filter Bottom Sheet ────────────────────────────────────

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
                  MediaQuery.of(ctx).padding.bottom +
                  16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
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
                  children:
                      ['Semua', 'Pengeluaran', 'Pemasukan'].map((f) {
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
                          side:
                              BorderSide(color: AppColors.surfaceBorder),
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

  // ═══════════════════════════════════════════════════════════
  // CALENDAR TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildCalendarTab(FinanceSnapshot snapshot) {
    final monthTxs = _txsForMonth(snapshot);
    final grouped = _groupByDay(monthTxs);

    final selectedTxs = _selectedDay != null
        ? (grouped[_selectedDay] ?? <Transaction>[])
        : <Transaction>[];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -300) {
          HapticFeedback.selectionClick();
          setState(() {
            _calendarMonth =
                DateTime(_calendarMonth.year, _calendarMonth.month + 1);
            _selectedDay = null;
          });
        } else if (v > 300) {
          HapticFeedback.selectionClick();
          setState(() {
            _calendarMonth =
                DateTime(_calendarMonth.year, _calendarMonth.month - 1);
            _selectedDay = null;
          });
        }
      },
      child: ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildMonthNav(),
        _buildDayOfWeekLabels(),
        _buildCalendarGrid(grouped),
        const SizedBox(height: 8),
        Divider(thickness: 0.5, color: AppColors.surfaceBorder, height: 1),
        if (_selectedDay != null) ...[
          _buildSelectedDayHeader(selectedTxs, snapshot),
          if (selectedTxs.isEmpty)
            _buildNoTxForDay()
          else
            ...selectedTxs.asMap().entries.map((e) => _buildRow(
                  tx: e.value,
                  snapshot: snapshot,
                  index: e.key,
                  showDivider: e.key < selectedTxs.length - 1,
                )),
        ] else
          _buildCalendarHint(),
      ],
    ),
    );
  }

  // ─── Month Navigation ───────────────────────────────────────

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded,
                color: AppColors.textSecondary, size: 28),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month - 1);
                _selectedDay = null;
              });
            },
          ),
          Expanded(
            child: Text(
              '${_monthNames[_calendarMonth.month]} ${_calendarMonth.year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 28),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month + 1);
                _selectedDay = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── Day-of-Week Labels ─────────────────────────────────────

  Widget _buildDayOfWeekLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: _dayLabels
            .map((d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Calendar Grid ──────────────────────────────────────────

  Widget _buildCalendarGrid(Map<DateTime, List<Transaction>> grouped) {
    final firstDay =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    // weekday: 1=Mon … 7=Sun → offset = weekday - 1 (0=Mon … 6=Sun)
    final offset = firstDay.weekday - 1;
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - offset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 64));
              }
              final date = DateTime(
                  _calendarMonth.year, _calendarMonth.month, dayNum);
              final txs = grouped[date] ?? [];
              return Expanded(
                child: _buildDayCell(date, txs, today),
              );
            }),
          );
        }),
      ),
    );
  }

  // ─── Day Cell ───────────────────────────────────────────────

  Widget _buildDayCell(
    DateTime date,
    List<Transaction> txs,
    DateTime today,
  ) {
    final isToday = date == today;
    final isSelected = date == _selectedDay;

    final income = txs
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final expense = txs
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);
    final hasIncome = income > 0;
    final hasExpense = expense > 0;

    final Color numColor = isSelected
        ? Colors.white
        : isToday
            ? AppColors.primary
            : AppColors.textPrimary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDay = isSelected ? null : date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(2),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withAlpha(25)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary.withAlpha(100))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: numColor,
                fontSize: 14,
                fontWeight: (isToday || isSelected)
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            if (hasIncome || hasExpense) ...[
              const SizedBox(height: 4),
              if (hasIncome)
                Text(
                  '+${_shortAmount(income)}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withAlpha(210)
                        : AppColors.income,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              if (hasExpense)
                Text(
                  '-${_shortAmount(expense)}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withAlpha(210)
                        : AppColors.expense,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Selected Day Header ────────────────────────────────────

  Widget _buildSelectedDayHeader(
      List<Transaction> txs, FinanceSnapshot snapshot) {
    final income = txs
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (s, tx) => s + tx.amount);
    final expense = txs
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = _selectedDay!;
    final label = d == today
        ? 'Hari ini, ${d.day} ${_monthNames[d.month]}'
        : '${d.day} ${_monthNames[d.month]} ${d.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _daySummaryCard(
                  label: 'Pemasukan',
                  value: income,
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _daySummaryCard(
                  label: 'Pengeluaran',
                  value: expense,
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          if (txs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${txs.length} transaksi',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _daySummaryCard({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                Text(
                  Fmt.compact(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTxForDay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Tidak ada transaksi di hari ini',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildCalendarHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Pilih tanggal untuk melihat transaksi',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

// ─── SWIPE DELETE ROW ─────────────────────────────────────────

class _SwipeDeleteRow extends StatefulWidget {
  final Widget child;
  final Future<bool?> Function() onConfirm;
  final VoidCallback onDelete;

  const _SwipeDeleteRow({
    required this.child,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  State<_SwipeDeleteRow> createState() => _SwipeDeleteRowState();
}

class _SwipeDeleteRowState extends State<_SwipeDeleteRow>
    with SingleTickerProviderStateMixin {
  static const double _maxReveal = 80.0;
  static const double _triggerAt = 52.0;

  late final AnimationController _anim;
  double _offset = 0;
  double _snapFrom = 0;
  double _snapTo = 0;
  bool _thresholdReached = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onTick);
  }

  void _onTick() {
    if (!mounted) return;
    final t = CurvedAnimation(parent: _anim, curve: Curves.easeOut).value;
    setState(() => _offset = _snapFrom + (_snapTo - _snapFrom) * t);
  }

  @override
  void dispose() {
    _anim
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _anim.stop();
    _snapFrom = _offset;
    _snapTo = target;
    _anim.forward(from: 0);
  }

  void _onDragStart(DragStartDetails _) {
    if (!_locked) _anim.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_locked) return;
    final next = _offset - d.delta.dx;
    double clamped;
    if (next <= _maxReveal) {
      clamped = next.clamp(0.0, _maxReveal);
    } else {
      // rubber-band resistance beyond max
      clamped = _maxReveal + (next - _maxReveal) * 0.12;
    }
    final reached = clamped >= _triggerAt;
    if (reached && !_thresholdReached) {
      _thresholdReached = true;
      HapticFeedback.mediumImpact();
    } else if (!reached) {
      _thresholdReached = false;
    }
    setState(() => _offset = clamped);
  }

  void _onDragEnd(DragEndDetails _) async {
    if (_locked) return;
    if (!_thresholdReached) {
      _thresholdReached = false;
      _animateTo(0);
      return;
    }
    _locked = true;
    _animateTo(_maxReveal);
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final confirmed = await widget.onConfirm();

    if (!mounted) return;
    _locked = false;
    _thresholdReached = false;
    _animateTo(0);
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              color: AppColors.expense,
              padding: const EdgeInsets.only(right: 26),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                  SizedBox(height: 3),
                  Text(
                    'Hapus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-_offset, 0),
            child: ColoredBox(
              color: AppColors.background,
              child: widget.child,
            ),
          ),
        ],
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
