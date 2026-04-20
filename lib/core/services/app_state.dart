import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

// ─── Currency ─────────────────────────────────────────────

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
  static const eur = CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro');
  static const gbp = CurrencyInfo(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
  );
  static const jpy = CurrencyInfo(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
  );
  static const aud = CurrencyInfo(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
  );
  static const cny = CurrencyInfo(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
  );
  static const krw = CurrencyInfo(code: 'KRW', symbol: '₩', name: 'Korean Won');
  static const thb = CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht');
  static const php = CurrencyInfo(
    code: 'PHP',
    symbol: '₱',
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

// ─── Custom Category ──────────────────────────────────────

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

// ─── AppState singleton ───────────────────────────────────

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  late Box _txBox;
  late Box _catBox;
  late Box _settingsBox;

  List<Transaction> transactions = [];
  List<CustomCategory> customCategories = [];
  CurrencyInfo currency = CurrencyInfo.idr;

  static const _uuid = Uuid();

  Future<void> init() async {
    await Hive.initFlutter();
    _txBox = await Hive.openBox('transactions');
    _catBox = await Hive.openBox('customCategories');
    _settingsBox = await Hive.openBox('settings');

    _loadTransactions();
    _loadCustomCategories();
    _loadSettings();
  }

  void _loadTransactions() {
    transactions = _txBox.values
        .map((v) => Transaction.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  void _loadCustomCategories() {
    customCategories = _catBox.values
        .map((v) => CustomCategory.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  void _loadSettings() {
    final code =
        _settingsBox.get('currency_code', defaultValue: 'IDR') as String;
    currency = CurrencyInfo.fromCode(code);
    Fmt.setCurrency(currency);
  }

  // ── Transactions ─────────────────────────────────────────

  Future<void> addTransaction(Transaction tx) async {
    await _txBox.put(tx.id, tx.toMap());
    transactions.insert(0, tx);
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

  // ── Custom Categories ────────────────────────────────────

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

  // ── Currency ─────────────────────────────────────────────

  Future<void> setCurrency(CurrencyInfo c) async {
    currency = c;
    Fmt.setCurrency(c);
    await _settingsBox.put('currency_code', c.code);
  }

  // ── Computed helpers ─────────────────────────────────────

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amount);
  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amount);
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
