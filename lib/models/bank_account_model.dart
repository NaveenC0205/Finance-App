class BankAccountModel {
  final String id;
  final String familyMemberId;
  final String bankName;
  final String accountType;
  final String? lastFourDigits;
  final String? nickname;
  final bool isActive;
  final DateTime createdAt;

  BankAccountModel({
    required this.id,
    required this.familyMemberId,
    required this.bankName,
    required this.accountType,
    this.lastFourDigits,
    this.nickname,
    required this.isActive,
    required this.createdAt,
  });

  String get displayName => nickname ?? '$bankName ${lastFourDigits != null ? "••••${lastFourDigits}" : ""}';

  factory BankAccountModel.fromJson(Map<String, dynamic> json) => BankAccountModel(
        id: json['id'],
        familyMemberId: json['family_member_id'],
        bankName: json['bank_name'],
        accountType: json['account_type'],
        lastFourDigits: json['last_four_digits'],
        nickname: json['nickname'],
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toInsertJson() => {
        'family_member_id': familyMemberId,
        'bank_name': bankName,
        'account_type': accountType,
        'last_four_digits': lastFourDigits,
        'nickname': nickname,
      };
}

class BankStatementModel {
  final String id;
  final String bankAccountId;
  final String filename;
  final String fileType;
  final String status;
  final int? transactionCount;
  final String? errorMessage;
  final DateTime uploadedAt;

  BankStatementModel({
    required this.id,
    required this.bankAccountId,
    required this.filename,
    required this.fileType,
    required this.status,
    this.transactionCount,
    this.errorMessage,
    required this.uploadedAt,
  });

  factory BankStatementModel.fromJson(Map<String, dynamic> json) => BankStatementModel(
        id: json['id'],
        bankAccountId: json['bank_account_id'],
        filename: json['filename'],
        fileType: json['file_type'],
        status: json['status'],
        transactionCount: json['transaction_count'],
        errorMessage: json['error_message'],
        uploadedAt: DateTime.parse(json['uploaded_at']),
      );
}
