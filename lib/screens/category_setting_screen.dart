import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/widgets/color_picker_sheet.dart';
import 'package:sentra_app/widgets/icon_picker_sheet.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';

class CategorySettingScreen extends StatelessWidget {
  const CategorySettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories =
        context.watch<CategoriesCubit>().state.customCategories;
    final cubit = context.read<CategoriesCubit>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Kustom',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${categories.length} kategori aktif ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showCategoryDialog(context, cubit),
              icon: Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
              label: Text(
                'Tambah',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: categories.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: categories.asMap().entries.map((e) {
                      final i = e.key;
                      final cat = e.value;
                      final isLast = i == categories.length - 1;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                                left: 16, right: 8, top: 4, bottom: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cat.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(cat.icon,
                                  color: cat.color, size: 20),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _typeBadge(cat.type),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showCategoryDialog(
                                      context, cubit,
                                      existing: cat),
                                  icon: Icon(Icons.edit_rounded,
                                      color: AppColors.primary, size: 18),
                                  tooltip: 'Edit',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  onPressed: () => _confirmDelete(
                                      context, cubit, cat.id),
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: AppColors.expense, size: 18),
                                  tooltip: 'Hapus',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                                color: AppColors.surfaceBorder,
                                height: 1,
                                indent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: categories.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(context, cubit),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tambah Kategori',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Belum ada kategori kustom',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Buat kategori sesuai kebutuhanmu',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _typeBadge(TransactionType type) {
    final isIncome = type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isIncome ? 'Pemasukan' : 'Pengeluaran',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CategoriesCubit cubit, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Hapus Kategori?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Transaksi yang menggunakan kategori ini akan menjadi "Lainnya".',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) await cubit.deleteCustomCategory(id);
  }

  // ── Unified dialog: add (existing=null) or edit (existing=CustomCategory) ──

  void _showCategoryDialog(
    BuildContext context,
    CategoriesCubit cubit, {
    CustomCategory? existing,
  }) {
    final isEdit = existing != null;
    final nameCtrl =
        TextEditingController(text: isEdit ? existing.name : '');
    IconData selectedIcon =
        isEdit ? existing.icon : CustomCategory.iconChoices.first;
    Color selectedColor =
        isEdit ? existing.color : CustomCategory.colorChoices.first;
    TransactionType selectedType =
        isEdit ? existing.type : TransactionType.expense;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(selectedIcon,
                    color: selectedColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          label: 'Pengeluaran',
                          color: AppColors.expense,
                          selected:
                              selectedType == TransactionType.expense,
                          onTap: () => setD(
                              () => selectedType = TransactionType.expense),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _typeChip(
                          label: 'Pemasukan',
                          color: AppColors.income,
                          selected:
                              selectedType == TransactionType.income,
                          onTap: () => setD(
                              () => selectedType = TransactionType.income),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: !isEdit,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ikon',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                _iconButton(ctx, selectedIcon, selectedColor,
                    (picked) => setD(() => selectedIcon = picked)),
                const SizedBox(height: 16),
                Text('Warna',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                _colorButton(ctx, selectedColor,
                    (picked) => setD(() => selectedColor = picked)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (isEdit) {
                  await cubit.updateCustomCategory(
                    id: existing.id,
                    name: name,
                    icon: selectedIcon,
                    color: selectedColor,
                    type: selectedType,
                  );
                } else {
                  await cubit.addCustomCategory(
                    name: name,
                    icon: selectedIcon,
                    color: selectedColor,
                    type: selectedType,
                  );
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext ctx,
    IconData selectedIcon,
    Color selectedColor,
    ValueChanged<IconData> onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked =
            await IconPickerSheet.show(ctx, current: selectedIcon);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selectedColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selectedColor.withAlpha(80), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedColor.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(selectedIcon, color: selectedColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ikon terpilih',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Ketuk untuk ganti dari 150+ ikon',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _colorButton(
    BuildContext ctx,
    Color selectedColor,
    ValueChanged<Color> onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked =
            await ColorPickerSheet.show(ctx, current: selectedColor);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selectedColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selectedColor.withAlpha(80), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withAlpha(100),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warna terpilih',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Ketuk untuk buka color picker',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected ? Border.all(color: color.withAlpha(80)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
