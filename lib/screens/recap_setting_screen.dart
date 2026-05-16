import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/repositories/recap_repository.dart';
import 'package:sentra_app/core/services/recap_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/weekly_recap_screen.dart';

class RecapSettingScreen extends StatefulWidget {
  const RecapSettingScreen({super.key});

  @override
  State<RecapSettingScreen> createState() => _RecapSettingScreenState();
}

class _RecapSettingScreenState extends State<RecapSettingScreen> {
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
    final recapRepo = context.read<RecapRepository>();
    final day = recapRepo.getRecapDay();

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
              'Rekap Mingguan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Jadwal & pratinjau rekap ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _label('JADWAL'),
          const SizedBox(height: 10),
          _tile(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            title: 'Hari Rekap',
            subtitle: 'Rekap dikirim setiap ${_dayNames[day]}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dayNames[day],
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
            onTap: () => _showDayPicker(context, recapRepo),
          ),
          const SizedBox(height: 24),
          _label('TESTING'),
          const SizedBox(height: 10),
          _tile(
            icon: Icons.play_circle_outline_rounded,
            iconColor: AppColors.warning,
            title: 'Coba Rekap Sekarang',
            subtitle: 'Tampilkan rekap mingguan untuk testing',
            trailing:
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: () => _triggerTestRecap(context, recapRepo),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rekap mingguan merangkum pemasukan, pengeluaran, dan kategori terbesar dalam 7 hari terakhir.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showDayPicker(BuildContext context, RecapRepository repo) {
    final current = repo.getRecapDay();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Hari Rekap Mingguan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.surfaceBorder, height: 1),
            ...List.generate(7, (i) {
              final dayIndex = i + 1;
              final isSel = dayIndex == current;
              return ListTile(
                tileColor:
                    isSel ? AppColors.primary.withAlpha(18) : null,
                title: Text(
                  _dayNames[dayIndex],
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight:
                        isSel ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSel
                    ? Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await repo.setRecapDay(dayIndex);
                  if (mounted) setState(() {});
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
            }),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerTestRecap(
      BuildContext context, RecapRepository repo) async {
    HapticFeedback.mediumImpact();
    // Capture before async gap to avoid BuildContext-across-async lint
    final navigator = Navigator.of(context);
    final transactions =
        context.read<TransactionsCubit>().state.transactions;
    final customCategories =
        context.read<CategoriesCubit>().state.customCategories;

    await repo.triggerTest();
    if (!mounted) return;

    final recapData = RecapService.compute(
      transactions: transactions,
      customCategories: customCategories,
    );
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => WeeklyRecapScreen(
          recapData: recapData,
          recapRepository: repo,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}
