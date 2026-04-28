import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;
  final Transaction? editTransaction;
  final ScanPrefill? scanData;
  final String? initialInstallmentPlanId;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.editTransaction,
    this.scanData,
    this.initialInstallmentPlanId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _uuid = Uuid();

  late TransactionType _type;
  TransactionCategory _category = TransactionCategory.food;
  String? _customCategoryId;
  String? _installmentPlanId;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  late FinanceSnapshot _snapshot;

  FinanceSnapshot _readSnapshot() {
    return FinanceSnapshot(
      transactions: context.read<TransactionsCubit>().state.transactions,
      customCategories: context.read<CategoriesCubit>().state.customCategories,
      installmentPlans: context
          .read<InstallmentsCubit>()
          .state
          .installmentPlans,
      currency: context.read<SettingsCubit>().state.currency,
    );
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

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    final scan = widget.scanData;
    if (edit != null) {
      _type = edit.type;
      _category = edit.category;
      _customCategoryId = edit.customCategoryId;
      _installmentPlanId = edit.installmentPlanId;
      _date = edit.date;
      _titleCtrl.text = edit.title;
      _amountCtrl.text = _fmtEditAmount(edit.amount);
      _noteCtrl.text = edit.note ?? '';
    } else if (scan != null) {
      _type = scan.type;
      _category = scan.category;
      _titleCtrl.text = scan.merchant;
      if (scan.total > 0) _amountCtrl.text = _fmtEditAmount(scan.total);
    } else {
      _type = widget.initialType;
      _installmentPlanId = widget.initialInstallmentPlanId;
      if (_installmentPlanId != null) {
        _category = TransactionCategory.bills;
      }
    }
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final q = _titleCtrl.text;
    final results = _readSnapshot().suggestTitles(q);
    final exact = results.length == 1 && results.first == q;
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty && !exact;
    });
  }

  void _applySuggestion(String title) {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.text = title;
    _titleCtrl.selection = TextSelection.collapsed(offset: title.length);
    setState(() => _showSuggestions = false);
    _titleCtrl.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

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

  List<InstallmentPlan> get _availableInstallments {
    final plans = _snapshot.activeInstallmentPlans.toList();
    final current = _snapshot.installmentById(_installmentPlanId);
    if (current != null && !plans.any((plan) => plan.id == current.id)) {
      plans.insert(0, current);
    }
    return plans;
  }

  double _selectedInstallmentRemaining({String? excludingTransactionId}) {
    final planId = _installmentPlanId;
    if (planId == null) return 0;
    final plan = _snapshot.installmentById(planId);
    if (plan == null) return 0;
    final paid = _snapshot.transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.installmentPlanId == planId &&
              tx.id != excludingTransactionId,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final remaining = plan.totalAmount - paid;
    return remaining < 0 ? 0 : remaining;
  }

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
    if (_type == TransactionType.expense && _installmentPlanId != null) {
      final remaining = _selectedInstallmentRemaining(
        excludingTransactionId: edit?.id,
      );
      if (amount > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran melebihi sisa cicilan (${Fmt.full(remaining)})',
            ),
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
    }

    final tx = Transaction(
      id: edit?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
      customCategoryId: _customCategoryId,
      installmentPlanId: _type == TransactionType.expense
          ? _installmentPlanId
          : null,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      fromScan: edit?.fromScan ?? (widget.scanData != null),
    );

    if (edit != null) {
      await context.read<TransactionsCubit>().updateTransaction(tx);
    } else {
      await context.read<TransactionsCubit>().addTransaction(tx);
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
          colorScheme: ColorScheme.dark(
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
    _snapshot = _watchSnapshot();
    _snapshot.applyCurrency();
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
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          widget.editTransaction != null
              ? 'Edit Transaksi'
              : widget.scanData != null
              ? 'Konfirmasi Scan'
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
            if (widget.scanData != null) ...[
              _buildScanBanner(),
              const SizedBox(height: 16),
            ],
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildAmountInput(),
            if ((widget.scanData?.candidateAmounts ?? []).isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAmountChips(),
            ],
            const SizedBox(height: 20),
            _buildDetailsCard(),
            if (_type == TransactionType.expense) ...[
              const SizedBox(height: 20),
              _buildInstallmentPicker(),
            ],
            const SizedBox(height: 20),
            _buildCategoryPicker(),
            if (widget.scanData?.rawText != null &&
                widget.scanData!.rawText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRawOcrSection(),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Scan banner ─────────────────────────────────────────

  Widget _buildScanBanner() {
    final scan = widget.scanData!;
    final hasTotal = scan.total > 0;
    final isGemini = scan.source == 'gemini';
    final bannerColor = hasTotal ? AppColors.income : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasTotal
                  ? Icons.document_scanner_rounded
                  : Icons.warning_amber_rounded,
              color: bannerColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasTotal
                          ? 'Hasil scan ditemukan'
                          : 'Total tidak terdeteksi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isGemini ? AppColors.primary : AppColors.textMuted)
                                .withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (isGemini
                                      ? AppColors.primary
                                      : AppColors.textMuted)
                                  .withAlpha(80),
                        ),
                      ),
                      child: Text(
                        isGemini ? 'Gemini AI' : 'ML Kit',
                        style: TextStyle(
                          color: isGemini
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  hasTotal
                      ? 'Periksa & edit jika ada yang salah'
                      : 'Isi jumlah secara manual',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (scan.imagePath != null)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(scan.imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountChips() {
    final candidates = widget.scanData!.candidateAmounts;
    final currentText = _amountCtrl.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nominal terdeteksi di struk — tap untuk pilih:',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: candidates.take(8).map((amount) {
            final formatted = _fmtEditAmount(amount);
            final isSelected = currentText == formatted;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _amountCtrl.text = formatted);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(40)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  'Rp $formatted',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRawOcrSection() {
    final isGemini = widget.scanData!.source == 'gemini';
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Icon(
            Icons.text_snippet_outlined,
            color: AppColors.textMuted,
            size: 18,
          ),
          title: Text(
            isGemini ? 'Respons Gemini (debug)' : 'Teks OCR Mentah (debug)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                widget.scanData!.rawText!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Suggestion dropdown ──────────────────────────────────

  Widget _buildSuggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions.asMap().entries.map((e) {
          final i = e.key;
          final title = e.value;
          final isLast = i == _suggestions.length - 1;
          return InkWell(
            onTap: () => _applySuggestion(title),
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            splashColor: _typeColor.withAlpha(26),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: _typeColor.withAlpha(153),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    color: AppColors.surfaceBorder,
                    height: 1,
                    indent: 40,
                  ),
              ],
            ),
          );
        }).toList(),
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
          setState(() {
            _type = t;
            if (_type == TransactionType.income) {
              _installmentPlanId = null;
            }
          });
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _snapshot.currency.symbol,
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
                  decoration: InputDecoration(
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStyledField(
          controller: _titleCtrl,
          label: 'Nama Transaksi',
          hint: 'Contoh: Makan siang, Gaji...',
          icon: Icons.receipt_long_rounded,
          focusColor: _typeColor,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _showSuggestions
              ? _buildSuggestionList()
              : const SizedBox.shrink(),
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

  Widget _buildInstallmentPicker() {
    final plans = _availableInstallments;
    final selectedPlan = _snapshot.installmentById(_installmentPlanId);
    final remaining = selectedPlan == null
        ? 0.0
        : _selectedInstallmentRemaining(
            excludingTransactionId: widget.editTransaction?.id,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran Cicilan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _installmentPlanId = null);
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _installmentPlanId == null
                        ? AppColors.primary.withAlpha(18)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _installmentPlanId == null
                          ? AppColors.primary.withAlpha(90)
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.do_not_disturb_on_outlined,
                        color: _installmentPlanId == null
                            ? AppColors.primaryLight
                            : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bukan pembayaran cicilan',
                          style: TextStyle(
                            color: _installmentPlanId == null
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (plans.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Belum ada cicilan aktif. Tambahkan cicilan dari beranda terlebih dulu.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plans.map((plan) {
                    final selected = _installmentPlanId == plan.id;
                    final planRemaining = selected
                        ? remaining
                        : _snapshot.installmentRemaining(plan.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _installmentPlanId = plan.id;
                          _category = TransactionCategory.bills;
                          _customCategoryId = null;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.warning.withAlpha(20)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.warning
                                : AppColors.surfaceBorder,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.warning
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sisa ${Fmt.full(planRemaining)}',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (selectedPlan != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Pembayaran ini akan mengurangi sisa cicilan ${selectedPlan.name} menjadi ${Fmt.full((remaining - (double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0)).clamp(0, remaining).toDouble())}.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
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
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
            borderSide: BorderSide(color: AppColors.surfaceBorder, width: 1),
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
              child: Icon(
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
                  Text(
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
                    style: TextStyle(
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
              child: Text(
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
        Text(
          'Kategori',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
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
            ..._snapshot.customCategories.map((cc) {
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

// ─── Focus-aware wrapper ──────────────────────────────────────
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

// ─── Thousand Separator Formatter ─────────────────────────────
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.isEmpty) return newValue.copyWith(text: '0');
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
