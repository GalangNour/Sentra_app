import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/models/parsed_transaction.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/widgets/thousands_separator_formatter.dart';

class QuickParseResultScreen extends StatefulWidget {
  final ParsedTransaction parsed;

  const QuickParseResultScreen({super.key, required this.parsed});

  @override
  State<QuickParseResultScreen> createState() => _QuickParseResultScreenState();
}

class _QuickParseResultScreenState extends State<QuickParseResultScreen> {
  static const _uuid = Uuid();

  late TransactionType _type;
  late TransactionCategory _category;
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _type = widget.parsed.type;
    _category = widget.parsed.category;
    _titleCtrl = TextEditingController(text: widget.parsed.title);
    _amountCtrl = TextEditingController(
      text: _formatAmount(widget.parsed.amount),
    );
    _noteCtrl = TextEditingController(text: widget.parsed.note ?? '');
    _date = widget.parsed.date;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
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

  Future<void> _save() async {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();

    final tx = Transaction(
      id: _uuid.v4(),
      title: _titleCtrl.text.trim(),
      amount: _parsedAmount,
      type: _type,
      category: _category,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    await context.read<TransactionsCubit>().addTransaction(tx);
    if (!mounted) return;

    // Show brief success snackbar before popping
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi disimpan'),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Pop back to home
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputBubble(),
                    if (widget.parsed.warning != null) ...[
                      const SizedBox(height: 10),
                      _buildWarning(widget.parsed.warning!),
                    ],
                    const SizedBox(height: 20),
                    _buildTypeToggle(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildCategoryLabel(),
                    const SizedBox(height: 10),
                    _buildCategoryGrid(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    const SizedBox(height: 16),
                    _buildDateRow(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
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
          Text(
            'Konfirmasi Transaksi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBubble() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.parsed.rawInput,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _typeBtn(
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            value: TransactionType.expense,
            color: AppColors.expense,
          ),
          _typeBtn(
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            value: TransactionType.income,
            color: AppColors.income,
          ),
        ],
      ),
    );
  }

  Widget _typeBtn({
    required String label,
    required IconData icon,
    required TransactionType value,
    required Color color,
  }) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _type = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(38) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorFormatter()],
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _titleCtrl,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nama transaksi...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLabel() {
    return _fieldLabel('Kategori');
  }

  Widget _buildCategoryGrid() {
    final categories = [
      TransactionCategory.food,
      TransactionCategory.transport,
      TransactionCategory.shopping,
      TransactionCategory.entertainment,
      TransactionCategory.health,
      TransactionCategory.bills,
      TransactionCategory.salary,
      TransactionCategory.investment,
      TransactionCategory.other,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final selected = _category == cat;
        final color = CategoryMeta.color(cat);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _category = cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(38) : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color.withAlpha(120)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryMeta.icon(cat),
                  color: selected ? color : AppColors.textMuted,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  CategoryMeta.label(cat),
                  style: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Catatan (opsional)'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Fmt.date(_date),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final active = _canSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: active ? _save : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(90),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_rounded,
                color: active ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Simpan Transaksi',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
