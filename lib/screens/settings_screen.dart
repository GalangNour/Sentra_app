import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _state = AppState.instance;

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(true),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _sectionLabel('Mata Uang'),
          _buildCurrencyTile(),
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
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      );

  // ─── Currency ───────────────────────────────────────────

  Widget _buildCurrencyTile() {
    return _tile(
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.income,
      title: _state.currency.name,
      subtitle: '${_state.currency.symbol} · ${_state.currency.code}',
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted),
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
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
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
              const Text(
                'Pilih Mata Uang',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              // Scrollable list
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 4,
                  ),
                  itemCount: CurrencyInfo.all.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.surfaceBorder,
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (_, i) {
                    final c = CurrencyInfo.all[i];
                    final sel = c.code == _state.currency.code;
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
                          color: sel
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        c.code,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: sel
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () async {
                        await _state.setCurrency(c);
                        setState(() {});
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


  // ─── Custom Categories ──────────────────────────────────

  Widget _buildCustomCategoryList() {
    if (_state.customCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(
          child: Text('Belum ada kategori kustom',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
        children: _state.customCategories.asMap().entries.map((e) {
          final i = e.key;
          final cat = e.value;
          final isLast = i == _state.customCategories.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cat.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 18),
                ),
                title: Text(cat.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                trailing: GestureDetector(
                  onTap: () => _deleteCategory(cat.id),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.expense, size: 20),
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
                style: BorderStyle.solid),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text('Tambah Kategori',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
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
        title: const Text('Hapus Kategori?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'Transaksi yang menggunakan kategori ini akan menjadi "Lainnya".',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (confirm == true) {
      await _state.deleteCustomCategory(id);
      setState(() {});
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
          title: const Text('Tambah Kategori',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name input
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
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

                // Icon picker
                const Text('Ikon',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CustomCategory.iconChoices.map((icon) {
                    final sel = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setD(() => selectedIcon = icon),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: sel
                              ? selectedColor.withAlpha(51)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? selectedColor
                                  : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Icon(icon,
                            color: sel ? selectedColor : AppColors.textMuted,
                            size: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text('Warna',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CustomCategory.colorChoices.map((color) {
                    final sel = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setD(() => selectedColor = color),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: sel
                              ? [BoxShadow(color: color.withAlpha(102), blurRadius: 8)]
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
                child: const Text('Batal',
                    style: TextStyle(color: AppColors.textMuted))),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _state.addCustomCategory(
                  name: nameCtrl.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                );
                setState(() {});
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan',
                  style: TextStyle(color: AppColors.primary)),
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
            title: const Text('Hapus Semua Data?',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text(
                'Seluruh riwayat transaksi akan dihapus permanen.',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hapus Semua',
                      style: TextStyle(color: AppColors.expense))),
            ],
          ),
        );
        if (confirm == true) {
          await _state.clearAllTransactions();
          setState(() {});
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
              width: 38, height: 38,
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
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
