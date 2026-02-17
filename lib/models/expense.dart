import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;
  final String currency; // Add currency field

  Expense({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.createdAt,
    this.currency = 'MYR', // Default to MYR
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'currency': currency,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Others',
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      currency: map['currency'] ?? 'MYR',
    );
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
    );
  }
}