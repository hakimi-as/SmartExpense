import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Extract text from image
  Future<OcrResult> extractTextFromImage(String imagePath) async {
    // Check if running on web
    if (kIsWeb) {
      return OcrResult(
        success: false,
        rawText: '',
        errorMessage: 'OCR is not supported on web. Please use mobile app.',
      );
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;

      // Parse the extracted text
      final amount = _extractAmount(rawText);
      final date = _extractDate(rawText);
      final merchant = _extractMerchant(rawText);

      return OcrResult(
        success: true,
        rawText: rawText,
        amount: amount,
        date: date,
        merchant: merchant,
      );
    } catch (e) {
      return OcrResult(
        success: false,
        rawText: '',
        errorMessage: 'Failed to process image: $e',
      );
    }
  }

  // Extract amount from text
  double? _extractAmount(String text) {
    // Common patterns for amounts: RM 50.00, MYR 50.00, TOTAL 50.00, etc.
    final patterns = [
      RegExp(r'(?:TOTAL|GRAND TOTAL|AMOUNT|JUMLAH|RM|MYR)\s*[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'RM\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'MYR\s*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})\s*(?:RM|MYR)', caseSensitive: false),
      RegExp(r'(?:TOTAL|JUMLAH)[:\s]*[RM\s]*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    // Try each pattern
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }

    // Fallback: Find the largest number (likely to be total)
    final allAmounts = RegExp(r'(\d+[.,]\d{2})').allMatches(text);
    double? maxAmount;
    for (var match in allAmounts) {
      final amountStr = match.group(1)?.replaceAll(',', '.');
      if (amountStr != null) {
        final amount = double.tryParse(amountStr);
        if (amount != null && (maxAmount == null || amount > maxAmount)) {
          maxAmount = amount;
        }
      }
    }

    return maxAmount;
  }

  // Extract date from text
  DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
      // DD/MM/YY or DD-MM-YY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})'),
      // YYYY/MM/DD or YYYY-MM-DD
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          int day, month, year;

          if (match.group(1)!.length == 4) {
            // YYYY/MM/DD format
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // DD/MM/YYYY or DD/MM/YY format
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
            if (year < 100) {
              year += 2000; // Convert 24 to 2024
            }
          }

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  // Extract merchant name from text
  String? _extractMerchant(String text) {
    final lines = text.split('\n');

    // Usually the merchant name is in the first few lines
    for (var i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();

      // Skip empty lines, lines with only numbers, or common receipt words
      if (line.isEmpty) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (RegExp(r'^(GST|SST|TAX|RECEIPT|INVOICE|DATE|TIME|TOTAL|CASH|CHANGE)', caseSensitive: false).hasMatch(line)) continue;

      // Check if line looks like a merchant name (has letters, reasonable length)
      if (line.length >= 3 && line.length <= 50 && RegExp(r'[a-zA-Z]').hasMatch(line)) {
        // Remove common suffixes
        var merchant = line
            .replaceAll(RegExp(r'\s*(SDN\s*BHD|BHD|SDN|PTE\s*LTD|LTD|LLC|INC)\s*$', caseSensitive: false), '')
            .trim();
        
        if (merchant.isNotEmpty) {
          return merchant;
        }
      }
    }

    return null;
  }

  // Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

// Result class
class OcrResult {
  final bool success;
  final String rawText;
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String? errorMessage;

  OcrResult({
    required this.success,
    required this.rawText,
    this.amount,
    this.date,
    this.merchant,
    this.errorMessage,
  });
}