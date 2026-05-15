import 'package:shared_preferences/shared_preferences.dart';

class RecapRepository {
  static const _kRecapDay = 'recap_start_day';
  static const _kLastSeen = 'last_recap_seen';
  static const _kForceShow = 'recap_force_show';

  final SharedPreferences _prefs;

  RecapRepository(this._prefs);

  // 1=Senin ... 7=Minggu (matches DateTime.weekday)
  int getRecapDay() => _prefs.getInt(_kRecapDay) ?? DateTime.now().weekday;

  Future<void> setRecapDay(int day) async {
    await _prefs.setInt(_kRecapDay, day);
  }

  DateTime? getLastSeen() {
    final s = _prefs.getString(_kLastSeen);
    return s == null ? null : DateTime.tryParse(s);
  }

  Future<void> markSeen() async {
    await _prefs.setString(_kLastSeen, DateTime.now().toIso8601String());
    await _prefs.remove(_kForceShow);
  }

  Future<void> triggerTest() async {
    await _prefs.setBool(_kForceShow, true);
  }

  bool isRecapAvailable() {
    if (_prefs.getBool(_kForceShow) == true) return true;
    final now = DateTime.now();
    if (now.weekday != getRecapDay()) return false;
    final last = getLastSeen();
    if (last == null) return true;
    return now.difference(last).inDays >= 7;
  }
}
