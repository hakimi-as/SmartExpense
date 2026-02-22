import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/currency_service.dart';
import '../../services/haptic_service.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/all_expenses_screen.dart';
import '../export/export_screen.dart';
import '../expenses/scan_receipt_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../models/budget.dart';
import '../../services/budget_service.dart';
import '../../widgets/budget_progress_widget.dart';
import '../budget/budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _currencyService = CurrencyService();
  final _budgetService = BudgetService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _preferredCurrency = 'MYR';
  Map<String, double> _exchangeRates = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    final currency = await _currencyService.getPreferredCurrency();
    final rates = await _currencyService.getExchangeRates('MYR');
    if (mounted) {
      setState(() {
        _preferredCurrency = currency;
        _exchangeRates = rates;
      });
    }
  }

  Future<void> _onRefresh() async {
    HapticService.mediumTap();
    setState(() => _isRefreshing = true);
    
    await _loadCurrencyData();
    
    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      HapticService.success();
    }
  }

  double _convertAmount(double amount, String fromCurrency) {
    if (fromCurrency == _preferredCurrency) return amount;

    final toMyrRate = _exchangeRates[fromCurrency] ?? 1.0;
    final fromMyrRate = _exchangeRates[_preferredCurrency] ?? 1.0;

    if (fromCurrency == 'MYR') {
      return amount * fromMyrRate;
    } else {
      final amountInMyr = amount / toMyrRate;
      return amountInMyr * fromMyrRate;
    }
  }

  String _formatWithCommas(double value) {
    int decimals = (_preferredCurrency == 'JPY' || _preferredCurrency == 'IDR') ? 0 : 2;

    String result = value.toStringAsFixed(decimals);
    List<String> parts = result.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = ',$formatted';
      }
      formatted = integerPart[i] + formatted;
      count++;
    }

    return '$formatted$decimalPart';
  }

  String _formatWithCommasForCurrency(double value, String currencyCode) {
    int decimals = (currencyCode == 'JPY' || currencyCode == 'IDR') ? 0 : 2;

    String result = value.toStringAsFixed(decimals);
    List<String> parts = result.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = ',$formatted';
      }
      formatted = integerPart[i] + formatted;
      count++;
    }

    return '$formatted$decimalPart';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'User';
    final currency = CurrencyService.getCurrency(_preferredCurrency);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryColor,
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            displacement: 60,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Beautiful Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      firstName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildHeaderButton(
                                      icon: Icons.search,
                                      onTap: () {
                                        HapticService.lightTap();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AllExpensesScreen()),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Balance Card
                            StreamBuilder<List<Expense>>(
                              stream: _databaseService.getExpensesByMonth(
                                user!.uid,
                                DateTime.now(),
                              ),
                              builder: (context, snapshot) {
                                double totalSpending = 0;
                                if (snapshot.hasData) {
                                  for (var expense in snapshot.data!) {
                                    totalSpending += _convertAmount(
                                      expense.amount,
                                      expense.currency,
                                    );
                                  }
                                }

                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    key: ValueKey(totalSpending),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Spending',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 14,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                DateFormat('MMMM').format(DateTime.now()),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currency.symbol,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0, end: totalSpending),
                                              duration: const Duration(milliseconds: 800),
                                              curve: Curves.easeOutCubic,
                                              builder: (context, value, child) {
                                                return Text(
                                                  _formatWithCommas(value),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        if (_preferredCurrency != 'MYR') ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '≈ Original amounts converted from multiple currencies',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickAction(
                              icon: Icons.add_circle_outline,
                              label: 'Add',
                              color: AppTheme.primaryColor,
                              gradient: AppTheme.primaryGradient,
                              onTap: () {
                                HapticService.mediumTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                              icon: Icons.camera_alt_outlined,
                              label: 'Scan',
                              color: AppTheme.accentOrange,
                              gradient: AppTheme.orangeGradient,
                              onTap: () {
                                HapticService.mediumTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Budget',
                              color: AppTheme.accentPurple,
                              gradient: AppTheme.purpleGradient,
                              onTap: () {
                                HapticService.mediumTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BudgetScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                              icon: Icons.pie_chart_outline,
                              label: 'Stats',
                              color: AppTheme.accentBlue,
                              gradient: AppTheme.blueGradient,
                              onTap: () {
                                HapticService.mediumTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Budget Progress Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticService.lightTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BudgetScreen()),
                                );
                              },
                              child: const Text('Manage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<Budget>>(
                          stream: _budgetService.getBudgets(user.uid),
                          builder: (context, budgetSnapshot) {
                            return StreamBuilder<List<Expense>>(
                              stream: _databaseService.getExpensesByMonth(user.uid, DateTime.now()),
                              builder: (context, expenseSnapshot) {
                                final budgets = budgetSnapshot.data ?? [];
                                final expenses = expenseSnapshot.data ?? [];
                                
                                final statuses = budgets
                                    .map((b) => _budgetService.calculateBudgetStatus(b, expenses))
                                    .toList();
                                
                                // Sort by percentage descending
                                statuses.sort((a, b) => b.percentage.compareTo(a.percentage));
                                
                                return BudgetProgressWidget(
                                  budgetStatuses: statuses,
                                  onTap: () {
                                    HapticService.lightTap();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Recent Transactions Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticService.lightTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AllExpensesScreen()),
                            );
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expense List
StreamBuilder<List<Expense>>(
  stream: _databaseService.getExpenses(user.uid),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    final expenses = snapshot.data ?? [];

    if (expenses.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'No expenses yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first expense',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final expense = expenses[index];
            final category = ExpenseCategory.getByName(expense.category);
            final convertedAmount = _convertAmount(
              expense.amount,
              expense.currency,
            );

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExpenseCard(
                        expense: expense,
                        category: category,
                        convertedAmount: convertedAmount,
                        currency: currency,
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          childCount: expenses.length > 10 ? 10 : expenses.length,
        ),
      ),
    );
  },
),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard({
    required Expense expense,
    required ExpenseCategory category,
    required double convertedAmount,
    required Currency currency,
    required bool isDark,
  }) {
    final showOriginal = expense.currency != _preferredCurrency;
    final originalCurrency = CurrencyService.getCurrency(expense.currency);

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(expense: expense),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'expense_icon_${expense.id}',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.category,
                          style: TextStyle(
                            color: category.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d').format(expense.date),
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${currency.symbol}${_formatWithCommas(convertedAmount)}',
                  style: const TextStyle(
                    color: AppTheme.expenseRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (showOriginal) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${originalCurrency.symbol}${_formatWithCommasForCurrency(expense.amount, expense.currency)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}