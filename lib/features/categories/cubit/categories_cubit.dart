import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/custom_category.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/repositories/custom_category_repository.dart';
import 'package:sentra_app/features/categories/cubit/categories_state.dart';
import 'package:uuid/uuid.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository)
    : super(CategoriesState(customCategories: _repository.loadAll()));

  final CustomCategoryRepository _repository;
  static const Uuid _uuid = Uuid();

  Future<CustomCategory> addCustomCategory({
    required String name,
    required IconData icon,
    required Color color,
    required TransactionType type,
  }) async {
    final category = CustomCategory(
      id: _uuid.v4(),
      name: name,
      iconCode: icon.codePoint,
      fontFamily: icon.fontFamily ?? 'MaterialIcons',
      colorValue: color.toARGB32(),
      type: type,
    );
    await _repository.save(category);
    emit(
      state.copyWith(customCategories: [...state.customCategories, category]),
    );
    return category;
  }

  Future<void> updateCustomCategory({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
    required TransactionType type,
  }) async {
    final updated = CustomCategory(
      id: id,
      name: name,
      iconCode: icon.codePoint,
      fontFamily: icon.fontFamily ?? 'MaterialIcons',
      colorValue: color.toARGB32(),
      type: type,
    );
    await _repository.save(updated);
    emit(
      state.copyWith(
        customCategories: state.customCategories
            .map((c) => c.id == id ? updated : c)
            .toList(),
      ),
    );
  }

  Future<void> deleteCustomCategory(String id) async {
    await _repository.delete(id);
    emit(
      state.copyWith(
        customCategories: state.customCategories
            .where((category) => category.id != id)
            .toList(),
      ),
    );
  }
}
