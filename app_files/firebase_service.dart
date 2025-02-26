import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String getCurrentUserId() {
    User? user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    }
    return ''; // Or handle the case where the user is not logged in
  }

  // Add a new expense to Firestore
  Future<void> addExpense(Expense expense) async {
    try {
      final docRef = _db.collection('expenses').doc();
      expense.id = docRef.id;
      expense.userId = getCurrentUserId();
      await docRef.set(expense.toMap());
    } catch (e) {
      print('Error adding expense: $e');
      throw e; // Re-throw to handle in the UI.
    }
  }

  // Stream of expenses for the current user
  Stream<List<Expense>> getExpenses() {
    String userId = getCurrentUserId();
    return _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _db.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      print('Error deleting expense: $e');
      throw e;
    }
  }

  // Edit an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await _db.collection('expenses').doc(expense.id).update(expense.toMap());
    } catch (e) {
      print('Error updating expense: $e');
      throw e;
    }
  }
}