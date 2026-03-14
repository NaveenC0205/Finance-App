import 'dart:math';
import 'package:intl/intl.dart';

String generateInviteCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random.secure();
  return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
}

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  return formatter.format(amount);
}

String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
String formatMonthYear(DateTime date) => DateFormat('MMM yyyy').format(date);
String formatMonth(String yyyyMM) {
  final parts = yyyyMM.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat('MMM yy').format(dt);
}

String categorize(String description) {
  final d = description.toLowerCase();
  if (RegExp(r'swiggy|zomato|dominos|mcdonald|restaurant|caf[eé]|hotel.*food|dining').hasMatch(d)) return 'food_dining';
  if (RegExp(r'bigbasket|grofer|blinkit|dmart|supermarket|grocery|vegetables|kirana').hasMatch(d)) return 'groceries';
  if (RegExp(r'petrol|diesel|hp |indian oil|bharat.*petro|shell|fuel').hasMatch(d)) return 'fuel';
  if (RegExp(r'amazon|flipkart|myntra|ajio|nykaa|meesho|mall|retail').hasMatch(d)) return 'shopping';
  if (RegExp(r'uber|ola|irctc|makemytrip|airline|flight|train|metro|rapido').hasMatch(d)) return 'travel';
  if (RegExp(r'rent|lease|landlord|property.*pay').hasMatch(d)) return 'rent';
  if (RegExp(r'emi|loan|mortgage|housing.*loan|car.*loan').hasMatch(d)) return 'emi';
  if (RegExp(r'electricity|water.*bill|gas.*bill|broadband|internet|jio|airtel|vi |bsnl|recharge').hasMatch(d)) return 'utilities';
  if (RegExp(r'netflix|spotify|prime|hotstar|cinema|movie|bookmyshow|game|disney').hasMatch(d)) return 'entertainment';
  if (RegExp(r'pharmacy|hospital|doctor|medical|clinic|apollo|health|medrx|1mg').hasMatch(d)) return 'healthcare';
  if (RegExp(r'mutual.*fund|sip|shares|stocks|zerodha|groww|nps|ppf|elss|demat').hasMatch(d)) return 'investment';
  return 'others';
}

String extractMerchant(String description) {
  final cleaned = description.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ').trim();
  final words = cleaned.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
  return words.take(3).join(' ').isEmpty ? description.substring(0, description.length.clamp(0, 30)) : words.take(3).join(' ');
}

List<Map<String, dynamic>> generateInsights(Map<String, double> byCategory, double totalSpend, Map<String, double> prevMonthByCategory) {
  final insights = <Map<String, dynamic>>[];

  // Top category
  if (byCategory.isNotEmpty) {
    final top = byCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = totalSpend > 0 ? (top.value / totalSpend * 100).round() : 0;
    insights.add({
      'text': 'You spent $pct% of your money on ${_label(top.key)} this month.',
      'type': pct > 30 ? 'warning' : 'info',
      'category': top.key,
    });
  }

  // Month-over-month changes
  for (final entry in byCategory.entries) {
    final prev = prevMonthByCategory[entry.key] ?? 0;
    if (prev > 0) {
      final change = ((entry.value - prev) / prev * 100).round();
      if (change > 20) {
        insights.add({
          'text': '${_label(entry.key)} expenses increased by $change% compared to last month.',
          'type': 'warning',
          'category': entry.key,
        });
      } else if (change < -20) {
        insights.add({
          'text': '${_label(entry.key)} expenses decreased by ${change.abs()}% — great job!',
          'type': 'positive',
          'category': entry.key,
        });
      }
    }
  }

  return insights;
}

String _label(String category) {
  const labels = {
    'food_dining': 'Food & Dining', 'groceries': 'Groceries', 'fuel': 'Fuel',
    'shopping': 'Shopping', 'travel': 'Travel', 'rent': 'Rent',
    'emi': 'EMI', 'utilities': 'Utilities', 'entertainment': 'Entertainment',
    'healthcare': 'Healthcare', 'investment': 'Investment', 'others': 'Others',
  };
  return labels[category] ?? category;
}
