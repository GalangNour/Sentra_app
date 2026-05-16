import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';

class ThemeSettingScreen extends StatelessWidget {
  const ThemeSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final current = ThemeConfig(
      preset: state.themePreset,
      accent: state.accent,
      font: state.fontPreset,
    );
    final visiblePresets = ThemePreset.forBrightness(current.preset.brightness);

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
              'Tema',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Tampilan & warna aksen ✦',
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
          _label('Mode'),
          const SizedBox(height: 10),
          _modeToggle(context, current, cubit),
          const SizedBox(height: 24),
          _label('Preset'),
          const SizedBox(height: 10),
          _presetCards(current, visiblePresets, cubit),
          const SizedBox(height: 24),
          _label('Warna Aksen'),
          const SizedBox(height: 10),
          _accentPicker(current, cubit),
          const SizedBox(height: 16),
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(3),
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

  Widget _modeToggle(
      BuildContext context, ThemeConfig current, SettingsCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeChip(
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              selected: current.preset.brightness == Brightness.dark,
              onTap: () async {
                HapticFeedback.selectionClick();
                if (current.preset.brightness == Brightness.dark) return;
                final next = ThemePreset.forBrightness(Brightness.dark).first;
                await cubit.setTheme(next, next.defaultAccent);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _modeChip(
              label: 'Light',
              icon: Icons.light_mode_rounded,
              selected: current.preset.brightness == Brightness.light,
              onTap: () async {
                HapticFeedback.selectionClick();
                if (current.preset.brightness == Brightness.light) return;
                final next = ThemePreset.forBrightness(Brightness.light).first;
                await cubit.setTheme(next, next.defaultAccent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withAlpha(18) : Colors.transparent,
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
            Icon(icon,
                size: 18,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary),
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

  Widget _presetCards(
      ThemeConfig current, List<ThemePreset> presets, SettingsCubit cubit) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final preset = presets[i];
          final isSelected = preset.id == current.preset.id;
          return GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              await cubit.setTheme(preset, preset.defaultAccent);
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
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
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
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _dot(preset.background),
                      const SizedBox(width: 3),
                      _dot(preset.surfaceCard),
                      const SizedBox(width: 3),
                      _dot(preset.surfaceBorder),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _accentPicker(ThemeConfig current, SettingsCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AccentColor.all.map((ac) {
              final isSelected =
                  current.accent.toARGB32() == ac.color.toARGB32();
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await cubit.setTheme(current.preset, ac.color);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ac.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
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
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Aksen aktif: ${_accentName(current.accent)}',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _accentName(Color accent) {
    final match = AccentColor.all
        .where((a) => a.color.toARGB32() == accent.toARGB32())
        .firstOrNull;
    return match?.name ?? 'Kustom';
  }
}
