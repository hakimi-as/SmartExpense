import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id;
  final String userId;
  final String category; // 'All' for total budget, or specific category
  final double amount;
  final String period; // 'monthly', 'weekly', 'yearly'
  final DateTime createdAt;
  final bool isActive;

  Budget({
    this.id,
    required this.userId,
    required this.category,
    required this.amount,
    this.period = 'monthly',
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'amount': amount,
      'period': period,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'All',
      amount: (map['amount'] ?? 0).toDouble(),
      period: map['period'] ?? 'monthly',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    String? period,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class BudgetStatus {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;
  final bool isNearLimit; // > 80%

  BudgetStatus({
    required this.budget,
    required this.spent,
  })  : remaining = budget.amount - spent,
        percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0,
        isOverBudget = spent > budget.amount,
        isNearLimit = spent > budget.amount * 0.8 && spent <= budget.amount;
}