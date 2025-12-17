import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transactions_repository.dart';
import '../models/transaction_model.dart';

final transactionsControllerProvider = StateNotifierProvider<TransactionsController, AsyncValue<void>>((ref) {
  return TransactionsController(ref.watch(transactionsRepositoryProvider));
});

class TransactionsController extends StateNotifier<AsyncValue<void>> {
  final TransactionsRepository _repository;

  TransactionsController(this._repository) : super(const AsyncValue.data(null));

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addTransaction(
      TransactionModel(
        amount: amount,
        type: type,
        category: category,
        date: date,
        description: description,
      ),
    ));
  }

  Future<void> deleteTransaction(String id) async {
    // Можно добавить состояние загрузки, но для удаления часто это не обязательно
    await _repository.deleteTransaction(id);
  }
}