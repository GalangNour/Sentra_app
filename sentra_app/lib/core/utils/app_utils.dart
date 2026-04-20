import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────
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

// ─── Transaction Model ────────────────────────────────────
class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;
  final bool fromScan;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.fromScan = false,
  });

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      fromScan: fromScan,
    );
  }
}

// ─── Budget Model ─────────────────────────────────────────
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

// ─── Category Metadata ────────────────────────────────────
class CategoryMeta {
  static const Map<TransactionCategory, _CatData> _data = {
    TransactionCategory.food: _CatData('Makanan', Icons.restaurant_rounded, Color(0xFFFF8C42)),
    TransactionCategory.transport: _CatData('Transport', Icons.directions_car_rounded, Color(0xFF38BDF8)),
    TransactionCategory.shopping: _CatData('Belanja', Icons.shopping_bag_rounded, Color(0xFFB06EF7)),
    TransactionCategory.entertainment: _CatData('Hiburan', Icons.movie_rounded, Color(0xFFFF6B9D)),
    TransactionCategory.health: _CatData('Kesehatan', Icons.favorite_rounded, Color(0xFFFF6B6B)),
    TransactionCategory.bills: _CatData('Tagihan', Icons.receipt_rounded, Color(0xFFFFB547)),
    TransactionCategory.salary: _CatData('Gaji', Icons.account_balance_wallet_rounded, Color(0xFF00C896)),
    TransactionCategory.investment: _CatData('Investasi', Icons.trending_up_rounded, Color(0xFF6C63FF)),
    TransactionCategory.other: _CatData('Lainnya', Icons.more_horiz_rounded, Color(0xFF8892B0)),
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

// ─── Mock Data ────────────────────────────────────────────
class AppData {
  // Mutable list - simulates a local store
  static final List<Transaction> transactions = [
    Transaction(
      id: '1', title: 'Gaji April', amount: 8500000,
      type: TransactionType.income, category: TransactionCategory.salary,
      date: DateTime(2026, 4, 1), note: 'Gaji bulan April',
    ),
    Transaction(
      id: '2', title: 'Makan Siang Warteg', amount: 25000,
      type: TransactionType.expense, category: TransactionCategory.food,
      date: DateTime(2026, 4, 20, 12, 30),
    ),
    Transaction(
      id: '3', title: 'Grab ke Kantor', amount: 35000,
      type: TransactionType.expense, category: TransactionCategory.transport,
      date: DateTime(2026, 4, 20, 8, 15),
    ),
    Transaction(
      id: '4', title: 'Shopee Belanja', amount: 320000,
      type: TransactionType.expense, category: TransactionCategory.shopping,
      date: DateTime(2026, 4, 19, 20, 0), fromScan: true,
    ),
    Transaction(
      id: '5', title: 'Netflix', amount: 54000,
      type: TransactionType.expense, category: TransactionCategory.entertainment,
      date: DateTime(2026, 4, 18),
    ),
    Transaction(
      id: '6', title: 'PLN Listrik', amount: 210000,
      type: TransactionType.expense, category: TransactionCategory.bills,
      date: DateTime(2026, 4, 15),
    ),
    Transaction(
      id: '7', title: 'Freelance Design', amount: 1500000,
      type: TransactionType.income, category: TransactionCategory.other,
      date: DateTime(2026, 4, 14),
    ),
    Transaction(
      id: '8', title: 'Klinik Dokter', amount: 150000,
      type: TransactionType.expense, category: TransactionCategory.health,
      date: DateTime(2026, 4, 13),
    ),
    Transaction(
      id: '9', title: 'Investasi Reksadana', amount: 500000,
      type: TransactionType.expense, category: TransactionCategory.investment,
      date: DateTime(2026, 4, 10),
    ),
    Transaction(
      id: '10', title: 'Makan Malam Pizza', amount: 85000,
      type: TransactionType.expense, category: TransactionCategory.food,
      date: DateTime(2026, 4, 9, 19, 0),
    ),
  ];

  static final List<BudgetItem> budgets = [
    const BudgetItem(category: TransactionCategory.food, limit: 600000, spent: 385000),
    const BudgetItem(category: TransactionCategory.transport, limit: 400000, spent: 210000),
    const BudgetItem(category: TransactionCategory.shopping, limit: 500000, spent: 320000),
    const BudgetItem(category: TransactionCategory.entertainment, limit: 200000, spent: 54000),
    const BudgetItem(category: TransactionCategory.bills, limit: 300000, spent: 210000),
  ];

  static double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  static double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  static double get balance => totalIncome - totalExpense;

  static void addTransaction(Transaction t) {
    transactions.insert(0, t);
  }
}

// ─── Formatters ───────────────────────────────────────────
class Fmt {
  static String currency(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return 'Rp ${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return 'Rp ${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}rb';
    }
    return 'Rp ${amount.toInt()}';
  }

  static String currencyFull(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer('Rp ');
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static String date(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
