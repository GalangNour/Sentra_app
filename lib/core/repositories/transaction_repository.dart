import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/transaction.dart';

class TransactionRepository {
  final Box _box;

  const TransactionRepository(this._box);

  List<Transaction> loadAll() {
    return _box.values
        .map(
          (value) =>
              Transaction.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> save(Transaction transaction) async {
    await _box.put(transaction.id, transaction.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
