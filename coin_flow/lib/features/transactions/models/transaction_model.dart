import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String? id;
  final double amount;
  final TransactionType type;
  final String category;
  final String? description;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
  });

  // Преобразование из документа Firestore
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
              (e) => e.name == map['type'],
          orElse: () => TransactionType.expense),
      category: map['category'] ?? 'Other',
      description: map['description'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  // Преобразование в Map для сохранения
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.name,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
    };
  }
}