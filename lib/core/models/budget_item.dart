import 'package:sentra_app/core/models/transaction.dart';

class BudgetItem {
  final String id;
  final TransactionCategory? category;
  final String? customCategoryId;
  final double limit;
  final int month;
  final int year;

  const BudgetItem({
    required this.id,
    this.category,
    this.customCategoryId,
    required this.limit,
    required this.month,
    required this.year,
  }) : assert(
         category != null || customCategoryId != null,
         'Either category or customCategoryId must be provided',
       );

  static String makeId({
    TransactionCategory? category,
    String? customCategoryId,
    required int month,
    required int year,
  }) {
    final catKey = customCategoryId ?? category!.name;
    return '${catKey}_${month}_$year';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (category != null) 'category': category!.name,
    if (customCategoryId != null) 'customCategoryId': customCategoryId,
    'limit': limit,
    'month': month,
    'year': year,
  };

  factory BudgetItem.fromMap(Map<String, dynamic> m) {
    final catName = m['category'] as String?;
    return BudgetItem(
      id: m['id'] as String,
      category: catName != null
          ? TransactionCategory.values.firstWhere((e) => e.name == catName)
          : null,
      customCategoryId: m['customCategoryId'] as String?,
      limit: (m['limit'] as num).toDouble(),
      month: m['month'] as int,
      year: m['year'] as int,
    );
  }

  BudgetItem copyWith({double? limit}) {
    return BudgetItem(
      id: id,
      category: category,
      customCategoryId: customCategoryId,
      limit: limit ?? this.limit,
      month: month,
      year: year,
    );
  }
}
