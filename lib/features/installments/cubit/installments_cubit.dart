import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/installment_plan.dart';
import 'package:sentra_app/core/repositories/installment_plan_repository.dart';
import 'package:sentra_app/features/installments/cubit/installments_state.dart';
import 'package:uuid/uuid.dart';

class InstallmentsCubit extends Cubit<InstallmentsState> {
  InstallmentsCubit(this._repository)
    : super(InstallmentsState(installmentPlans: _repository.loadAll()));

  final InstallmentPlanRepository _repository;
  static const Uuid _uuid = Uuid();

  Future<InstallmentPlan> addInstallmentPlan({
    required String name,
    required double totalAmount,
    double? monthlyAmount,
    String? note,
  }) async {
    final plan = InstallmentPlan(
      id: _uuid.v4(),
      name: name,
      totalAmount: totalAmount,
      monthlyAmount: monthlyAmount,
      createdAt: DateTime.now(),
      note: note,
    );

    await _repository.save(plan);
    final plans = [...state.installmentPlans, plan]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(state.copyWith(installmentPlans: plans));
    return plan;
  }

  Future<void> editInstallmentPlan({
    required String id,
    required String name,
    required double totalAmount,
    double? monthlyAmount,
    String? note,
  }) async {
    final existing = state.installmentPlans.firstWhere((p) => p.id == id);
    final updated = existing.copyWith(
      name: name,
      totalAmount: totalAmount,
      monthlyAmount: monthlyAmount,
      note: note,
    );
    await _repository.save(updated);
    final plans = state.installmentPlans
        .map((p) => p.id == id ? updated : p)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(state.copyWith(installmentPlans: plans));
  }

  Future<void> deleteInstallmentPlan(String id) async {
    await _repository.delete(id);
    emit(
      state.copyWith(
        installmentPlans: state.installmentPlans
            .where((plan) => plan.id != id)
            .toList(),
      ),
    );
  }
}
