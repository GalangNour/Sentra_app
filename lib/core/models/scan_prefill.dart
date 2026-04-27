import 'package:sentra_app/core/models/transaction.dart';

class ScanPrefill {
  final String merchant;
  final double total;
  final TransactionCategory category;
  final TransactionType type;
  final String? imagePath;
  final String? rawText;
  final String source;
  final String? warning;
  final List<double> candidateAmounts;

  const ScanPrefill({
    required this.merchant,
    required this.total,
    required this.category,
    this.type = TransactionType.expense,
    this.imagePath,
    this.rawText,
    this.source = 'mlkit',
    this.warning,
    this.candidateAmounts = const [],
  });
}
