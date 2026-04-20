import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

// ─── Data from scan ───────────────────────────────────────
class ParsedReceiptData {
  final String merchant;
  final double total;
  final DateTime date;
  final TransactionCategory category;
  final String? imagePath;
  final String? rawText;

  ParsedReceiptData({
    required this.merchant,
    required this.total,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawText,
  });
}

// ─── Screen ───────────────────────────────────────────────
class ScanResultScreen extends StatefulWidget {
  final ParsedReceiptData data;
  const ScanResultScreen({super.key, required this.data});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TransactionCategory _category;
  late TransactionType _type;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.data.merchant);
    _amountCtrl =
        TextEditingController(text: widget.data.total.toInt().toString());
    _category = widget.data.category;
    _type = TransactionType.expense;

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.expense : AppColors.income;

  void _save() {
    final amount = double.tryParse(
          _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        widget.data.total;

    if (_titleCtrl.text.trim().isEmpty || amount <= 0) {
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
      date: widget.data.date,
      fromScan: true,
    ));

    setState(() => _saved = true);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSuccessBadge(),
                    const SizedBox(height: 20),
                    _buildAmountCard(),
                    const SizedBox(height: 16),
                    _buildDetailsForm(),
                    const SizedBox(height: 16),
                    _buildCategoryPicker(),
                    if (widget.data.rawText != null &&
                        widget.data.rawText!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildRawTextSection(),
                    ],
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
                    _buildDiscardButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      title: const Text('Konfirmasi Transaksi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    );
  }

  // ─── Success Badge ────────────────────────────────────────

  Widget _buildSuccessBadge() {
    final hasAmount = widget.data.total > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (hasAmount ? AppColors.income : AppColors.warning).withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (hasAmount ? AppColors.income : AppColors.warning).withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (hasAmount ? AppColors.income : AppColors.warning).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasAmount
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: hasAmount ? AppColors.income : AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAmount ? 'Total berhasil ditemukan!' : 'Total tidak terdeteksi',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  hasAmount
                      ? 'Periksa & edit jika perlu, lalu simpan'
                      : 'Masukkan jumlah secara manual',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Thumbnail jika ada gambar
          if (widget.data.imagePath != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(widget.data.imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Amount Card ─────────────────────────────────────────

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3E), Color(0xFF252D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _typeColor.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: _typeColor.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type toggle
          Row(
            children: [
              _typeChip(TransactionType.expense, 'Pengeluaran',
                  Icons.arrow_upward_rounded),
              const SizedBox(width: 8),
              _typeChip(TransactionType.income, 'Pemasukan',
                  Icons.arrow_downward_rounded),
            ],
          ),
          const SizedBox(height: 18),

          // Amount input
          Text(
            _type == TransactionType.expense ? 'Jumlah Pengeluaran' : 'Jumlah Pemasukan',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Rp',
                  style: TextStyle(
                      color: _typeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 34),
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

  Widget _typeChip(TransactionType t, String label, IconData icon) {
    final sel = _type == t;
    final color = t == TransactionType.expense ? AppColors.expense : AppColors.income;
    return GestureDetector(
      onTap: () {
        setState(() => _type = t);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? color.withAlpha(38) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color.withAlpha(102) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: sel ? color : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: sel ? color : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  // ─── Details Form ─────────────────────────────────────────

  Widget _buildDetailsForm() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Nama / Merchant',
                prefixIcon: Icon(Icons.store_rounded,
                    size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1, indent: 16),
          ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.textMuted),
            title: const Text('Tanggal',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: Text(
              Fmt.date(widget.data.date),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Picker ─────────────────────────────────────

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Kategori',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TransactionCategory.values.map((c) {
            final sel = c == _category;
            final color = CategoryMeta.color(c);
            return GestureDetector(
              onTap: () {
                setState(() => _category = c);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? color.withAlpha(38) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? color.withAlpha(102) : AppColors.surfaceBorder,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CategoryMeta.icon(c),
                        size: 16,
                        color: sel ? color : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(CategoryMeta.label(c),
                        style: TextStyle(
                          color: sel ? color : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Raw OCR Text (collapsed by default) ─────────────────

  Widget _buildRawTextSection() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: const Icon(Icons.text_snippet_outlined,
              color: AppColors.textMuted, size: 18),
          title: const Text('Teks OCR Mentah',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
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
                widget.data.rawText!,
                style: const TextStyle(
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

  // ─── Buttons ─────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saved ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        decoration: BoxDecoration(
          gradient:
              _saved ? AppColors.incomeGradient : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_saved ? AppColors.income : AppColors.primary)
                  .withAlpha(76),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _saved
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Tersimpan!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Simpan Transaksi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDiscardButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(
          child: Text('Buang',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
