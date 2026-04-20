import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  final Transaction? editTransaction; // if set → edit mode

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _state = AppState.instance;
  static const _uuid = Uuid();

  late TransactionType _type;
  TransactionCategory _category = TransactionCategory.food;
  String? _customCategoryId;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    if (edit != null) {
      _type = edit.type;
      _category = edit.category;
      _customCategoryId = edit.customCategoryId;
      _date = edit.date;
      _titleCtrl.text = edit.title;
      _amountCtrl.text = _fmtEditAmount(edit.amount);
      _noteCtrl.text = edit.note ?? '';
    } else {
      _type = widget.initialType;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // pre-fill helper for edit mode
  String _fmtEditAmount(double amount) {
    final str = amount.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(str[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.expense : AppColors.income;

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (_titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Isi nama dan jumlah transaksi'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final edit = widget.editTransaction;
    final tx = Transaction(
      id: edit?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
      customCategoryId: _customCategoryId,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      fromScan: edit?.fromScan ?? false,
    );

    if (edit != null) {
      await _state.updateTransaction(tx);
    } else {
      await _state.addTransaction(tx);
    }

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
        title: Text(
          widget.editTransaction != null
              ? 'Edit Transaksi'
              : 'Tambah Transaksi',
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Simpan',
              style: TextStyle(
                color: _typeColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildDetailsCard(),
            const SizedBox(height: 20),
            _buildCategoryPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _typeTab(
            TransactionType.expense,
            'Pengeluaran',
            Icons.arrow_upward_rounded,
          ),
          _typeTab(
            TransactionType.income,
            'Pemasukan',
            Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _typeTab(TransactionType t, String label, IconData icon) {
    final sel = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _type = t);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel
                ? (t == TransactionType.expense
                      ? AppColors.expenseGradient
                      : AppColors.incomeGradient)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: sel ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _typeColor.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _type == TransactionType.expense
                ? 'Jumlah Pengeluaran'
                : 'Jumlah Pemasukan',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _state.currency.symbol,
                style: TextStyle(
                  color: _typeColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [ThousandsSeparatorFormatter()],
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 36,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Column(
      children: [
        _buildStyledField(
          controller: _titleCtrl,
          label: 'Nama Transaksi',
          hint: 'Contoh: Makan siang, Gaji...',
          icon: Icons.receipt_long_rounded,
          focusColor: _typeColor,
        ),
        const SizedBox(height: 12),
        _buildDateRow(),
        const SizedBox(height: 12),
        _buildStyledField(
          controller: _noteCtrl,
          label: 'Catatan',
          hint: 'Tambahkan catatan (opsional)',
          icon: Icons.sticky_note_2_rounded,
          focusColor: AppColors.info,
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color focusColor,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return _FocusFieldWrapper(
      focusColor: focusColor,
      child: (hasFocus) => TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          labelStyle: TextStyle(
            color: hasFocus ? focusColor : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: hasFocus ? FontWeight.w600 : FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              icon,
              size: 20,
              color: hasFocus ? focusColor : AppColors.textMuted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: hasFocus
              ? focusColor.withAlpha(15)
              : AppColors.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.surfaceBorder,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: focusColor, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Transaksi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Fmt.date(_date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category picker (built-in + custom) ─────────────────

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Built-in categories
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...TransactionCategory.values.map((c) {
              final sel = _customCategoryId == null && c == _category;
              final color = CategoryMeta.color(c);
              return _catChip(
                label: CategoryMeta.label(c),
                icon: CategoryMeta.icon(c),
                color: color,
                selected: sel,
                onTap: () => setState(() {
                  _category = c;
                  _customCategoryId = null;
                }),
              );
            }),

            // Custom categories
            ..._state.customCategories.map((cc) {
              final sel = _customCategoryId == cc.id;
              return _catChip(
                label: cc.name,
                icon: cc.icon,
                color: cc.color,
                selected: sel,
                onTap: () => setState(() {
                  _customCategoryId = cc.id;
                  _category = TransactionCategory.other;
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _catChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(38) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withAlpha(102) : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Focus-aware wrapper for animated input fields ─────────────────────────
class _FocusFieldWrapper extends StatefulWidget {
  final Widget Function(bool hasFocus) child;
  final Color focusColor;

  const _FocusFieldWrapper({required this.child, required this.focusColor});

  @override
  State<_FocusFieldWrapper> createState() => _FocusFieldWrapperState();
}

class _FocusFieldWrapperState extends State<_FocusFieldWrapper> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: widget.child(_hasFocus),
      ),
    );
  }
}

// ─── Thousand Separator Formatter ────────────────────────────────────────────
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove leading zeros
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.isEmpty) return newValue.copyWith(text: '0');

    // Insert dots every 3 digits from the right
    final buf = StringBuffer();
    int count = 0;
    for (int i = trimmed.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(trimmed[i]);
      count++;
    }
    final formatted = buf.toString().split('').reversed.join();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
