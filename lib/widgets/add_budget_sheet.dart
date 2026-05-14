import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/constants/category_meta.dart';
import 'package:sentra_app/core/models/budget_item.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/budgets/cubit/budgets_cubit.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/widgets/thousands_separator_formatter.dart';

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({super.key, this.existingBudget});

  final BudgetItem? existingBudget;

  static Future<void> show(
    BuildContext context, {
    BudgetItem? existingBudget,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetsCubit>(),
        child: BlocProvider.value(
          value: context.read<CategoriesCubit>(),
          child: AddBudgetSheet(existingBudget: existingBudget),
        ),
      ),
    );
  }

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  TransactionCategory? _selectedCategory;
  CustomCategory? _selectedCustomCategory;
  final _limitController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _selectedCategory = widget.existingBudget!.category;
      if (widget.existingBudget!.limit > 0) {
        final formatted = _formatAmount(widget.existingBudget!.limit.toInt());
        _limitController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  double get _parsedLimit {
    final raw = _limitController.text.replaceAll('.', '');
    return double.tryParse(raw) ?? 0;
  }

  bool get _hasSelection =>
      _selectedCategory != null || _selectedCustomCategory != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasSelection) return;

    final now = DateTime.now();
    final id = BudgetItem.makeId(
      category: _selectedCategory,
      customCategoryId: _selectedCustomCategory?.id,
      month: now.month,
      year: now.year,
    );
    final budget = BudgetItem(
      id: id,
      category: _selectedCategory,
      customCategoryId: _selectedCustomCategory?.id,
      limit: _parsedLimit,
      month: now.month,
      year: now.year,
    );

    HapticFeedback.mediumImpact();
    context.read<BudgetsCubit>().setBudget(budget);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final customCategories = context
        .read<CategoriesCubit>()
        .state
        .customCategories
        .where((c) => c.type == TransactionType.expense)
        .toList();

    final existingIds = context
        .read<BudgetsCubit>()
        .state
        .budgets
        .where((b) {
          final now = DateTime.now();
          return b.month == now.month && b.year == now.year;
        })
        .map((b) => b.customCategoryId ?? b.category?.name)
        .toSet();

    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.existingBudget != null
                          ? 'Edit Budget'
                          : 'Atur Budget',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih kategori & set limit pengeluaran bulan ini',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryGrid(
                          customCategories,
                          existingIds,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Limit Pengeluaran',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _limitController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorFormatter()],
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Masukkan nominal limit';
                            }
                            if (_parsedLimit <= 0) {
                              return 'Limit harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _hasSelection ? _save : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: _hasSelection
                                    ? AppColors.primaryGradient
                                    : null,
                                color: _hasSelection
                                    ? null
                                    : AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Simpan Budget',
                                style: TextStyle(
                                  color: _hasSelection
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<CustomCategory> customCategories,
    Set<String?> existingIds,
  ) {
    final builtInCategories = CategoryMeta.forType(TransactionType.expense);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in builtInCategories)
          _categoryChip(
            label: CategoryMeta.label(cat),
            icon: CategoryMeta.icon(cat),
            color: CategoryMeta.color(cat),
            isSelected: _selectedCategory == cat &&
                _selectedCustomCategory == null,
            isAlreadySet: existingIds.contains(cat.name) &&
                widget.existingBudget?.category != cat,
            onTap: () => setState(() {
              _selectedCategory = cat;
              _selectedCustomCategory = null;
            }),
          ),
        for (final custom in customCategories)
          _categoryChip(
            label: custom.name,
            icon: custom.icon,
            color: custom.color,
            isSelected: _selectedCustomCategory?.id == custom.id,
            isAlreadySet: existingIds.contains(custom.id) &&
                widget.existingBudget?.customCategoryId != custom.id,
            onTap: () => setState(() {
              _selectedCustomCategory = custom;
              _selectedCategory = null;
            }),
          ),
      ],
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isAlreadySet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAlreadySet
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(38)
              : isAlreadySet
              ? AppColors.surfaceCard.withAlpha(120)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color.withAlpha(180)
                : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isAlreadySet ? AppColors.textMuted : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isAlreadySet
                    ? AppColors.textMuted
                    : isSelected
                    ? color
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isAlreadySet) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
