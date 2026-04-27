import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/repositories/custom_category_repository.dart';
import 'package:sentra_app/core/repositories/installment_plan_repository.dart';
import 'package:sentra_app/core/repositories/settings_repository.dart';
import 'package:sentra_app/core/repositories/transaction_repository.dart';
import 'package:sentra_app/core/services/finance_insights_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:uuid/uuid.dart';

export 'package:sentra_app/core/models/currency_info.dart';
export 'package:sentra_app/core/models/custom_category.dart';

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  late Box _txBox;
  late Box _catBox;
  late Box _installmentBox;
  late Box _settingsBox;
  late TransactionRepository _transactionRepository;
  late CustomCategoryRepository _customCategoryRepository;
  late InstallmentPlanRepository _installmentPlanRepository;
  late SettingsRepository _settingsRepository;
  final FinanceInsightsService _insights = const FinanceInsightsService();

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
    _transactionRepository = TransactionRepository(_txBox);
    _customCategoryRepository = CustomCategoryRepository(_catBox);
    _installmentPlanRepository = InstallmentPlanRepository(_installmentBox);
    _settingsRepository = SettingsRepository(_settingsBox);

    _loadTransactions();
    _loadCustomCategories();
    _loadInstallments();
    _loadSettings();
  }

  void _loadTransactions() {
    transactions = _transactionRepository.loadAll();
  }

  void _loadCustomCategories() {
    customCategories = _customCategoryRepository.loadAll();
  }

  void _loadInstallments() {
    installmentPlans = _installmentPlanRepository.loadAll();
  }

  void _loadSettings() {
    final code = _settingsRepository.getCurrencyCode();
    currency = CurrencyInfo.fromCode(code);
    Fmt.setCurrency(currency);

    final presetId = _settingsRepository.getThemePresetId();
    final accentValue = _settingsRepository.getThemeAccent();
    ThemeConfig.apply(ThemePreset.fromId(presetId), Color(accentValue));
  }

  Future<void> addTransaction(Transaction tx) async {
    await _transactionRepository.save(tx);
    transactions.insert(0, tx);
    transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionRepository.delete(id);
    transactions.removeWhere((t) => t.id == id);
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _transactionRepository.save(tx);
    final idx = transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) transactions[idx] = tx;
    transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> clearAllTransactions() async {
    await _transactionRepository.clear();
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
    await _customCategoryRepository.save(cat);
    customCategories.add(cat);
    return cat;
  }

  Future<void> deleteCustomCategory(String id) async {
    await _customCategoryRepository.delete(id);
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
    await _installmentPlanRepository.save(plan);
    installmentPlans.insert(0, plan);
    installmentPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plan;
  }

  Future<void> deleteInstallmentPlan(String id) async {
    await _installmentPlanRepository.delete(id);
    installmentPlans.removeWhere((p) => p.id == id);
  }

  Future<void> setCurrency(CurrencyInfo c) async {
    currency = c;
    Fmt.setCurrency(c);
    await _settingsRepository.setCurrencyCode(c.code);
  }

  Future<void> setTheme(ThemePreset preset, Color accent) async {
    ThemeConfig.apply(preset, accent);
    await _settingsRepository.saveTheme(
      presetId: preset.id,
      accentValue: accent.toARGB32(),
    );
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
    return _insights.installmentById(installmentPlans, id);
  }

  List<Transaction> installmentPayments(String installmentId) {
    return _insights.installmentPayments(transactions, installmentId);
  }

  double installmentPaidAmount(String installmentId) =>
      _insights.installmentPaidAmount(transactions, installmentId);

  double installmentRemaining(String installmentId) => _insights
      .installmentRemaining(installmentPlans, transactions, installmentId);

  double installmentProgress(String installmentId) => _insights
      .installmentProgress(installmentPlans, transactions, installmentId);

  bool installmentIsPaidOff(String installmentId) =>
      installmentRemaining(installmentId) <= 0;

  List<InstallmentPlan> get activeInstallmentPlans =>
      _insights.activeInstallmentPlans(installmentPlans, transactions);

  double get totalIncome => _insights.totalIncome(transactions);

  double get totalExpense => _insights.totalExpense(transactions);

  double get totalInstallmentOutstanding =>
      _insights.totalInstallmentOutstanding(installmentPlans, transactions);

  double get balance => totalIncome - totalExpense;

  String categoryLabel(Transaction tx) =>
      _insights.categoryLabel(tx, customCategories);

  IconData categoryIcon(Transaction tx) =>
      _insights.categoryIcon(tx, customCategories);

  Color categoryColor(Transaction tx) =>
      _insights.categoryColor(tx, customCategories);
}
