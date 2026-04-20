import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  const AddTransactionScreen({super.key, this.initialType = TransactionType.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  TransactionCategory _category = TransactionCategory.food;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.expense : AppColors.income;

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (_titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Isi nama dan jumlah transaksi'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    AppData.addTransaction(Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
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
        title: const Text('Tambah Transaksi'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Simpan',
              style: TextStyle(
                  color: _typeColor, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type selector ──
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // ── Amount ──
            _buildAmountInput(),
            const SizedBox(height: 20),

            // ── Details card ──
            _buildDetailsCard(),
            const SizedBox(height: 20),

            // ── Category ──
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
          _typeTab(TransactionType.expense, 'Pengeluaran',
              Icons.arrow_upward_rounded),
          _typeTab(TransactionType.income, 'Pemasukan',
              Icons.arrow_downward_rounded),
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
              Icon(icon,
                  size: 16,
                  color: sel ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  )),
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
            _type == TransactionType.expense ? 'Jumlah Pengeluaran' : 'Jumlah Pemasukan',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: TextStyle(
                    color: _typeColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 36),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Nama Transaksi',
                prefixIcon: Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1, indent: 16),
          // Date
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.textMuted),
            title: const Text('Tanggal',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: Text(
              Fmt.date(_date),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            onTap: _pickDate,
            dense: true,
          ),
          Divider(color: AppColors.surfaceBorder, height: 1, indent: 16),
          // Note
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_rounded, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: TransactionCategory.values.length,
          itemBuilder: (_, i) {
            final c = TransactionCategory.values[i];
            final sel = c == _category;
            final color = CategoryMeta.color(c);
            return GestureDetector(
              onTap: () {
                setState(() => _category = c);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel ? color.withAlpha(38) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? color.withAlpha(102) : AppColors.surfaceBorder,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CategoryMeta.icon(c),
                        size: 22,
                        color: sel ? color : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(CategoryMeta.label(c),
                        style: TextStyle(
                          color: sel ? color : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
