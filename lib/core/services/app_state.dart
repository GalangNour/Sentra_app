import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final bool symbolBefore;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.symbolBefore = true,
  });

  static const idr = CurrencyInfo(
    code: 'IDR',
    symbol: 'Rp',
    name: 'Rupiah Indonesia',
  );
  static const usd = CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const sgd = CurrencyInfo(
    code: 'SGD',
    symbol: 'S\$',
    name: 'Singapore Dollar',
  );
  static const myr = CurrencyInfo(
    code: 'MYR',
    symbol: 'RM',
    name: 'Malaysian Ringgit',
  );
  static const eur = CurrencyInfo(code: 'EUR', symbol: 'EUR', name: 'Euro');
  static const gbp = CurrencyInfo(
    code: 'GBP',
    symbol: 'GBP',
    name: 'British Pound',
  );
  static const jpy = CurrencyInfo(
    code: 'JPY',
    symbol: 'JPY',
    name: 'Japanese Yen',
  );
  static const aud = CurrencyInfo(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
  );
  static const cny = CurrencyInfo(
    code: 'CNY',
    symbol: 'CNY',
    name: 'Chinese Yuan',
  );
  static const krw = CurrencyInfo(
    code: 'KRW',
    symbol: 'KRW',
    name: 'Korean Won',
  );
  static const thb = CurrencyInfo(
    code: 'THB',
    symbol: 'THB',
    name: 'Thai Baht',
  );
  static const php = CurrencyInfo(
    code: 'PHP',
    symbol: 'PHP',
    name: 'Philippine Peso',
  );

  static const all = [
    idr,
    usd,
    sgd,
    myr,
    eur,
    gbp,
    jpy,
    aud,
    cny,
    krw,
    thb,
    php,
  ];

  static CurrencyInfo fromCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => idr);
}

class CustomCategory {
  final String id;
  final String name;
  final int iconCode;
  final String fontFamily;
  final int colorValue;

  const CustomCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.fontFamily,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: fontFamily);
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'fontFamily': fontFamily,
    'colorValue': colorValue,
  };

  factory CustomCategory.fromMap(Map<String, dynamic> m) => CustomCategory(
    id: m['id'] as String,
    name: m['name'] as String,
    iconCode: m['iconCode'] as int,
    fontFamily: m['fontFamily'] as String,
    colorValue: m['colorValue'] as int,
  );

  static const iconChoices = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
    Icons.sports_soccer_rounded,
    Icons.music_note_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.computer_rounded,
    Icons.smartphone_rounded,
    Icons.book_rounded,
    Icons.sports_esports_rounded,
    Icons.local_gas_station_rounded,
    Icons.child_care_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_rounded,
    Icons.videogame_asset_rounded,
  ];

  static const colorChoices = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B6B),
    Color(0xFF00C896),
    Color(0xFFFFB547),
    Color(0xFF38BDF8),
    Color(0xFFFF6B9D),
    Color(0xFFB06EF7),
    Color(0xFF00E5FF),
    Color(0xFFFF8C42),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF795548),
  ];
}

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  late Box _txBox;
  late Box _catBox;
  late Box _installmentBox;
  late Box _settingsBox;

  List<Transaction> transactions = [];
  List<CustomCategory> customCategories = [];
  List<InstallmentPlan> installmentPlans = [];
  CurrencyInfo currency = CurrencyInfo.idr;

  static const _uuid = Uuid();

  static VoidCallback? _rebuildApp;
  static void registerRebuild(VoidCallback fn) => _rebuildApp = fn;
  static void _triggerRebuild() => _rebuildApp?.call();

  Future<void> init() async {
    await Hive.initFlutter();
    _txBox = await Hive.openBox('transactions');
    _catBox = await Hive.openBox('customCategories');
    _installmentBox = await Hive.openBox('installmentPlans');
    _settingsBox = await Hive.openBox('settings');

    _loadTransactions();
    _loadCustomCategories();
    _loadInstallments();
    _loadSettings();
  }

  void _loadTransactions() {
    transactions =
        _txBox.values
            .map(
              (v) => Transaction.fromMap(Map<String, dynamic>.from(v as Map)),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _loadCustomCategories() {
    customCategories = _catBox.values
        .map((v) => CustomCategory.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  void _loadInstallments() {
    installmentPlans =
        _installmentBox.values
            .map(
              (v) =>
                  InstallmentPlan.fromMap(Map<String, dynamic>.from(v as Map)),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _loadSettings() {
    final code =
        _settingsBox.get('currency_code', defaultValue: 'IDR') as String;
    currency = CurrencyInfo.fromCode(code);
    Fmt.setCurrency(currency);

    final presetId =
        _settingsBox.get('theme_preset_id', defaultValue: 'navy') as String;
    final accentValue =
        _settingsBox.get('theme_accent', defaultValue: 0xFF6C63FF) as int;
    ThemeConfig.apply(ThemePreset.fromId(presetId), Color(accentValue));
  }

  Future<void> addTransaction(Transaction tx) async {
    await _txBox.put(tx.id, tx.toMap());
    transactions.insert(0, tx);
    transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteTransaction(String id) async {
    await _txBox.delete(id);
    transactions.removeWhere((t) => t.id == id);
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _txBox.put(tx.id, tx.toMap());
    final idx = transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) transactions[idx] = tx;
    transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> clearAllTransactions() async {
    await _txBox.clear();
    transactions.clear();
  }

  Future<CustomCategory> addCustomCategory({
    required String name,
    required IconData icon,
    required Color color,
  }) async {
    final cat = CustomCategory(
      id: _uuid.v4(),
      name: name,
      iconCode: icon.codePoint,
      fontFamily: icon.fontFamily ?? 'MaterialIcons',
      colorValue: color.toARGB32(),
    );
    await _catBox.put(cat.id, cat.toMap());
    customCategories.add(cat);
    return cat;
  }

  Future<void> deleteCustomCategory(String id) async {
    await _catBox.delete(id);
    customCategories.removeWhere((c) => c.id == id);
  }

  Future<InstallmentPlan> addInstallmentPlan({
    required String name,
    required double totalAmount,
    String? note,
  }) async {
    final plan = InstallmentPlan(
      id: _uuid.v4(),
      name: name,
      totalAmount: totalAmount,
      createdAt: DateTime.now(),
      note: note,
    );
    await _installmentBox.put(plan.id, plan.toMap());
    installmentPlans.insert(0, plan);
    installmentPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plan;
  }

  Future<void> deleteInstallmentPlan(String id) async {
    await _installmentBox.delete(id);
    installmentPlans.removeWhere((p) => p.id == id);
  }

  Future<void> setCurrency(CurrencyInfo c) async {
    currency = c;
    Fmt.setCurrency(c);
    await _settingsBox.put('currency_code', c.code);
  }

  Future<void> setTheme(ThemePreset preset, Color accent) async {
    ThemeConfig.apply(preset, accent);
    await _settingsBox.put('theme_preset_id', preset.id);
    await _settingsBox.put('theme_accent', accent.toARGB32());
    AppState._triggerRebuild();
  }

  List<String> suggestTitles(String query, {int limit = 8}) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final seen = <String>{};
    final results = <String>[];
    for (final tx in transactions) {
      final title = tx.title.trim();
      if (title.toLowerCase().contains(q) && seen.add(title)) {
        results.add(title);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  InstallmentPlan? installmentById(String? id) {
    if (id == null) return null;
    for (final plan in installmentPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<Transaction> installmentPayments(String installmentId) {
    final payments =
        transactions
            .where(
              (tx) =>
                  tx.type == TransactionType.expense &&
                  tx.installmentPlanId == installmentId,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return payments;
  }

  double installmentPaidAmount(String installmentId) => installmentPayments(
    installmentId,
  ).fold(0.0, (sum, tx) => sum + tx.amount);

  double installmentRemaining(String installmentId) {
    final plan = installmentById(installmentId);
    if (plan == null) return 0;
    final remaining = plan.totalAmount - installmentPaidAmount(installmentId);
    return remaining < 0 ? 0 : remaining;
  }

  double installmentProgress(String installmentId) {
    final plan = installmentById(installmentId);
    if (plan == null || plan.totalAmount <= 0) return 0;
    return (installmentPaidAmount(installmentId) / plan.totalAmount).clamp(
      0.0,
      1.0,
    );
  }

  bool installmentIsPaidOff(String installmentId) =>
      installmentRemaining(installmentId) <= 0;

  List<InstallmentPlan> get activeInstallmentPlans {
    final plans =
        installmentPlans
            .where((plan) => installmentRemaining(plan.id) > 0)
            .toList()
          ..sort(
            (a, b) => installmentRemaining(
              b.id,
            ).compareTo(installmentRemaining(a.id)),
          );
    return plans;
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalInstallmentOutstanding => activeInstallmentPlans.fold(
    0.0,
    (sum, plan) => sum + installmentRemaining(plan.id),
  );

  double get balance => totalIncome - totalExpense;

  String categoryLabel(Transaction tx) => tx.customCategoryId != null
      ? (customCategories
                .where((c) => c.id == tx.customCategoryId)
                .firstOrNull
                ?.name ??
            CategoryMeta.label(tx.category))
      : CategoryMeta.label(tx.category);

  IconData categoryIcon(Transaction tx) => tx.customCategoryId != null
      ? (customCategories
                .where((c) => c.id == tx.customCategoryId)
                .firstOrNull
                ?.icon ??
            CategoryMeta.icon(tx.category))
      : CategoryMeta.icon(tx.category);

  Color categoryColor(Transaction tx) => tx.customCategoryId != null
      ? (customCategories
                .where((c) => c.id == tx.customCategoryId)
                .firstOrNull
                ?.color ??
            CategoryMeta.color(tx.category))
      : CategoryMeta.color(tx.category);
}
