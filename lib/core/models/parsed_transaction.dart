import 'package:sentra_app/core/models/transaction.dart';

class ParsedTransaction {
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategoryId;
  final String? note;
  final DateTime date;
  final String rawInput;
  final String? warning;

  const ParsedTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategoryId,
    this.note,
    required this.date,
    required this.rawInput,
    this.warning,
  });
}
