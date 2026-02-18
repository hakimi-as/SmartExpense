import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/currency_service.dart';

class PdfService {
  // Generate expense report PDF
  Future<Uint8List> generateExpenseReport({
    required List<Expense> expenses,
    required String userName,
    required String currencyCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final currency = CurrencyService.getCurrency(currencyCode);

    // Calculate summary
    double totalSpending = 0;
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      totalSpending += expense.amount;
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Sort categories by amount
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate daily average
    final days = endDate.difference(startDate).inDays + 1;
    final dailyAverage = expenses.isNotEmpty ? totalSpending / days : 0.0;

    // Define colors
    final primaryColor = PdfColor.fromHex('#00C853');
    final darkColor = PdfColor.fromHex('#1A1A2E');
    final greyColor = PdfColor.fromHex('#6B7280');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(startDate, endDate, primaryColor),
          pw.SizedBox(height: 30),

          // Summary Card
          _buildSummaryCard(
            totalSpending: totalSpending,
            expenseCount: expenses.length,
            dailyAverage: dailyAverage,
            currency: currency,
            primaryColor: primaryColor,
          ),
          pw.SizedBox(height: 25),

          // Category Breakdown
          if (sortedCategories.isNotEmpty) ...[
            _buildSectionTitle('Spending by Category', darkColor),
            pw.SizedBox(height: 15),
            _buildCategoryBreakdown(
              sortedCategories,
              totalSpending,
              currency,
              greyColor,
            ),
            pw.SizedBox(height: 25),
          ],

          // Transaction List
          _buildSectionTitle('All Transactions', darkColor),
          pw.SizedBox(height: 15),
          _buildTransactionTable(expenses, currency, greyColor),
          pw.SizedBox(height: 30),

          // Footer
          _buildFooter(userName, greyColor),
        ],
      ),
    );

    return pdf.save();
  }

  // Header with title and date range
  pw.Widget _buildHeader(
    DateTime startDate,
    DateTime endDate,
    PdfColor primaryColor,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final monthFormat = DateFormat('MMMM yyyy');

    String dateRangeText;
    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      dateRangeText = monthFormat.format(startDate);
    } else {
      dateRangeText = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SmartExpense',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Expense Report',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              dateRangeText,
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Summary card with key metrics
  pw.Widget _buildSummaryCard({
    required double totalSpending,
    required int expenseCount,
    required double dailyAverage,
    required Currency currency,
    required PdfColor primaryColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Total Spending',
            '${currency.symbol}${_formatWithCommas(totalSpending)}',
            primaryColor,
          ),
          _buildMetricItem(
            'Transactions',
            expenseCount.toString(),
            PdfColor.fromHex('#7C4DFF'),
          ),
          _buildMetricItem(
            'Daily Average',
            '${currency.symbol}${_formatWithCommas(dailyAverage)}',
            PdfColor.fromHex('#2196F3'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey600,
            fontSize: 10,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Section title
  pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  // Category breakdown
  pw.Widget _buildCategoryBreakdown(
    List<MapEntry<String, double>> categories,
    double total,
    Currency currency,
    PdfColor greyColor,
  ) {
    return pw.Column(
      children: categories.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              pw.Container(
                width: 100,
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 20,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.Container(
                      height: 20,
                      width: (percentage / 100) * 250,
                      decoration: pw.BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 80,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${currency.symbol}${_formatWithCommas(entry.value)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Container(
                width: 45,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: greyColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Transaction table
  pw.Widget _buildTransactionTable(
    List<Expense> expenses,
    Currency currency,
    PdfColor greyColor,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Title', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        // Data rows
        ...expenses.map((expense) => pw.TableRow(
          children: [
            _buildTableCell(DateFormat('MMM d').format(expense.date)),
            _buildTableCell(expense.title),
            _buildTableCell(expense.category),
            _buildTableCell(
              '-${currency.symbol}${_formatWithCommas(expense.amount)}',
              align: pw.Alignment.centerRight,
              color: PdfColor.fromHex('#FF5252'),
            ),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  // Footer
  pw.Widget _buildFooter(String userName, PdfColor greyColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Generated by SmartExpense',
                style: pw.TextStyle(fontSize: 10, color: greyColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'User: $userName',
                style: pw.TextStyle(fontSize: 10, color: greyColor),
              ),
            ],
          ),
          pw.Text(
            DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 10, color: greyColor),
          ),
        ],
      ),
    );
  }

  // Helper: Format with commas
  String _formatWithCommas(double value) {
    String result = value.toStringAsFixed(2);
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

  // Helper: Get category color
  PdfColor _getCategoryColor(String category) {
    final colors = {
      'Food': PdfColor.fromHex('#FF9800'),
      'Transport': PdfColor.fromHex('#2196F3'),
      'Shopping': PdfColor.fromHex('#E91E63'),
      'Bills': PdfColor.fromHex('#9C27B0'),
      'Entertainment': PdfColor.fromHex('#00BCD4'),
      'Health': PdfColor.fromHex('#F44336'),
      'Education': PdfColor.fromHex('#3F51B5'),
      'Others': PdfColor.fromHex('#607D8B'),
    };
    return colors[category] ?? PdfColor.fromHex('#607D8B');
  }
}