import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/currency_service.dart';
import '../../services/pdf_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _currencyService = CurrencyService();
  final _pdfService = PdfService();

  String _selectedPeriod = 'This Month';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String _preferredCurrency = 'MYR';

  @override
  void initState() {
    super.initState();
    _setDateRange('This Month');
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await _currencyService.getPreferredCurrency();
    setState(() => _preferredCurrency = currency);
  }

  void _setDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 3 Months':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
        case 'Custom':
          // Keep current dates for custom
          break;
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: isDark ? AppTheme.darkCard : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateAndPreviewPdf() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Fetch expenses for date range
      final expenses = await _databaseService
          .getExpensesByDateRange(user.uid, _startDate, _endDate)
          .first;

      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('No expenses found for this period'),
                ],
              ),
              backgroundColor: AppTheme.accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Generate PDF
      final pdfBytes = await _pdfService.generateExpenseReport(
        expenses: expenses,
        userName: user.displayName ?? 'User',
        currencyCode: _preferredCurrency,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Show preview with print/share options
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'SmartExpense_Report_${DateFormat('yyyyMMdd').format(_startDate)}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareReport() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final expenses = await _databaseService
          .getExpensesByDateRange(user.uid, _startDate, _endDate)
          .first;

      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No expenses found for this period'),
              backgroundColor: AppTheme.accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final pdfBytes = await _pdfService.generateExpenseReport(
        expenses: expenses,
        userName: user.displayName ?? 'User',
        currencyCode: _preferredCurrency,
        startDate: _startDate,
        endDate: _endDate,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'SmartExpense_Report_${DateFormat('yyyyMMdd').format(_startDate)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Export Report'),
        backgroundColor: isDark ? AppTheme.darkSurface : null,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Generate PDF Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Export your expenses as a professional PDF report',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Period Selection
              Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildPeriodOption('This Month', Icons.calendar_today, isDark),
                    Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    _buildPeriodOption('Last Month', Icons.calendar_month, isDark),
                    Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    _buildPeriodOption('Last 3 Months', Icons.date_range, isDark),
                    Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    _buildPeriodOption('This Year', Icons.calendar_view_month, isDark),
                    Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    _buildPeriodOption('Custom', Icons.edit_calendar, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selected Date Range Display
              _buildCard(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.date_range,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Range',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedPeriod == 'Custom')
                        IconButton(
                          onPressed: _selectCustomDateRange,
                          icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Report Contents Preview
              Text(
                'Report Includes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCard(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildReportItem(Icons.summarize, 'Summary', 'Total spending, count & daily average', isDark),
                      const SizedBox(height: 12),
                      _buildReportItem(Icons.pie_chart, 'Category Breakdown', 'Spending by category with percentages', isDark),
                      const SizedBox(height: 12),
                      _buildReportItem(Icons.list_alt, 'Transaction List', 'All expenses with details', isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.visibility,
                      label: 'Preview',
                      color: AppTheme.primaryColor,
                      onTap: _isLoading ? null : _generateAndPreviewPdf,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: AppTheme.accentBlue,
                      onTap: _isLoading ? null : _shareReport,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full width print button
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.print,
                  label: 'Print Report',
                  color: AppTheme.accentPurple,
                  onTap: _isLoading ? null : _generateAndPreviewPdf,
                ),
              ),

              // Loading indicator
              if (_isLoading) ...[
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'Generating report...',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildPeriodOption(String period, IconData icon, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey),
      ),
      title: Text(
        period,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white : AppTheme.textPrimary),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        _setDateRange(period);
        if (period == 'Custom') {
          _selectCustomDateRange();
        }
      },
    );
  }

  Widget _buildReportItem(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check, color: AppTheme.primaryColor, size: 20),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey[300] : color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}