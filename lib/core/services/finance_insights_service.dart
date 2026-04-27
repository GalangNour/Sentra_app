import 'package:flutter/material.dart';
import 'package:sentra_app/core/constants/category_meta.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/installment_plan.dart';
import 'package:sentra_app/core/models/transaction.dart';

class FinanceInsightsService {
  const FinanceInsightsService();

  List<Transaction> installmentPayments(
    List<Transaction> transactions,
    String installmentId,
  ) {
    return transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.installmentPlanId == installmentId,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double installmentPaidAmount(
    List<Transaction> transactions,
    String installmentId,
  ) {
    return installmentPayments(
      transactions,
      installmentId,
    ).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double installmentRemaining(
    List<InstallmentPlan> plans,
    List<Transaction> transactions,
    String installmentId,
  ) {
    final plan = installmentById(plans, installmentId);
    if (plan == null) return 0;
    final remaining =
        plan.totalAmount - installmentPaidAmount(transactions, installmentId);
    return remaining < 0 ? 0 : remaining;
  }

  double installmentProgress(
    List<InstallmentPlan> plans,
    List<Transaction> transactions,
    String installmentId,
  ) {
    final plan = installmentById(plans, installmentId);
    if (plan == null || plan.totalAmount <= 0) return 0;
    return (installmentPaidAmount(transactions, installmentId) /
            plan.totalAmount)
        .clamp(0.0, 1.0);
  }

  InstallmentPlan? installmentById(List<InstallmentPlan> plans, String? id) {
    if (id == null) return null;
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<InstallmentPlan> activeInstallmentPlans(
    List<InstallmentPlan> plans,
    List<Transaction> transactions,
  ) {
    return plans
        .where((plan) => installmentRemaining(plans, transactions, plan.id) > 0)
        .toList()
      ..sort(
        (a, b) => installmentRemaining(
          plans,
          transactions,
          b.id,
        ).compareTo(installmentRemaining(plans, transactions, a.id)),
      );
  }

  double totalInstallmentOutstanding(
    List<InstallmentPlan> plans,
    List<Transaction> transactions,
  ) {
    return activeInstallmentPlans(plans, transactions).fold(
      0.0,
      (sum, plan) => sum + installmentRemaining(plans, transactions, plan.id),
    );
  }

  double totalIncome(List<Transaction> transactions) => transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double totalExpense(List<Transaction> transactions) => transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  String categoryLabel(Transaction tx, List<CustomCategory> categories) {
    return tx.customCategoryId != null
        ? (categories
                  .where((c) => c.id == tx.customCategoryId)
                  .firstOrNull
                  ?.name ??
              CategoryMeta.label(tx.category))
        : CategoryMeta.label(tx.category);
  }

  IconData categoryIcon(Transaction tx, List<CustomCategory> categories) {
    return tx.customCategoryId != null
        ? (categories
                  .where((c) => c.id == tx.customCategoryId)
                  .firstOrNull
                  ?.icon ??
              CategoryMeta.icon(tx.category))
        : CategoryMeta.icon(tx.category);
  }

  Color categoryColor(Transaction tx, List<CustomCategory> categories) {
    return tx.customCategoryId != null
        ? (categories
                  .where((c) => c.id == tx.customCategoryId)
                  .firstOrNull
                  ?.color ??
              CategoryMeta.color(tx.category))
        : CategoryMeta.color(tx.category);
  }
}
