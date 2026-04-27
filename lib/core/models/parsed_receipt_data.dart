import 'package:sentra_app/core/models/transaction.dart';

class ParsedReceiptData {
  final String merchant;
  final double total;
  final DateTime date;
  final TransactionCategory category;
  final String? imagePath;
  final String? rawText;
  final String source;
  final String? warning;
  final List<double> candidateAmounts;

  const ParsedReceiptData({
    required this.merchant,
    required this.total,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawText,
    this.source = 'mlkit',
    this.warning,
    this.candidateAmounts = const [],
  });
}
