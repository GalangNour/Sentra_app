import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class AddInstallmentScreen extends StatefulWidget {
  const AddInstallmentScreen({super.key});

  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final _state = AppState.instance;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await _state.addInstallmentPlan(
      name: _nameCtrl.text.trim(),
      totalAmount: amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(true);
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
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: const Text('Tambah Cicilan'),
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
                        _state.currency.symbol,
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
                          autofocus: true,
                          inputFormatters: [_ThousandsSeparatorFormatter()],
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
          ],
        ),
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
}

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

class _ThousandsSeparatorFormatter extends TextInputFormatter {
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
