import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/family_model.dart';
import '../../models/bank_account_model.dart';
import '../../models/transaction_model.dart';
import '../utils/helpers.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ─── Auth ────────────────────────────────────────────────────
  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  static Future<bool> signInWithApple() async {
    return await _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password, String name) async {
    return await _client.auth.signUp(email: email, password: password, data: {'name': name});
  }

  static Future<void> signOut() => _client.auth.signOut();

  static User? get currentUser => _client.auth.currentUser;

  // ─── Family ──────────────────────────────────────────────────
  static Future<FamilyModel> createFamily(String name) async {
    final userId = currentUser!.id;
    final inviteCode = generateInviteCode();
    final data = await _client.from('families').insert({
      'name': name,
      'admin_clerk_id': userId,
      'invite_code': inviteCode,
    }).select().single();

    // Auto-add creator as admin member
    await _client.from('family_members').insert({
      'family_id': data['id'],
      'clerk_user_id': userId,
      'email': currentUser!.email,
      'name': currentUser!.userMetadata?['name'] ?? currentUser!.email,
      'picture': currentUser!.userMetadata?['avatar_url'],
      'role': 'admin',
    });

    return FamilyModel.fromJson(data);
  }

  static Future<FamilyModel?> getMyFamily() async {
    final userId = currentUser!.id;
    final member = await _client
        .from('family_members')
        .select('family_id')
        .eq('clerk_user_id', userId)
        .maybeSingle();

    if (member == null) return null;

    final family = await _client
        .from('families')
        .select()
        .eq('id', member['family_id'])
        .single();

    return FamilyModel.fromJson(family);
  }

  static Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    final data = await _client
        .from('family_members')
        .select()
        .eq('family_id', familyId)
        .order('joined_at');
    return (data as List).map((e) => FamilyMemberModel.fromJson(e)).toList();
  }

  static Future<FamilyMemberModel?> getMyMembership(String familyId) async {
    final userId = currentUser!.id;
    final data = await _client
        .from('family_members')
        .select()
        .eq('family_id', familyId)
        .eq('clerk_user_id', userId)
        .maybeSingle();
    return data != null ? FamilyMemberModel.fromJson(data) : null;
  }

  static Future<FamilyModel?> joinFamily(String inviteCode) async {
    final family = await _client
        .from('families')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .maybeSingle();

    if (family == null) return null;

    final userId = currentUser!.id;
    await _client.from('family_members').upsert({
      'family_id': family['id'],
      'clerk_user_id': userId,
      'email': currentUser!.email,
      'name': currentUser!.userMetadata?['name'] ?? currentUser!.email,
      'picture': currentUser!.userMetadata?['avatar_url'],
      'role': 'member',
    });

    return FamilyModel.fromJson(family);
  }

  // ─── Bank Accounts ───────────────────────────────────────────
  static Future<BankAccountModel> addBankAccount(BankAccountModel account) async {
    final data = await _client
        .from('bank_accounts')
        .insert(account.toInsertJson())
        .select()
        .single();
    return BankAccountModel.fromJson(data);
  }

  static Future<List<BankAccountModel>> getBankAccounts(String familyMemberId) async {
    final data = await _client
        .from('bank_accounts')
        .select()
        .eq('family_member_id', familyMemberId)
        .eq('is_active', true)
        .order('created_at');
    return (data as List).map((e) => BankAccountModel.fromJson(e)).toList();
  }

  static Future<List<BankAccountModel>> getFamilyBankAccounts(List<String> memberIds) async {
    final data = await _client
        .from('bank_accounts')
        .select()
        .inFilter('family_member_id', memberIds)
        .eq('is_active', true);
    return (data as List).map((e) => BankAccountModel.fromJson(e)).toList();
  }

  static Future<void> deleteBankAccount(String id) async {
    await _client.from('bank_accounts').update({'is_active': false}).eq('id', id);
  }

  // ─── Statements ──────────────────────────────────────────────
  static Future<BankStatementModel> createStatement({
    required String bankAccountId,
    required String filename,
    required String fileType,
    required String filePath,
  }) async {
    final data = await _client.from('bank_statements').insert({
      'bank_account_id': bankAccountId,
      'filename': filename,
      'file_type': fileType,
      'file_path': filePath,
      'status': 'pending',
    }).select().single();
    return BankStatementModel.fromJson(data);
  }

  static Future<List<BankStatementModel>> getStatements(String bankAccountId) async {
    final data = await _client
        .from('bank_statements')
        .select()
        .eq('bank_account_id', bankAccountId)
        .order('uploaded_at', ascending: false);
    return (data as List).map((e) => BankStatementModel.fromJson(e)).toList();
  }

  static Future<void> updateStatementStatus(String id, String status, {int? count, String? error}) async {
    await _client.from('bank_statements').update({
      'status': status,
      if (count != null) 'transaction_count': count,
      if (error != null) 'error_message': error,
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ─── Transactions ─────────────────────────────────────────────
  static Future<void> insertTransactions(List<TransactionModel> txns) async {
    if (txns.isEmpty) return;
    await _client.from('transactions').insert(txns.map((t) => t.toInsertJson()).toList());
  }

  static Future<List<TransactionModel>> getTransactions({
    required List<String> accountIds,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? category,
    String? transactionType,
    String? memberId,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client
        .from('transactions')
        .select()
        .inFilter('bank_account_id', accountIds);

    if (dateFrom != null) {
      query = query.gte('date', dateFrom.toIso8601String().split('T')[0]);
    }
    if (dateTo != null) {
      query = query.lte('date', dateTo.toIso8601String().split('T')[0]);
    }
    if (category != null) query = query.eq('category', category);
    if (transactionType != null) query = query.eq('transaction_type', transactionType);

    final data = await query
        .order('date', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getDashboardData(List<String> accountIds) async {
    if (accountIds.isEmpty) return {};

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

    final txns = await _client
        .from('transactions')
        .select()
        .inFilter('bank_account_id', accountIds)
        .gte('date', monthStart);

    double totalDebit = 0, totalCredit = 0;
    final byCategory = <String, double>{};
    final byAccount = <String, double>{};

    for (final t in txns as List) {
      final amount = (t['amount'] as num).toDouble();
      if (t['transaction_type'] == 'debit') {
        totalDebit += amount;
        byCategory[t['category']] = (byCategory[t['category']] ?? 0) + amount;
        byAccount[t['bank_account_id']] = (byAccount[t['bank_account_id']] ?? 0) + amount;
      } else {
        totalCredit += amount;
      }
    }

    return {
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'by_category': byCategory,
      'by_account': byAccount,
      'transaction_count': txns.length,
    };
  }

  static Future<List<Map<String, dynamic>>> getMonthlyTrend(List<String> accountIds) async {
    if (accountIds.isEmpty) return [];
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final data = await _client
        .from('transactions')
        .select('date, amount, transaction_type')
        .inFilter('bank_account_id', accountIds)
        .eq('transaction_type', 'debit')
        .gte('date', sixMonthsAgo.toIso8601String().split('T')[0])
        .order('date');

    // Group by month
    final monthly = <String, double>{};
    for (final t in data as List) {
      final month = (t['date'] as String).substring(0, 7); // YYYY-MM
      monthly[month] = (monthly[month] ?? 0) + (t['amount'] as num).toDouble();
    }

    return monthly.entries.map((e) => {'month': e.key, 'amount': e.value}).toList()
      ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
  }

  static Future<void> updateCategory(String transactionId, String category) async {
    await _client.from('transactions').update({'category': category}).eq('id', transactionId);
  }

  // ─── Storage ─────────────────────────────────────────────────
  static Future<String> uploadStatementFile(String path, Uint8List bytes, String mimeType) async {
    await _client.storage.from('bank-statements').uploadBinary(path, bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true));
    return _client.storage.from('bank-statements').getPublicUrl(path);
  }
}
