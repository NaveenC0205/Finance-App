import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/services/supabase_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _dashboard = {};
  List<Map<String, dynamic>> _monthlyTrend = [];
  bool _loading = false;
  bool _dashboardLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;

  // Filters
  DateTime? filterDateFrom;
  DateTime? filterDateTo;
  String? filterCategory;
  String? filterType;

  List<TransactionModel> get transactions => _transactions;
  Map<String, dynamic> get dashboard => _dashboard;
  List<Map<String, dynamic>> get monthlyTrend => _monthlyTrend;
  bool get loading => _loading;
  bool get dashboardLoading => _dashboardLoading;
  bool get hasMore => _hasMore;

  double get totalSpend => (_dashboard['total_debit'] as num?)?.toDouble() ?? 0;
  double get totalIncome => (_dashboard['total_credit'] as num?)?.toDouble() ?? 0;

  Map<String, double> get byCategory {
    final raw = _dashboard['by_category'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> loadDashboard(List<String> accountIds) async {
    if (accountIds.isEmpty) return;
    _dashboardLoading = true;
    notifyListeners();
    try {
      _dashboard = await SupabaseService.getDashboardData(accountIds);
      _monthlyTrend = await SupabaseService.getMonthlyTrend(accountIds);
    } catch (_) {}
    _dashboardLoading = false;
    notifyListeners();
  }

  Future<void> loadTransactions(List<String> accountIds, {bool refresh = false}) async {
    if (accountIds.isEmpty) return;
    if (refresh) {
      _transactions = [];
      _currentPage = 0;
      _hasMore = true;
    }
    if (!_hasMore || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final newTxns = await SupabaseService.getTransactions(
        accountIds: accountIds,
        dateFrom: filterDateFrom,
        dateTo: filterDateTo,
        category: filterCategory,
        transactionType: filterType,
        page: _currentPage,
      );
      if (newTxns.length < 20) _hasMore = false;
      _transactions.addAll(newTxns);
      _currentPage++;
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void applyFilters({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? category,
    String? type,
  }) {
    filterDateFrom = dateFrom;
    filterDateTo = dateTo;
    filterCategory = category == 'all' ? null : category;
    filterType = type == 'all' ? null : type;
    notifyListeners();
  }

  void clearFilters() {
    filterDateFrom = null;
    filterDateTo = null;
    filterCategory = null;
    filterType = null;
    notifyListeners();
  }

  Future<void> updateCategory(String txnId, String category) async {
    await SupabaseService.updateCategory(txnId, category);
    final idx = _transactions.indexWhere((t) => t.id == txnId);
    if (idx >= 0) {
      _transactions[idx] = TransactionModel(
        id: _transactions[idx].id,
        bankAccountId: _transactions[idx].bankAccountId,
        date: _transactions[idx].date,
        description: _transactions[idx].description,
        merchant: _transactions[idx].merchant,
        amount: _transactions[idx].amount,
        transactionType: _transactions[idx].transactionType,
        category: category,
        balance: _transactions[idx].balance,
        createdAt: _transactions[idx].createdAt,
      );
      notifyListeners();
    }
  }
}
