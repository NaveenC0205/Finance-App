class AppConstants {
  static const String supabaseUrl = 'https://qtkefumzlgylxsrnaaau.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0a2VmdW16bGd5bHhzcm5hYWF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0OTY0NTEsImV4cCI6MjA4OTA3MjQ1MX0.mx3opVKojPEaWevR74Uj-5Z8m7zXGR296vhNXL1LISQ';

  static const String appName = 'Family Finance Tracker';
  static const String statementsBucket = 'bank-statements';

  static const List<String> categories = [
    'food_dining', 'groceries', 'fuel', 'shopping', 'travel',
    'rent', 'emi', 'utilities', 'entertainment', 'healthcare',
    'investment', 'others',
  ];

  static const Map<String, String> categoryLabels = {
    'food_dining': 'Food & Dining',
    'groceries': 'Groceries',
    'fuel': 'Fuel',
    'shopping': 'Shopping',
    'travel': 'Travel',
    'rent': 'Rent',
    'emi': 'EMI',
    'utilities': 'Utilities',
    'entertainment': 'Entertainment',
    'healthcare': 'Healthcare',
    'investment': 'Investment',
    'others': 'Others',
  };

  static const Map<String, String> categoryEmojis = {
    'food_dining': '🍽️',
    'groceries': '🛒',
    'fuel': '⛽',
    'shopping': '🛍️',
    'travel': '✈️',
    'rent': '🏠',
    'emi': '🏦',
    'utilities': '💡',
    'entertainment': '🎬',
    'healthcare': '💊',
    'investment': '📈',
    'others': '📦',
  };
}
