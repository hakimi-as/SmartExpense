class AppConstants {
  static const String appName = 'SmartExpense';
  
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': '🍔', 'color': 0xFFFF7043},
    {'name': 'Transport', 'icon': '🚗', 'color': 0xFF42A5F5},
    {'name': 'Shopping', 'icon': '🛍️', 'color': 0xFFAB47BC},
    {'name': 'Bills', 'icon': '📄', 'color': 0xFFFFCA28},
    {'name': 'Entertainment', 'icon': '🎬', 'color': 0xFFEC407A},
    {'name': 'Health', 'icon': '💊', 'color': 0xFF26A69A},
    {'name': 'Education', 'icon': '📚', 'color': 0xFF5C6BC0},
    {'name': 'Others', 'icon': '📦', 'color': 0xFF78909C},
  ];

  static const List<Map<String, String>> currencies = [
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
  ];
}
