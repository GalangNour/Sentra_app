import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/currency_info.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CurrencyInfo _currency;
  late List<CustomCategory> _customCategories;
  late ThemePreset _themePreset;
  late Color _accent;
  late FontPreset _fontPreset;
  late SettingsCubit _settingsCubit;
  late CategoriesCubit _categoriesCubit;
  late TransactionsCubit _transactionsCubit;

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final categoriesState = context.watch<CategoriesCubit>().state;
    _settingsCubit = context.read<SettingsCubit>();
    _categoriesCubit = context.read<CategoriesCubit>();
    _transactionsCubit = context.read<TransactionsCubit>();
    _currency = settingsState.currency;
    _themePreset = settingsState.themePreset;
    _accent = settingsState.accent;
    _fontPreset = settingsState.fontPreset;
    _customCategories = categoriesState.customCategories;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(true),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _sectionLabel('Mata Uang'),
          _buildCurrencyTile(),
          const SizedBox(height: 24),
          _sectionLabel('Tema'),
          _buildThemeSection(),
          const SizedBox(height: 24),
          _sectionLabel('Gaya Font'),
          _buildFontSection(),
          const SizedBox(height: 24),
          _sectionLabel('Kategori Kustom'),
          _buildCustomCategoryList(),
          _buildAddCategoryButton(),
          const SizedBox(height: 24),
          _sectionLabel('Data'),
          _buildClearDataTile(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  // ─── Currency ───────────────────────────────────────────

  Widget _buildCurrencyTile() {
    return _tile(
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.income,
      title: _currency.name,
      subtitle: '${_currency.symbol} · ${_currency.code}',
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: _showCurrencyPicker,
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih Mata Uang',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.surfaceBorder, height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 4,
                  ),
                  itemCount: CurrencyInfo.all.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.surfaceBorder,
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (_, i) {
                    final c = CurrencyInfo.all[i];
                    final sel = c.code == _currency.code;
                    return ListTile(
                      tileColor: sel ? AppColors.primary.withAlpha(18) : null,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withAlpha(30)
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            c.symbol,
                            style: TextStyle(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        c.code,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: sel
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () async {
                        await _settingsCubit.setCurrency(c);
                        if (mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setThemeBrightness(Brightness brightness) async {
    if (_themePreset.brightness == brightness) return;
    final nextPreset = ThemePreset.forBrightness(brightness).first;
    await _settingsCubit.setTheme(nextPreset, _accent);
  }

  // ─── Theme Section ──────────────────────────────────────

  Widget _buildThemeSection() {
    final current = ThemeConfig(preset: _themePreset, accent: _accent, font: _fontPreset);
    final visiblePresets = ThemePreset.forBrightness(current.preset.brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _themeModeChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: current.preset.brightness == Brightness.dark,
                  onTap: () => _setThemeBrightness(Brightness.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _themeModeChip(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: current.preset.brightness == Brightness.light,
                  onTap: () => _setThemeBrightness(Brightness.light),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Preset cards
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visiblePresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final preset = visiblePresets[i];
              final isSelected = preset.id == current.preset.id;
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await _settingsCubit.setTheme(preset, preset.defaultAccent);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 88,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: preset.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? current.accent : preset.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: current.accent.withAlpha(60),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: preset.defaultAccent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const Spacer(),
                          Icon(preset.icon, size: 14, color: preset.textMuted),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        preset.name,
                        style: TextStyle(
                          color: isSelected
                              ? preset.textPrimary
                              : preset.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _colorDot(preset.background),
                          const SizedBox(width: 3),
                          _colorDot(preset.surfaceCard),
                          const SizedBox(width: 3),
                          _colorDot(preset.surfaceBorder),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Accent color picker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warna Aksen',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AccentColor.all.map((ac) {
                  final isSelected =
                      current.accent.toARGB32() == ac.color.toARGB32();
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await _settingsCubit.setTheme(current.preset, ac.color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ac.color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : Border.all(color: Colors.transparent, width: 2.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: ac.color.withAlpha(120),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Aksen aktif: ${_accentName(current.accent)}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Preview strip
        Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _colorDot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _themeModeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary.withAlpha(76)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _accentName(Color accent) {
    final match = AccentColor.all
        .where((a) => a.color.toARGB32() == accent.toARGB32())
        .firstOrNull;
    return match?.name ?? 'Kustom';
  }

  // ─── Font Section ───────────────────────────────────────

  Widget _buildFontSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FontPreset.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final font = FontPreset.all[i];
              final isSelected = font.id == _fontPreset.id;
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await _settingsCubit.setFont(font);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 148,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(18)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(50),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            font.emoji,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Preview angka
                      Text(
                        'Rp 1.250.000',
                        style: font.style(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        font.name,
                        style: font.style(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        font.description,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Preview strip aktif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Font aktif: ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                _fontPreset.name,
                style: _fontPreset.style(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _fontPreset.description,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Custom Categories ──────────────────────────────────

  Widget _buildCustomCategoryList() {
    if (_customCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Center(
          child: Text(
            'Belum ada kategori kustom',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: _customCategories.asMap().entries.map((e) {
          final i = e.key;
          final cat = e.value;
          final isLast = i == _customCategories.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cat.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 18),
                ),
                title: Text(
                  cat.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () => _deleteCategory(cat.id),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.expense,
                    size: 20,
                  ),
                ),
              ),
              if (!isLast)
                Divider(color: AppColors.surfaceBorder, height: 1, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: _showAddCategoryDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withAlpha(76),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                'Tambah Kategori',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Hapus Kategori?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
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
    if (confirm == true) {
      await _categoriesCubit.deleteCustomCategory(id);
    }
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = CustomCategory.iconChoices.first;
    Color selectedColor = CustomCategory.colorChoices.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text(
            'Tambah Kategori',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
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
                Text(
                  'Ikon',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CustomCategory.iconChoices.map((icon) {
                    final sel = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setD(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sel
                              ? selectedColor.withAlpha(51)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? selectedColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: sel ? selectedColor : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Warna',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CustomCategory.colorChoices.map((color) {
                    final sel = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setD(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(102),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _categoriesCubit.addCustomCategory(
                  name: nameCtrl.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text('Simpan', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Clear Data ─────────────────────────────────────────

  Widget _buildClearDataTile() {
    return _tile(
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.expense,
      title: 'Hapus Semua Transaksi',
      subtitle: 'Tidak dapat dibatalkan',
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            title: Text(
              'Hapus Semua Data?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Seluruh riwayat transaksi akan dihapus permanen.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Hapus Semua',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _transactionsCubit.clearAllTransactions();
        }
      },
    );
  }

  // ─── Shared tile widget ─────────────────────────────────

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
