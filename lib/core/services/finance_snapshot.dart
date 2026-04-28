import 'package:flutter/material.dart';
import 'package:sentra_app/core/models/currency_info.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/installment_plan.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/services/finance_insights_service.dart';
import 'package:sentra_app/core/utils/formatters.dart';

class FinanceSnapshot {
  FinanceSnapshot({
    required this.transactions,
    required this.customCategories,
    required this.installmentPlans,
    required this.currency,
  });

  final List<Transaction> transactions;
  final List<CustomCategory> customCategories;
  final List<InstallmentPlan> installmentPlans;
  final CurrencyInfo currency;

  static const FinanceInsightsService _insights = FinanceInsightsService();

  void applyCurrency() {
    Fmt.setCurrency(currency);
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

  double installmentPaidAmount(String installmentId) {
    return _insights.installmentPaidAmount(transactions, installmentId);
  }

  double installmentRemaining(String installmentId) {
    return _insights.installmentRemaining(
      installmentPlans,
      transactions,
      installmentId,
    );
  }

  double installmentProgress(String installmentId) {
    return _insights.installmentProgress(
      installmentPlans,
      transactions,
      installmentId,
    );
  }

  bool installmentIsPaidOff(String installmentId) {
    return installmentRemaining(installmentId) <= 0;
  }

  List<InstallmentPlan> get activeInstallmentPlans {
    return _insights.activeInstallmentPlans(installmentPlans, transactions);
  }

  double get totalIncome => _insights.totalIncome(transactions);

  double get totalExpense => _insights.totalExpense(transactions);

  double get totalInstallmentOutstanding {
    return _insights.totalInstallmentOutstanding(
      installmentPlans,
      transactions,
    );
  }

  double get balance => totalIncome - totalExpense;

  String categoryLabel(Transaction tx) {
    return _insights.categoryLabel(tx, customCategories);
  }

  IconData categoryIcon(Transaction tx) {
    return _insights.categoryIcon(tx, customCategories);
  }

  Color categoryColor(Transaction tx) {
    return _insights.categoryColor(tx, customCategories);
  }
}
