enum TransactionType { income, expense }

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  bills,
  salary,
  investment,
  other,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategoryId;
  final String? installmentPlanId;
  final DateTime date;
  final String? note;
  final bool fromScan;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategoryId,
    this.installmentPlanId,
    required this.date,
    this.note,
    this.fromScan = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.name,
    'category': category.name,
    'customCategoryId': customCategoryId,
    'installmentPlanId': installmentPlanId,
    'date': date.toIso8601String(),
    'note': note,
    'fromScan': fromScan,
  };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id: m['id'] as String,
    title: m['title'] as String,
    amount: (m['amount'] as num).toDouble(),
    type: TransactionType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => TransactionType.expense,
    ),
    category: TransactionCategory.values.firstWhere(
      (e) => e.name == m['category'],
      orElse: () => TransactionCategory.other,
    ),
    customCategoryId: m['customCategoryId'] as String?,
    installmentPlanId: m['installmentPlanId'] as String?,
    date: DateTime.parse(m['date'] as String),
    note: m['note'] as String?,
    fromScan: (m['fromScan'] as bool?) ?? false,
  );
}
