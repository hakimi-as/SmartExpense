import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/category.dart';
import '../services/categorization_service.dart';

class CategorySuggestionWidget extends StatelessWidget {
  final String merchantName;
  final String currentCategory;
  final Function(String) onCategorySelected;

  const CategorySuggestionWidget({
    super.key,
    required this.merchantName,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (merchantName.isEmpty) return const SizedBox.shrink();

    final service = CategorizationService();
    final suggestedCategory = service.categorizeByKeyword(merchantName);

    // Don't show if already selected or if it suggests "Others"
    if (suggestedCategory == currentCategory || suggestedCategory == 'Others') {
      return const SizedBox.shrink();
    }

    final category = ExpenseCategory.getByName(suggestedCategory);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Category',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestedCategory,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => onCategorySelected(suggestedCategory),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}