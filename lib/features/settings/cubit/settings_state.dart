import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sentra_app/core/models/currency_info.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.currency,
    required this.themePreset,
    required this.accent,
  });

  final CurrencyInfo currency;
  final ThemePreset themePreset;
  final Color accent;

  SettingsState copyWith({
    CurrencyInfo? currency,
    ThemePreset? themePreset,
    Color? accent,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themePreset: themePreset ?? this.themePreset,
      accent: accent ?? this.accent,
    );
  }

  @override
  List<Object?> get props => [currency.code, themePreset.id, accent.toARGB32()];
}
