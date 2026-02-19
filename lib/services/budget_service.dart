import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _budgetsCollection => _firestore.collection('budgets');

  // Create or update budget
  Future<void> setBudget(Budget budget) async {
    try {
      // Check if budget already exists for this category
      final existing = await _budgetsCollection
          .where('userId', isEqualTo: budget.userId)
          .where('category', isEqualTo: budget.category)
          .where('isActive', isEqualTo: true)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing budget
        await _budgetsCollection.doc(existing.docs.first.id).update({
          'amount': budget.amount,
          'period': budget.period,
        });
        print('Budget updated successfully');
      } else {
        // Create new budget
        final docRef = await _budgetsCollection.add(budget.toMap());
        print('Budget created with ID: ${docRef.id}');
      }
    } catch (e) {
      print('Error setting budget: $e');
      rethrow;
    }
  }

  // Get all active budgets for user
  Stream<List<Budget>> getBudgets(String userId) {
    return _budgetsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          print('Fetched ${snapshot.docs.length} budgets');
          return snapshot.docs
              .map((doc) => Budget.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }

  // Get budget for specific category
  Future<Budget?> getBudgetForCategory(String userId, String category) async {
    try {
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Budget.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting budget for category: $e');
      return null;
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetsCollection.doc(budgetId).update({'isActive': false});
      print('Budget deleted successfully');
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Calculate budget status
  BudgetStatus calculateBudgetStatus(Budget budget, List<Expense> expenses) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (budget.period) {
      case 'weekly':
        // Start of current week (Monday)
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'monthly':
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Filter expenses for the period
    final periodExpenses = expenses.where((e) {
      if (e.date.isBefore(startDate)) return false;
      if (budget.category != 'All' && e.category != budget.category) return false;
      return true;
    }).toList();

    // Calculate total spent
    double spent = 0;
    for (var expense in periodExpenses) {
      spent += expense.amount;
    }

    return BudgetStatus(budget: budget, spent: spent);
  }

  // Get all budget statuses for user
  Future<List<BudgetStatus>> getBudgetStatuses(
    String userId,
    List<Expense> expenses,
  ) async {
    try {
      final budgetsSnapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final budgets = budgetsSnapshot.docs
          .map((doc) => Budget.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return budgets.map((budget) => calculateBudgetStatus(budget, expenses)).toList();
    } catch (e) {
      print('Error getting budget statuses: $e');
      return [];
    }
  }
}