import 'dart:io'; // For Platform.isAndroid/isIOS
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker_app/models/expense.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to get or generate the device ID
  Future<String?> getOrGenerateDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = await getDeviceId();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  // Function to get the device ID
  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor!; // Vendor ID
    } else {
      return 'unknown_device';
    }
  }

  // Add a new expense to Firestore
  Future<void> addExpense(Expense expense) async {
    try {
      final docRef = _db.collection('expenses').doc();
      expense.id = docRef.id;
      expense.userId = await getOrGenerateDeviceId() ?? "No deviceId";
      await docRef.set(expense.toMap());
    } catch (e) {
      print('Error adding expense: $e');
      throw e; // Re-throw to handle in the UI.
    }
  }

  // Stream of expenses for the current device
  Stream<List<Expense>> getExpenses() async* {
    String deviceId = await getOrGenerateDeviceId() ?? "No deviceId";
    yield* _db
        .collection('expenses')
        .where('userId', isEqualTo: deviceId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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