import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/categorization_service.dart';
import '../../services/currency_service.dart';
import '../../widgets/category_suggestion.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final double? scannedAmount;
  final String? scannedMerchant;
  final DateTime? scannedDate;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.scannedAmount,
    this.scannedMerchant,
    this.scannedDate,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _categorizationService = CategorizationService();
  final _currencyService = CurrencyService();

  String _selectedCategory = 'Food';
  String _suggestedCategory = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'MYR';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    if (_isEditing) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _notesController.text = widget.expense!.notes ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _selectedCurrency = widget.expense!.currency;
    } else {
      // Check for scanned data
      if (widget.scannedAmount != null) {
        _amountController.text = widget.scannedAmount!.toStringAsFixed(2);
      }
      if (widget.scannedMerchant != null) {
        _titleController.text = widget.scannedMerchant!;
        _autoCategorize(widget.scannedMerchant!);
      }
      if (widget.scannedDate != null) {
        _selectedDate = widget.scannedDate!;
      }
      
      // Load preferred currency
      _loadPreferredCurrency();
    }

    // Listen to title changes for auto-categorization
    _titleController.addListener(_onTitleChanged);
  }

  Future<void> _loadPreferredCurrency() async {
    final currency = await _currencyService.getPreferredCurrency();
    if (mounted) {
      setState(() => _selectedCurrency = currency);
    }
  }

  void _onTitleChanged() {
    final title = _titleController.text.trim();
    if (title.length >= 3) {
      _autoCategorize(title);
    }
  }

  Future<void> _autoCategorize(String text) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final suggested = await _categorizationService.smartCategorize(userId, text);

    if (mounted && suggested != 'Others') {
      setState(() {
        _suggestedCategory = suggested;
      });
    }
  }

  void _applySuggestion(String category) {
    setState(() {
      _selectedCategory = category;
      _suggestedCategory = '';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const Divider(),
            
            // Currency List
            Expanded(
              child: ListView.builder(
                itemCount: CurrencyService.supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = CurrencyService.supportedCurrencies[index];
                  final isSelected = currency.code == _selectedCurrency;

                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          currency.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(
                      currency.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${currency.code} (${currency.symbol})',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedCurrency = currency.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount'),
          backgroundColor: AppTheme.expenseRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser!.uid;

      if (_suggestedCategory.isNotEmpty &&
          _suggestedCategory != _selectedCategory) {
        await _categorizationService.saveUserCorrection(
          userId: userId,
          merchantName: _titleController.text.trim(),
          suggestedCategory: _suggestedCategory,
          selectedCategory: _selectedCategory,
        );
      }

      final expense = Expense(
        id: widget.expense?.id,
        userId: userId,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        currency: _selectedCurrency,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.expense?.createdAt,
      );

      if (_isEditing) {
        await _databaseService.updateExpense(expense);
      } else {
        await _databaseService.addExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isEditing ? 'Expense updated!' : 'Expense added!'),
              ],
            ),
            backgroundColor: AppTheme.incomeGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyService.getCurrency(_selectedCurrency);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with Amount
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
                  child: Column(
                    children: [
                      // App Bar Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            ),
                            Expanded(
                              child: Text(
                                _isEditing ? 'Edit Expense' : 'Add Expense',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the back button
                          ],
                        ),
                      ),

                      // Amount Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Column(
                          children: [
                            Text(
                              'Enter Amount',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Amount Input
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  currency.symbol,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      hintText: '0.00',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Currency Selector Button
                            GestureDetector(
                              onTap: _showCurrencyPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currency.flag,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currency.code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Field
                      _buildCard(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g., Lunch at McDonalds',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Smart Category Suggestion
                      if (_suggestedCategory.isNotEmpty &&
                          _suggestedCategory != _selectedCategory)
                        CategorySuggestionWidget(
                          merchantName: _titleController.text,
                          currentCategory: _selectedCategory,
                          onCategorySelected: _applySuggestion,
                        ),

                      // Category Selection
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: ExpenseCategory.categories.length,
                                itemBuilder: (context, index) {
                                  final category = ExpenseCategory.categories[index];
                                  final isSelected = _selectedCategory == category.name;
                                  final isSuggested = _suggestedCategory == category.name;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedCategory = category.name);
                                    },
                                    child: Container(
                                      width: 72,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? category.color
                                                  : category.color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: isSelected
                                                  ? Border.all(color: category.color, width: 2)
                                                  : isSuggested
                                                      ? Border.all(
                                                          color: AppTheme.primaryColor,
                                                          width: 2,
                                                        )
                                                      : null,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: category.color.withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Icon(
                                              category.icon,
                                              color: isSelected ? Colors.white : category.color,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category.name,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? category.color
                                                  : Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Selection
                      _buildCard(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      _buildCard(
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Add any additional details...',
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notes,
                                color: AppTheme.accentPurple,
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing ? Icons.update : Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing ? 'Update Expense' : 'Add Expense',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}