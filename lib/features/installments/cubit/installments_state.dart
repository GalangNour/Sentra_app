import 'package:equatable/equatable.dart';
import 'package:sentra_app/core/models/installment_plan.dart';

class InstallmentsState extends Equatable {
  const InstallmentsState({required this.installmentPlans});

  final List<InstallmentPlan> installmentPlans;

  InstallmentsState copyWith({List<InstallmentPlan>? installmentPlans}) {
    return InstallmentsState(
      installmentPlans: installmentPlans ?? this.installmentPlans,
    );
  }

  @override
  List<Object?> get props => [installmentPlans];
}
