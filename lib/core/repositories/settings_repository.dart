import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  final Box _box;

  const SettingsRepository(this._box);

  String getCurrencyCode() =>
      _box.get('currency_code', defaultValue: 'IDR') as String;

  Future<void> setCurrencyCode(String code) async {
    await _box.put('currency_code', code);
  }

  String getThemePresetId() =>
      _box.get('theme_preset_id', defaultValue: 'navy') as String;

  int getThemeAccent() =>
      _box.get('theme_accent', defaultValue: 0xFF6C63FF) as int;

  Future<void> saveTheme({
    required String presetId,
    required int accentValue,
  }) async {
    await _box.put('theme_preset_id', presetId);
    await _box.put('theme_accent', accentValue);
  }
}
