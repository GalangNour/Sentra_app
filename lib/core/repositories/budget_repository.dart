import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/budget_item.dart';

class BudgetRepository {
  const BudgetRepository(this._box);

  final Box _box;

  List<BudgetItem> loadAll() {
    return _box.values
        .map((v) => BudgetItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> save(BudgetItem budget) async {
    await _box.put(budget.id, budget.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
