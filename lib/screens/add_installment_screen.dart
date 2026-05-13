import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/installment_plan.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/widgets/focus_field_wrapper.dart';
import 'package:sentra_app/widgets/thousands_separator_formatter.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';

class AddInstallmentScreen extends StatefulWidget {
  final InstallmentPlan? editPlan;

  const AddInstallmentScreen({super.key, this.editPlan});

  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late FinanceSnapshot _snapshot;

  bool _useMonthlyAmount = false;
  int? _computedDuration;

  bool get _isEdit => widget.editPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.editPlan;
    if (plan != null) {
      _nameCtrl.text = plan.name;
      _noteCtrl.text = plan.note ?? '';
      _amountCtrl.text = _formatAmount(plan.totalAmount);
      if (plan.monthlyAmount != null) {
        _useMonthlyAmount = true;
        _monthlyCtrl.text = _formatAmount(plan.monthlyAmount!);
      }
    }
    _amountCtrl.addListener(_updateDuration);
    _monthlyCtrl.addListener(_updateDuration);
    _updateDuration();
  }

  String _formatAmount(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  void _updateDuration() {
    final total = double.tryParse(
        _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    final monthly = double.tryParse(
        _monthlyCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (total != null && monthly != null && total > 0 && monthly > 0) {
      setState(() => _computedDuration = (total / monthly).ceil());
    } else {
      setState(() => _computedDuration = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _monthlyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  FinanceSnapshot _readSnapshot() {
    return FinanceSnapshot(
      transactions: context.read<TransactionsCubit>().state.transactions,
      customCategories: context.read<CategoriesCubit>().state.customCategories,
      installmentPlans: context.read<InstallmentsCubit>().state.installmentPlans,
      currency: context.read<SettingsCubit>().state.currency,
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (_nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Isi nama cicilan dan total nominal'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    double? monthlyAmount;
    if (_useMonthlyAmount) {
      monthlyAmount = double.tryParse(
        _monthlyCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      );
      if (monthlyAmount == null || monthlyAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Isi nominal cicilan per bulan'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    final cubit = context.read<InstallmentsCubit>();
    final noteTrimmed =
        _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    if (_isEdit) {
      await cubit.editInstallmentPlan(
        id: widget.editPlan!.id,
        name: _nameCtrl.text.trim(),
        totalAmount: amount,
        monthlyAmount: monthlyAmount,
        note: noteTrimmed,
      );
    } else {
      await cubit.addInstallmentPlan(
        name: _nameCtrl.text.trim(),
        totalAmount: amount,
        monthlyAmount: monthlyAmount,
        note: noteTrimmed,
      );
    }

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    _snapshot = _readSnapshot();
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
        title: Text(_isEdit ? 'Edit Cicilan' : 'Tambah Cicilan'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Simpan',
              style: TextStyle(
                color: AppColors.primaryLight,
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
            // Total amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.balanceGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(76)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Cicilan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _snapshot.currency.symbol,
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          autofocus: !_isEdit,
                          inputFormatters: [ThousandsSeparatorFormatter()],
                          style: TextStyle(
                            color: AppColors.primaryLight,
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
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _nameCtrl,
              label: 'Nama Cicilan',
              hint: 'Contoh: Motor, Laptop, Pinjaman teman',
              icon: Icons.account_balance_wallet_rounded,
              focusColor: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _noteCtrl,
              label: 'Catatan',
              hint: 'Opsional',
              icon: Icons.sticky_note_2_rounded,
              focusColor: AppColors.info,
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 20),
            // Monthly amount toggle section
            _buildMonthlySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _useMonthlyAmount
              ? AppColors.warning.withAlpha(100)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _useMonthlyAmount
                        ? AppColors.warning.withAlpha(20)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: _useMonthlyAmount
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cicilan per bulan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Atur nominal yang dibayar tiap bulan',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useMonthlyAmount,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _useMonthlyAmount = val;
                      if (!val) _monthlyCtrl.clear();
                    });
                    _updateDuration();
                  },
                  activeThumbColor: AppColors.warning,
                  activeTrackColor: AppColors.warning.withAlpha(80),
                ),
              ],
            ),
          ),
          // Expandable input when toggled on
          if (_useMonthlyAmount) ...[
            Divider(
                color: AppColors.warning.withAlpha(60),
                height: 1,
                thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _snapshot.currency.symbol,
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _monthlyCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorFormatter()],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 22,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixText: '/ bulan',
                            suffixStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_computedDuration != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(
                          'Durasi cicilan: ~$_computedDuration bulan',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color focusColor,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return FocusFieldWrapper(
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
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: hasFocus ? focusColor.withAlpha(15) : AppColors.surfaceCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
}
