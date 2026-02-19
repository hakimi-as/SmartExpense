import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/budget.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _authService = AuthService();
  final _budgetService = BudgetService();
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: isDark ? AppTheme.darkSurface : null,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddBudgetSheet(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<Budget>>(
        stream: _budgetService.getBudgets(user!.uid),
        builder: (context, budgetSnapshot) {
          return StreamBuilder<List<Expense>>(
            stream: _databaseService.getExpenses(user.uid),
            builder: (context, expenseSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                  expenseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              final budgets = budgetSnapshot.data ?? [];
              final expenses = expenseSnapshot.data ?? [];

              if (budgets.isEmpty) {
                return _buildEmptyState(isDark);
              }

              // Calculate budget statuses
              final statuses = budgets
                  .map((b) => _budgetService.calculateBudgetStatus(b, expenses))
                  .toList();

              // Sort: over budget first, then by percentage
              statuses.sort((a, b) {
                if (a.isOverBudget && !b.isOverBudget) return -1;
                if (!a.isOverBudget && b.isOverBudget) return 1;
                return b.percentage.compareTo(a.percentage);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    _buildSummaryCard(statuses, isDark),
                    const SizedBox(height: 24),

                    // Budget List
                    Text(
                      'Your Budgets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...statuses.map((status) => _buildBudgetCard(status, isDark)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetSheet(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No budgets set',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set budgets to track your spending\nand stay on top of your finances',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddBudgetSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<BudgetStatus> statuses, bool isDark) {
    final overBudgetCount = statuses.where((s) => s.isOverBudget).length;
    final nearLimitCount = statuses.where((s) => s.isNearLimit).length;
    final healthyCount = statuses.length - overBudgetCount - nearLimitCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: overBudgetCount > 0
            ? const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
              )
            : nearLimitCount > 0
                ? const LinearGradient(
                    colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
                  )
                : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (overBudgetCount > 0
                    ? AppTheme.expenseRed
                    : nearLimitCount > 0
                        ? AppTheme.accentOrange
                        : AppTheme.primaryColor)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                overBudgetCount > 0
                    ? Icons.warning
                    : nearLimitCount > 0
                        ? Icons.info_outline
                        : Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  overBudgetCount > 0
                      ? '$overBudgetCount budget${overBudgetCount > 1 ? 's' : ''} exceeded!'
                      : nearLimitCount > 0
                          ? '$nearLimitCount budget${nearLimitCount > 1 ? 's' : ''} near limit'
                          : 'All budgets on track!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Over', overBudgetCount, Colors.white),
              _buildSummaryItem('Near', nearLimitCount, Colors.white),
              _buildSummaryItem('Healthy', healthyCount, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BudgetStatus status, bool isDark) {
    final category = status.budget.category == 'All'
        ? null
        : ExpenseCategory.getByName(status.budget.category);
    
    final progressColor = status.isOverBudget
        ? AppTheme.expenseRed
        : status.isNearLimit
            ? AppTheme.accentOrange
            : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: status.isOverBudget
            ? Border.all(color: AppTheme.expenseRed.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (category?.color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category?.icon ?? Icons.account_balance_wallet,
                  color: category?.color ?? AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.budget.category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _getPeriodLabel(status.budget.period),
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                color: isDark ? AppTheme.darkCard : Colors.white,
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddBudgetSheet(context, existingBudget: status.budget);
                  } else if (value == 'delete') {
                    _deleteBudget(status.budget);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: AppTheme.expenseRed),
                        const SizedBox(width: 8),
                        const Text('Delete', style: TextStyle(color: AppTheme.expenseRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (status.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Amount Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'RM ${_formatAmount(status.spent)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${status.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'RM ${_formatAmount(status.budget.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Warning Message
          if (status.isOverBudget || status.isNearLimit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    status.isOverBudget ? Icons.warning : Icons.info_outline,
                    color: progressColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.isOverBudget
                          ? 'Over budget by RM ${_formatAmount(status.spent - status.budget.amount)}'
                          : 'RM ${_formatAmount(status.remaining)} remaining',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'weekly':
        return 'Weekly Budget';
      case 'yearly':
        return 'Yearly Budget';
      default:
        return 'Monthly Budget';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(2);
  }

  void _showAddBudgetSheet(BuildContext context, {Budget? existingBudget}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedCategory = existingBudget?.category ?? 'All';
    String selectedPeriod = existingBudget?.period ?? 'monthly';
    final amountController = TextEditingController(
      text: existingBudget?.amount.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  existingBudget != null ? 'Edit Budget' : 'Set Budget',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Category Selection
                Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryChip('All', selectedCategory, isDark, (cat) {
                      setSheetState(() => selectedCategory = cat);
                    }),
                    ...ExpenseCategory.categories.map((cat) => _buildCategoryChip(
                      cat.name,
                      selectedCategory,
                      isDark,
                      (c) => setSheetState(() => selectedCategory = c),
                      color: cat.color,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount Input
                Text(
                  'Budget Amount (RM)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'RM ',
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Period Selection
                Text(
                  'Budget Period',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPeriodChip('Weekly', 'weekly', selectedPeriod, isDark, (p) {
                      setSheetState(() => selectedPeriod = p);
                    }),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Monthly', 'monthly', selectedPeriod, isDark, (p) {
                      setSheetState(() => selectedPeriod = p);
                    }),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Yearly', 'yearly', selectedPeriod, isDark, (p) {
                      setSheetState(() => selectedPeriod = p);
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Button
SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: () async {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: AppTheme.expenseRed,
          ),
        );
        return;
      }

      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: AppTheme.expenseRed,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      try {
        final budget = Budget(
          id: existingBudget?.id,
          userId: user.uid,
          category: selectedCategory,
          amount: amount,
          period: selectedPeriod,
        );

        await _budgetService.setBudget(budget);
        
        if (context.mounted) {
          // Close loading dialog
          Navigator.pop(context);
          // Close bottom sheet
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(existingBudget != null
                      ? 'Budget updated!'
                      : 'Budget created!'),
                ],
              ),
              backgroundColor: AppTheme.incomeGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          // Close loading dialog
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.expenseRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: Text(
      existingBudget != null ? 'Update Budget' : 'Create Budget',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String category,
    String selected,
    bool isDark,
    Function(String) onSelect, {
    Color? color,
  }) {
    final isSelected = category == selected;
    final chipColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: () => onSelect(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    String value,
    String selected,
    bool isDark,
    Function(String) onSelect,
  ) {
    final isSelected = value == selected;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.expenseRed),
            const SizedBox(width: 12),
            Text(
              'Delete Budget',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this budget?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && budget.id != null) {
      await _budgetService.deleteBudget(budget.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Budget deleted'),
            backgroundColor: AppTheme.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}