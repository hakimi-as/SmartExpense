import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/budget.dart';
import '../models/category.dart';

class BudgetProgressWidget extends StatelessWidget {
  final List<BudgetStatus> budgetStatuses;
  final VoidCallback onTap;

  const BudgetProgressWidget({
    super.key,
    required this.budgetStatuses,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (budgetStatuses.isEmpty) {
      return _buildEmptyBudgetCard(isDark);
    }

    // Get the most critical budget (over budget or highest percentage)
    final criticalBudgets = budgetStatuses.where((s) => s.isOverBudget || s.isNearLimit).toList();
    
    if (criticalBudgets.isEmpty) {
      // All budgets are healthy
      return _buildHealthyCard(isDark);
    }

    return _buildAlertCard(criticalBudgets, isDark);
  }

  Widget _buildEmptyBudgetCard(bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_chart,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a Budget',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Track your spending goals',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthyCard(bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.incomeGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.incomeGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.incomeGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.incomeGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All budgets on track!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.incomeGreen,
                    ),
                  ),
                  Text(
                    '${budgetStatuses.length} active budget${budgetStatuses.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppTheme.incomeGreen.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.incomeGreen.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(List<BudgetStatus> criticalBudgets, bool isDark) {
    final hasOverBudget = criticalBudgets.any((s) => s.isOverBudget);
    final alertColor = hasOverBudget ? AppTheme.expenseRed : AppTheme.accentOrange;
    final mostCritical = criticalBudgets.first;
    final category = mostCritical.budget.category == 'All'
        ? null
        : ExpenseCategory.getByName(mostCritical.budget.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasOverBudget ? Icons.warning : Icons.info_outline,
                    color: alertColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasOverBudget
                            ? '${criticalBudgets.where((s) => s.isOverBudget).length} budget${criticalBudgets.where((s) => s.isOverBudget).length > 1 ? 's' : ''} exceeded'
                            : '${criticalBudgets.length} budget${criticalBudgets.length > 1 ? 's' : ''} near limit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: alertColor,
                        ),
                      ),
                      Text(
                        '${mostCritical.budget.category}: ${mostCritical.percentage.toStringAsFixed(0)}% used',
                        style: TextStyle(
                          color: alertColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: alertColor.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mini progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (mostCritical.percentage / 100).clamp(0.0, 1.0),
                backgroundColor: alertColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}