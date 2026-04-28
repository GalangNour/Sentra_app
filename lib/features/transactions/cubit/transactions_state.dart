import 'package:equatable/equatable.dart';
import 'package:sentra_app/core/models/transaction.dart';

class TransactionsState extends Equatable {
  const TransactionsState({required this.transactions});

  final List<Transaction> transactions;

  TransactionsState copyWith({List<Transaction>? transactions}) {
    return TransactionsState(transactions: transactions ?? this.transactions);
  }

  @override
  List<Object?> get props => [transactions];
}
