class InstallmentPlan {
  final String id;
  final String name;
  final double totalAmount;
  final double? monthlyAmount;
  final DateTime createdAt;
  final String? note;

  const InstallmentPlan({
    required this.id,
    required this.name,
    required this.totalAmount,
    this.monthlyAmount,
    required this.createdAt,
    this.note,
  });

  int? get durationMonths =>
      monthlyAmount != null && monthlyAmount! > 0
          ? (totalAmount / monthlyAmount!).ceil()
          : null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'totalAmount': totalAmount,
    'monthlyAmount': monthlyAmount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory InstallmentPlan.fromMap(Map<String, dynamic> m) => InstallmentPlan(
    id: m['id'] as String,
    name: m['name'] as String,
    totalAmount: (m['totalAmount'] as num).toDouble(),
    monthlyAmount: (m['monthlyAmount'] as num?)?.toDouble(),
    createdAt: DateTime.parse(m['createdAt'] as String),
    note: m['note'] as String?,
  );

  InstallmentPlan copyWith({
    String? name,
    double? totalAmount,
    Object? monthlyAmount = _unset,
    String? note,
  }) => InstallmentPlan(
    id: id,
    name: name ?? this.name,
    totalAmount: totalAmount ?? this.totalAmount,
    monthlyAmount: monthlyAmount == _unset
        ? this.monthlyAmount
        : monthlyAmount as double?,
    createdAt: createdAt,
    note: note,
  );
}

const Object _unset = Object();
