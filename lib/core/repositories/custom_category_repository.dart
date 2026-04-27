import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/custom_category.dart';

class CustomCategoryRepository {
  final Box _box;

  const CustomCategoryRepository(this._box);

  List<CustomCategory> loadAll() {
    return _box.values
        .map(
          (value) =>
              CustomCategory.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }

  Future<void> save(CustomCategory category) async {
    await _box.put(category.id, category.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
