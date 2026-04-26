import 'package:flutter/material.dart';

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

class BudgetItem {
  final TransactionCategory category;
  final double limit;
  final double spent;

  const BudgetItem({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get percentage => (spent / limit).clamp(0.0, 1.0);
  bool get isOver => spent > limit;
}

class CategoryMeta {
  static const Map<TransactionCategory, _CatData> _data = {
    TransactionCategory.food: _CatData(
      'Makanan',
      Icons.restaurant_rounded,
      Color(0xFFFF8C42),
    ),
    TransactionCategory.transport: _CatData(
      'Transport',
      Icons.directions_car_rounded,
      Color(0xFF38BDF8),
    ),
    TransactionCategory.shopping: _CatData(
      'Belanja',
      Icons.shopping_bag_rounded,
      Color(0xFFB06EF7),
    ),
    TransactionCategory.entertainment: _CatData(
      'Hiburan',
      Icons.movie_rounded,
      Color(0xFFFF6B9D),
    ),
    TransactionCategory.health: _CatData(
      'Kesehatan',
      Icons.favorite_rounded,
      Color(0xFFFF6B6B),
    ),
    TransactionCategory.bills: _CatData(
      'Tagihan',
      Icons.receipt_rounded,
      Color(0xFFFFB547),
    ),
    TransactionCategory.salary: _CatData(
      'Gaji',
      Icons.account_balance_wallet_rounded,
      Color(0xFF00C896),
    ),
    TransactionCategory.investment: _CatData(
      'Investasi',
      Icons.trending_up_rounded,
      Color(0xFF6C63FF),
    ),
    TransactionCategory.other: _CatData(
      'Lainnya',
      Icons.more_horiz_rounded,
      Color(0xFF8892B0),
    ),
  };

  static String label(TransactionCategory c) => _data[c]!.label;
  static IconData icon(TransactionCategory c) => _data[c]!.icon;
  static Color color(TransactionCategory c) => _data[c]!.color;
}

class _CatData {
  final String label;
  final IconData icon;
  final Color color;

  const _CatData(this.label, this.icon, this.color);
}

class Fmt {
  static String _symbol = 'Rp';
  static bool _before = true;

  static void setCurrency(dynamic c) {
    _symbol = c.symbol as String;
    _before = c.symbolBefore as bool;
  }

  static String compact(double amount) {
    String num;
    if (amount >= 1000000) {
      final m = amount / 1000000;
      num = '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      num = '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}rb';
    } else {
      num = amount.toInt().toString();
    }
    return _before ? '$_symbol $num' : '$num $_symbol';
  }

  static String full(double amount) {
    final str = amount.toInt().toString();
    final chars = <String>[];
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) chars.add('.');
      chars.add(str[i]);
      count++;
    }
    final number = chars.reversed.join();
    return _before ? '$_symbol $number' : '$number $_symbol';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return date(dt);
  }

  static String date(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
