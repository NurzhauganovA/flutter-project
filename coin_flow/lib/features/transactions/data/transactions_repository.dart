import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

// Провайдер репозитория
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// Провайдер потока транзакций (слушает изменения в реальном времени)
final transactionsStreamProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  return ref.watch(transactionsRepositoryProvider).getTransactions();
});

class TransactionsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionsRepository(this._firestore, this._auth);

  // Получаем коллекцию текущего пользователя
  CollectionReference get _transactionsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  // Получить список (Stream)
  Stream<List<TransactionModel>> getTransactions() {
    return _transactionsRef
        .orderBy('date', descending: true) // Сортировка по дате (сначала новые)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Добавить
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsRef.add(transaction.toMap());
  }

  // Удалить
  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }
}