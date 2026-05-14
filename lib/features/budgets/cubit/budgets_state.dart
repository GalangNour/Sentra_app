import 'package:equatable/equatable.dart';
import 'package:sentra_app/core/models/budget_item.dart';

class BudgetsState extends Equatable {
  const BudgetsState({required this.budgets});

  final List<BudgetItem> budgets;

  BudgetsState copyWith({List<BudgetItem>? budgets}) {
    return BudgetsState(budgets: budgets ?? this.budgets);
  }

  @override
  List<Object?> get props => [budgets];
}
