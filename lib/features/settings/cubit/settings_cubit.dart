import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/currency_info.dart';
import 'package:sentra_app/core/repositories/settings_repository.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/formatters.dart';
import 'package:sentra_app/features/settings/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
    : super(
        SettingsState(
          currency: CurrencyInfo.fromCode(_repository.getCurrencyCode()),
          themePreset: ThemePreset.fromId(_repository.getThemePresetId()),
          accent: Color(_repository.getThemeAccent()),
          fontPreset: FontPreset.fromId(_repository.getFontPresetId()),
        ),
      ) {
    _apply(state);
  }

  final SettingsRepository _repository;

  void _apply(SettingsState s) {
    Fmt.setCurrency(s.currency);
    ThemeConfig.apply(s.themePreset, s.accent, s.fontPreset);
  }

  Future<void> setCurrency(CurrencyInfo currency) async {
    await _repository.setCurrencyCode(currency.code);
    final next = state.copyWith(currency: currency);
    _apply(next);
    emit(next);
  }

  Future<void> setTheme(ThemePreset preset, Color accent) async {
    await _repository.saveTheme(
      presetId: preset.id,
      accentValue: accent.toARGB32(),
    );
    final next = state.copyWith(themePreset: preset, accent: accent);
    _apply(next);
    emit(next);
  }

  Future<void> setFont(FontPreset font) async {
    await _repository.setFontPresetId(font.id);
    final next = state.copyWith(fontPreset: font);
    _apply(next);
    emit(next);
  }
}
