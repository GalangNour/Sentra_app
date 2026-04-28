import 'package:equatable/equatable.dart';
import 'package:sentra_app/core/models/custom_category.dart';

class CategoriesState extends Equatable {
  const CategoriesState({required this.customCategories});

  final List<CustomCategory> customCategories;

  CategoriesState copyWith({List<CustomCategory>? customCategories}) {
    return CategoriesState(
      customCategories: customCategories ?? this.customCategories,
    );
  }

  @override
  List<Object?> get props => [customCategories];
}
