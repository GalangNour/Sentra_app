import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/installment_plan.dart';

class InstallmentPlanRepository {
  final Box _box;

  const InstallmentPlanRepository(this._box);

  List<InstallmentPlan> loadAll() {
    return _box.values
        .map(
          (value) =>
              InstallmentPlan.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(InstallmentPlan plan) async {
    await _box.put(plan.id, plan.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
