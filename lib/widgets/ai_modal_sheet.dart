import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/camera_screen.dart';
import 'package:sentra_app/screens/quick_input_screen.dart';
import 'package:sentra_app/screens/sentra_brain_screen.dart';

class AiModalSheet extends StatelessWidget {
  const AiModalSheet({super.key, required this.parentContext});

  final BuildContext parentContext;

  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AiModalSheet(parentContext: context),
    );
  }

  FinanceSnapshot _buildSnapshot() {
    return FinanceSnapshot(
      transactions: parentContext.read<TransactionsCubit>().state.transactions,
      customCategories:
          parentContext.read<CategoriesCubit>().state.customCategories,
      installmentPlans:
          parentContext.read<InstallmentsCubit>().state.installmentPlans,
      currency: parentContext.read<SettingsCubit>().state.currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mau ngapain?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih cara berinteraksi dengan AI',
            style: TextStyle(
              color: AppColors.textMuted.withAlpha(153),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _OptionTile(
            leadingColor: AppColors.primary,
            leadingIcon: Icons.auto_awesome_rounded,
            title: 'Sentra Brain',
            subtitle: 'Tanya apapun soal keuanganmu',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              final snapshot = _buildSnapshot();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => SentraBrainScreen(snapshot: snapshot),
                ),
              );
            },
          ),
          _OptionTile(
            leadingColor: AppColors.income,
            leadingIcon: Icons.edit_rounded,
            title: 'Quick Input',
            subtitle: 'Catat transaksi dengan teks natural',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => const QuickInputScreen(),
                ),
              );
            },
          ),
          _OptionTile(
            leadingColor: AppColors.info,
            leadingIcon: Icons.document_scanner_rounded,
            title: 'Scan Struk',
            subtitle: 'Foto struk belanja, AI yang catat',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              Navigator.of(parentContext).push(
                PageRouteBuilder(
                  pageBuilder: (ctx, anim, secAnim) => const CameraScreen(),
                  transitionsBuilder: (ctx, anim, secAnim, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            },
          ),
          Opacity(
            opacity: 0.5,
            child: _OptionTile(
              leadingColor: AppColors.textMuted,
              leadingIcon: Icons.mic_rounded,
              title: 'Voice Input',
              subtitle: 'Rekam suara, AI yang catat',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Segera',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Voice Input segera hadir 🎙️'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.leadingColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final Color leadingColor;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: leadingColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(leadingIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
      ),
    );
  }
}
