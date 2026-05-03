import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/models/parsed_transaction.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/widgets/thousands_separator_formatter.dart';

class MultiParseResultScreen extends StatefulWidget {
  final List<ParsedTransaction> transactions;

  const MultiParseResultScreen({super.key, required this.transactions});

  @override
  State<MultiParseResultScreen> createState() => _MultiParseResultScreenState();
}

class _MultiParseResultScreenState extends State<MultiParseResultScreen> {
  static const _uuid = Uuid();
  late List<_EditableItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.transactions.map(_EditableItem.new).toList();
  }

  double get _totalIncome => _items
      .where((i) => i.tx.type == TransactionType.income)
      .fold(0, (sum, i) => sum + i.tx.amount);

  double get _totalExpense => _items
      .where((i) => i.tx.type == TransactionType.expense)
      .fold(0, (sum, i) => sum + i.tx.amount);

  Future<void> _edit(int index) async {
    HapticFeedback.selectionClick();
    final updated = await showModalBottomSheet<ParsedTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(transaction: _items[index].tx),
    );
    if (updated != null) setState(() => _items[index] = _EditableItem(updated));
  }

  void _delete(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _items.removeAt(index));
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  Future<void> _saveAll() async {
    HapticFeedback.mediumImpact();
    final transactionsCubit = context.read<TransactionsCubit>();
    for (final item in _items) {
      await transactionsCubit.addTransaction(
        Transaction(
          id: _uuid.v4(),
          title: item.tx.title,
          amount: item.tx.amount,
          type: item.tx.type,
          category: item.tx.category,
          date: item.tx.date,
          note: item.tx.note,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_items.length} transaksi disimpan'),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ─── BUILD ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                itemCount: _items.length + 1,
                itemBuilder: (_, i) {
                  if (i == _items.length) return _buildSwipeHint();
                  return _buildCard(i);
                },
              ),
            ),
            _buildSummaryAndSave(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Konfirmasi Transaksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_items.length}x',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = _items[index].tx;
    final typeColor = item.type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;
    final catColor = CategoryMeta.color(item.category);

    return Dismissible(
      key: _items[index].key,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.expense.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.expense,
        ),
      ),
      child: GestureDetector(
        onTap: () => _edit(index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type accent bar — stretches to full card height
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Category icon — vertically centered
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      CategoryMeta.icon(item.category),
                      color: catColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title + meta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _chip(CategoryMeta.label(item.category), catColor),
                            const SizedBox(width: 6),
                            _chip(Fmt.date(item.date), AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Amount + edit icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Fmt.compact(item.amount),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'edit',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_left_rounded, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(
            'Geser kiri untuk hapus • Ketuk untuk edit',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndSave() {
    final hasIncome = _totalIncome > 0;
    final hasExpense = _totalExpense > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (hasIncome) ...[
                _summaryPill(
                  icon: Icons.arrow_downward_rounded,
                  label: Fmt.compact(_totalIncome),
                  color: AppColors.income,
                ),
                const SizedBox(width: 8),
              ],
              if (hasExpense) ...[
                _summaryPill(
                  icon: Icons.arrow_upward_rounded,
                  label: Fmt.compact(_totalExpense),
                  color: AppColors.expense,
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text(
                '${_items.length} transaksi',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saveAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(90),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Simpan Semua (${_items.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wrapper ──────────────────────────────────────────────

class _EditableItem {
  final Key key;
  final ParsedTransaction tx;

  _EditableItem(this.tx) : key = UniqueKey();
  _EditableItem._(this.tx, this.key);

  _EditableItem copyWith(ParsedTransaction newTx) =>
      _EditableItem._(newTx, key);
}

// ─── Edit Bottom Sheet ────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final ParsedTransaction transaction;

  const _EditSheet({required this.transaction});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TransactionType _type;
  late TransactionCategory _category;
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _titleCtrl = TextEditingController(text: widget.transaction.title);
    _amountCtrl = TextEditingController(
      text: _formatAmount(widget.transaction.amount),
    );
    _date = widget.transaction.date;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String _formatAmount(double v) {
    if (v <= 0) return '';
    final s = v.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  double get _parsedAmount =>
      double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty && _parsedAmount > 0;

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _done() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      ParsedTransaction(
        title: _titleCtrl.text.trim(),
        amount: _parsedAmount,
        type: _type,
        category: _category,
        date: _date,
        note: widget.transaction.note,
        rawInput: widget.transaction.rawInput,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            Text(
              'Edit Transaksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildTypeToggle(),
            const SizedBox(height: 14),
            _buildAmountField(),
            const SizedBox(height: 14),
            _buildTitleField(),
            const SizedBox(height: 14),
            _fieldLabel('Kategori'),
            const SizedBox(height: 8),
            _buildCategoryGrid(),
            const SizedBox(height: 14),
            _buildDateRow(),
            const SizedBox(height: 20),
            _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _typeBtn(
            'Pengeluaran',
            Icons.arrow_upward_rounded,
            TransactionType.expense,
            AppColors.expense,
          ),
          _typeBtn(
            'Pemasukan',
            Icons.arrow_downward_rounded,
            TransactionType.income,
            AppColors.income,
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(
    String label,
    IconData icon,
    TransactionType value,
    Color color,
  ) {
    final sel = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _type = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? color.withAlpha(38) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? color : AppColors.textMuted, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: sel ? color : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Nominal'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              Text(
                'Rp',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorFormatter()],
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Keterangan'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: TextField(
            controller: _titleCtrl,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nama transaksi...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    const categories = TransactionCategory.values;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: categories.map((cat) {
        final sel = _category == cat;
        final color = CategoryMeta.color(cat);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _category = cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? color.withAlpha(38) : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? color.withAlpha(120) : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryMeta.icon(cat),
                  color: sel ? color : AppColors.textMuted,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  CategoryMeta.label(cat),
                  style: TextStyle(
                    color: sel ? color : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Fmt.date(_date),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    final active = _canSave;
    return GestureDetector(
      onTap: active ? _done : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            'Selesai',
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );
}
