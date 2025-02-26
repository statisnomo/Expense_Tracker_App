import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  String id;
  double amount;
  String category;
  DateTime date;
  String description;
  String userId;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.userId,
  });

  // Convert Expense object to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': date,
      'description': description,
      'userId': userId,
    };
  }

  // Create Expense object from a Map (retrieved from Firestore)
  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: (map['date'] as Timestamp).toDate(), //Firestore saves DateTime as timestamp
      description: map['description'] as String,
      userId: map['userId'] as String,
    );
  }
}