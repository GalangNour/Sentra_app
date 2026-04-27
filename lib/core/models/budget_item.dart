import 'package:sentra_app/core/models/transaction.dart';

class BudgetItem {
  final TransactionCategory category;
  final double limit;
  final double spent;

  const BudgetItem({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get percentage => (spent / limit).clamp(0.0, 1.0);
  bool get isOver => spent > limit;
}
