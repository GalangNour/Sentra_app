import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/budget_item.dart';
import 'package:sentra_app/core/repositories/budget_repository.dart';
import 'package:sentra_app/features/budgets/cubit/budgets_state.dart';

class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit(this._repository)
    : super(BudgetsState(budgets: _repository.loadAll()));

  final BudgetRepository _repository;

  Future<void> setBudget(BudgetItem budget) async {
    await _repository.save(budget);
    final updated = [
      ...state.budgets.where((b) => b.id != budget.id),
      budget,
    ];
    emit(state.copyWith(budgets: updated));
  }

  Future<void> deleteBudget(String id) async {
    await _repository.delete(id);
    emit(state.copyWith(
      budgets: state.budgets.where((b) => b.id != id).toList(),
    ));
  }
}
