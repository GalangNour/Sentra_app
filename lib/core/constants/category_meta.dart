import 'package:flutter/material.dart';
import 'package:sentra_app/core/models/transaction.dart';

class CategoryMeta {
  static const Set<TransactionCategory> _expenseCategories = {
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.shopping,
    TransactionCategory.entertainment,
    TransactionCategory.health,
    TransactionCategory.bills,
    TransactionCategory.other,
  };

  static const Set<TransactionCategory> _incomeCategories = {
    TransactionCategory.salary,
    TransactionCategory.investment,
    TransactionCategory.other,
  };

  static List<TransactionCategory> forType(TransactionType type) {
    return type == TransactionType.expense
        ? _expenseCategories.toList()
        : _incomeCategories.toList();
  }

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
