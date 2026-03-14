import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _key = 'transactions';

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((item) => Transaction.fromJson(item as Map<String, dynamic>)).toList();
  }
}
