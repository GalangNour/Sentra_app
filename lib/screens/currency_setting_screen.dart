import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/currency_info.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';

class CurrencySettingScreen extends StatefulWidget {
  const CurrencySettingScreen({super.key});

  @override
  State<CurrencySettingScreen> createState() => _CurrencySettingScreenState();
}

class _CurrencySettingScreenState extends State<CurrencySettingScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final current = state.currency;

    final filtered = _query.isEmpty
        ? CurrencyInfo.all
        : CurrencyInfo.all
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                c.code.toLowerCase().contains(_query.toLowerCase()) ||
                c.symbol.toLowerCase().contains(_query.toLowerCase()))
            .toList();

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
              'Mata Uang',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Simbol & format angka ✦',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari mata uang...',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 4,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => Divider(
                color: AppColors.surfaceBorder,
                height: 1,
                indent: 72,
              ),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final sel = c.code == current.code;
                return ListTile(
                  tileColor: sel ? AppColors.primary.withAlpha(12) : null,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withAlpha(30)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary.withAlpha(60)
                            : AppColors.surfaceBorder,
                      ),
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
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: sel
                      ? Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 18),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await cubit.setCurrency(c);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
