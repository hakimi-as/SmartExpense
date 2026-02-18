import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _expensesCollection =>
      _firestore.collection('expenses');

  // Add new expense
  Future<String> addExpense(Expense expense) async {
    try {
      final docRef = await _expensesCollection.add(expense.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to add expense: $e';
    }
  }

  // Get all expenses for a user (as stream)
  Stream<List<Expense>> getExpenses(String userId) {
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get expenses for a specific month
  Stream<List<Expense>> getExpensesByMonth(String userId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) throw 'Expense ID is required';
      await _expensesCollection.doc(expense.id).update(expense.toMap());
    } catch (e) {
      throw 'Failed to update expense: $e';
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesCollection.doc(expenseId).delete();
    } catch (e) {
      throw 'Failed to delete expense: $e';
    }
  }

  // Get total spending for a month
  Future<double> getMonthlyTotal(String userId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
    }
    return total;
  }
  // Get expenses by date range
Stream<List<Expense>> getExpensesByDateRange(
  String userId,
  DateTime startDate,
  DateTime endDate,
) {
  return _firestore
      .collection('expenses')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      ))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data()))
          .toList());
}
}