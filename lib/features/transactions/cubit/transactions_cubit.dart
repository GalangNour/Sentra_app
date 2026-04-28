import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/repositories/transaction_repository.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit(this._repository)
    : super(TransactionsState(transactions: _repository.loadAll()));

  final TransactionRepository _repository;

  Future<void> addTransaction(Transaction tx) async {
    await _repository.save(tx);
    final transactions = [...state.transactions, tx]
      ..sort((a, b) => b.date.compareTo(a.date));
    emit(state.copyWith(transactions: transactions));
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _repository.save(tx);
    final transactions =
        state.transactions.map((item) => item.id == tx.id ? tx : item).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    emit(state.copyWith(transactions: transactions));
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.delete(id);
    emit(
      state.copyWith(
        transactions: state.transactions
            .where((transaction) => transaction.id != id)
            .toList(),
      ),
    );
  }

  Future<void> clearAllTransactions() async {
    await _repository.clear();
    emit(state.copyWith(transactions: const []));
  }
}
