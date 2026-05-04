import 'package:hive_flutter/hive_flutter.dart';

class AppStorage {
  const AppStorage({
    required this.transactionsBox,
    required this.customCategoriesBox,
    required this.installmentPlansBox,
    required this.settingsBox,
    required this.insightsBox,
  });

  final Box transactionsBox;
  final Box customCategoriesBox;
  final Box installmentPlansBox;
  final Box settingsBox;
  final Box insightsBox;

  static Future<AppStorage> init() async {
    await Hive.initFlutter();

    return AppStorage(
      transactionsBox: await Hive.openBox('transactions'),
      customCategoriesBox: await Hive.openBox('customCategories'),
      installmentPlansBox: await Hive.openBox('installmentPlans'),
      settingsBox: await Hive.openBox('settings'),
      insightsBox: await Hive.openBox('ai_insights'),
    );
  }
}
