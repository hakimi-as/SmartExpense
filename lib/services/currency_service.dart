import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  // Free API - no key required
  static const String _baseUrl = 'https://api.frankfurter.app';
  
  // Supported currencies
  static const List<Currency> supportedCurrencies = [
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', flag: '🇲🇾'),
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳'),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht', flag: '🇹🇭'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', flag: '🇮🇩'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso', flag: '🇵🇭'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
  ];

  // Cache for exchange rates
  Map<String, double> _ratesCache = {};
  DateTime? _cacheTime;

  // Get user's preferred currency
  Future<String> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_currency') ?? 'MYR';
  }

  // Set user's preferred currency
  Future<void> setPreferredCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_currency', currencyCode);
  }

  // Get currency by code
  static Currency getCurrency(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
  }

  // Fetch exchange rates from API
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    // Return cached rates if less than 1 hour old
    if (_ratesCache.isNotEmpty && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!).inHours < 1) {
      return _ratesCache;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?from=$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map).map((key, value) => 
            MapEntry(key, (value as num).toDouble())
          ),
        );
        
        // Add base currency with rate 1.0
        rates[baseCurrency] = 1.0;
        
        _ratesCache = rates;
        _cacheTime = DateTime.now();
        
        return rates;
      } else {
        throw Exception('Failed to fetch exchange rates');
      }
    } catch (e) {
      // Return fallback rates if API fails
      return _getFallbackRates(baseCurrency);
    }
  }

  // Convert amount between currencies
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    try {
      final rates = await getExchangeRates(from);
      final rate = rates[to];
      
      if (rate != null) {
        return amount * rate;
      }
      return amount;
    } catch (e) {
      return amount;
    }
  }

  // Get exchange rate between two currencies
  Future<double?> getRate(String from, String to) async {
    if (from == to) return 1.0;

    try {
      final rates = await getExchangeRates(from);
      return rates[to];
    } catch (e) {
      return null;
    }
  }

  // Fallback rates (approximate) when API is unavailable
  Map<String, double> _getFallbackRates(String base) {
    // Approximate rates based on MYR
    const myrRates = {
      'MYR': 1.0,
      'USD': 0.21,
      'SGD': 0.28,
      'EUR': 0.19,
      'GBP': 0.17,
      'JPY': 32.0,
      'CNY': 1.53,
      'THB': 7.5,
      'IDR': 3300.0,
      'PHP': 12.0,
      'INR': 17.5,
      'AUD': 0.32,
    };

    if (base == 'MYR') {
      return myrRates;
    }

    // Convert rates to the requested base currency
    final baseToMyr = 1 / (myrRates[base] ?? 1.0);
    return myrRates.map((key, value) => 
      MapEntry(key, value * baseToMyr)
    );
  }

  // Format amount with currency symbol
  // Format amount with currency symbol and thousand separators
String formatAmount(double amount, String currencyCode) {
  final currency = getCurrency(currencyCode);
  
  // Handle currencies with no decimal places (like JPY, IDR)
  if (currencyCode == 'JPY' || currencyCode == 'IDR') {
    return '${currency.symbol}${_formatWithCommas(amount.round().toDouble(), 0)}';
  }
  
  return '${currency.symbol}${_formatWithCommas(amount, 2)}';
}

// Static version for use without instance
static String formatAmountStatic(double amount, String currencyCode) {
  final currency = getCurrency(currencyCode);
  
  if (currencyCode == 'JPY' || currencyCode == 'IDR') {
    return '${currency.symbol}${_formatNumberWithCommas(amount.round().toDouble(), 0)}';
  }
  
  return '${currency.symbol}${_formatNumberWithCommas(amount, 2)}';
}

// Helper to format number with commas
String _formatWithCommas(double value, int decimals) {
  return _formatNumberWithCommas(value, decimals);
}

// Static helper to format number with commas
static String _formatNumberWithCommas(double value, int decimals) {
  String result = value.toStringAsFixed(decimals);
  
  // Split into integer and decimal parts
  List<String> parts = result.split('.');
  String integerPart = parts[0];
  String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
  
  // Add commas to integer part
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
}

// Currency model
class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}