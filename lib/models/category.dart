import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> categories = [
    ExpenseCategory(
      name: 'Food',
      icon: Icons.restaurant,
      color: Color(0xFFFF7043),
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: Icons.directions_car,
      color: Color(0xFF42A5F5),
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFFAB47BC),
    ),
    ExpenseCategory(
      name: 'Bills',
      icon: Icons.receipt_long,
      color: Color(0xFFFFCA28),
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Color(0xFFEC407A),
    ),
    ExpenseCategory(
      name: 'Health',
      icon: Icons.medical_services,
      color: Color(0xFF26A69A),
    ),
    ExpenseCategory(
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFF5C6BC0),
    ),
    ExpenseCategory(
      name: 'Others',
      icon: Icons.more_horiz,
      color: Color(0xFF78909C),
    ),
  ];

  static ExpenseCategory getByName(String name) {
    return categories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => categories.last,
    );
  }
}