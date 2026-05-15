import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  const AppStorage({
    required this.transactionsBox,
    required this.customCategoriesBox,
    required this.installmentPlansBox,
    required this.settingsBox,
    required this.insightsBox,
    required this.budgetsBox,
    required this.prefs,
  });

  final Box transactionsBox;
  final Box customCategoriesBox;
  final Box installmentPlansBox;
  final Box settingsBox;
  final Box insightsBox;
  final Box budgetsBox;
  final SharedPreferences prefs;

  static Future<AppStorage> init() async {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();

    // Persist the install weekday so recap_start_day is stable across days
    if (!prefs.containsKey('recap_start_day')) {
      await prefs.setInt('recap_start_day', DateTime.now().weekday);
    }

    return AppStorage(
      transactionsBox: await Hive.openBox('transactions'),
      customCategoriesBox: await Hive.openBox('customCategories'),
      installmentPlansBox: await Hive.openBox('installmentPlans'),
      settingsBox: await Hive.openBox('settings'),
      insightsBox: await Hive.openBox('ai_insights'),
      budgetsBox: await Hive.openBox('budgets'),
      prefs: prefs,
    );
  }
}
