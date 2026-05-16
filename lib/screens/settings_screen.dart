import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/repositories/recap_repository.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/category_setting_screen.dart';
import 'package:sentra_app/screens/currency_setting_screen.dart';
import 'package:sentra_app/screens/font_setting_screen.dart';
import 'package:sentra_app/screens/recap_setting_screen.dart';
import 'package:sentra_app/screens/theme_setting_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _dayNames = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final categories =
        context.watch<CategoriesCubit>().state.customCategories;
    final recapRepo = context.read<RecapRepository>();
    final recapDay = recapRepo.getRecapDay();

    final currentTheme = ThemeConfig(
      preset: settings.themePreset,
      accent: settings.accent,
      font: settings.fontPreset,
    );
    final accentName = AccentColor.all
        .where((a) => a.color.toARGB32() == settings.accent.toARGB32())
        .firstOrNull
        ?.name ?? 'Kustom';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Preferensi aplikasi ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ── Tampilan ───────────────────────────────────────
          _sectionLabel('TAMPILAN'),
          const SizedBox(height: 8),
          _group([
            _navTile(
              context,
              icon: Icons.palette_rounded,
              iconColor: AppColors.primary,
              title: 'Tema',
              subtitle:
                  '${currentTheme.preset.name} · $accentName',
              destination: const ThemeSettingScreen(),
            ),
            _navTile(
              context,
              icon: Icons.text_fields_rounded,
              iconColor: Colors.teal,
              title: 'Gaya Font',
              subtitle: settings.fontPreset.name,
              destination: const FontSettingScreen(),
            ),
            _navTile(
              context,
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.income,
              title: 'Mata Uang',
              subtitle:
                  '${settings.currency.code} · ${settings.currency.symbol}',
              destination: const CurrencySettingScreen(),
              showDivider: false,
            ),
          ]),

          const SizedBox(height: 24),

          // ── Transaksi ──────────────────────────────────────
          _sectionLabel('TRANSAKSI'),
          const SizedBox(height: 8),
          _group([
            _navTile(
              context,
              icon: Icons.label_rounded,
              iconColor: Colors.purple,
              title: 'Kategori Kustom',
              subtitle: categories.isEmpty
                  ? 'Belum ada kategori'
                  : '${categories.length} kategori',
              destination: const CategorySettingScreen(),
              showDivider: false,
            ),
          ]),

          const SizedBox(height: 24),

          // ── Fitur ──────────────────────────────────────────
          _sectionLabel('FITUR'),
          const SizedBox(height: 8),
          _group([
            _navTile(
              context,
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.warning,
              title: 'Rekap Mingguan',
              subtitle: 'Setiap ${_dayNames[recapDay]}',
              destination: const RecapSettingScreen(),
              showDivider: false,
            ),
          ]),

          const SizedBox(height: 24),

          // ── Data ───────────────────────────────────────────
          _sectionLabel('DATA'),
          const SizedBox(height: 8),
          _group([
            _dangerTile(context),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget destination,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const SizedBox(width: 14),
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
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              color: AppColors.surfaceBorder, height: 1, indent: 68),
      ],
    );
  }

  Widget _dangerTile(BuildContext context) {
    return InkWell(
      onTap: () => _confirmClearData(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.expense.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded,
                  color: AppColors.expense, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hapus Semua Transaksi',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Tidak dapat dibatalkan',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Hapus Semua Data?',
            style: TextStyle(color: AppColors.textPrimary)),
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
            child: Text('Hapus Semua',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<TransactionsCubit>().clearAllTransactions();
    }
  }
}
