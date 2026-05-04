class InstallmentPlan {
  final String id;
  final String name;
  final double totalAmount;
  final DateTime createdAt;
  final String? note;

  const InstallmentPlan({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'totalAmount': totalAmount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory InstallmentPlan.fromMap(Map<String, dynamic> m) => InstallmentPlan(
    id: m['id'] as String,
    name: m['name'] as String,
    totalAmount: (m['totalAmount'] as num).toDouble(),
    createdAt: DateTime.parse(m['createdAt'] as String),
    note: m['note'] as String?,
  );

  InstallmentPlan copyWith({
    String? name,
    double? totalAmount,
    String? note,
  }) => InstallmentPlan(
    id: id,
    name: name ?? this.name,
    totalAmount: totalAmount ?? this.totalAmount,
    createdAt: createdAt,
    note: note,
  );
}
