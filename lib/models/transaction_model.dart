import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TransactionModel {
  final String id;
  final String bankAccountId;
  final String? statementId;
  final DateTime date;
  final String description;
  final String? merchant;
  final double amount;
  final String transactionType; // debit / credit
  final String category;
  final double? balance;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.bankAccountId,
    this.statementId,
    required this.date,
    required this.description,
    this.merchant,
    required this.amount,
    required this.transactionType,
    required this.category,
    this.balance,
    required this.createdAt,
  });

  bool get isDebit => transactionType == 'debit';

  Color get typeColor => isDebit ? AppColors.danger : AppColors.success;

  String get amountDisplay => '${isDebit ? '-' : '+'}₹${amount.toStringAsFixed(0)}';

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        bankAccountId: json['bank_account_id'],
        statementId: json['statement_id'],
        date: DateTime.parse(json['date']),
        description: json['description'],
        merchant: json['merchant'],
        amount: (json['amount'] as num).toDouble(),
        transactionType: json['transaction_type'],
        category: json['category'] ?? 'others',
        balance: json['balance'] != null ? (json['balance'] as num).toDouble() : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toInsertJson() => {
        'bank_account_id': bankAccountId,
        'statement_id': statementId,
        'date': date.toIso8601String().split('T')[0],
        'description': description,
        'merchant': merchant,
        'amount': amount,
        'transaction_type': transactionType,
        'category': category,
        'balance': balance,
      };
}

class SpendingSummary {
  final double totalDebit;
  final double totalCredit;
  final Map<String, double> byCategory;
  final Map<String, double> byMember;

  SpendingSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.byCategory,
    required this.byMember,
  });
}
