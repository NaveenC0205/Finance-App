import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/bank_account_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/family_provider.dart';
import '../../widgets/drawer/app_drawer.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});
  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final _bankNameCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String _accountType = 'savings';
  bool _uploading = false;

  @override
  void dispose() {
    _bankNameCtrl.dispose(); _lastFourCtrl.dispose(); _nicknameCtrl.dispose();
    super.dispose();
  }

  void _showAddAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name *', hintText: 'e.g. HDFC Bank')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _accountType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: const [
              DropdownMenuItem(value: 'savings', child: Text('Savings')),
              DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
              DropdownMenuItem(value: 'current', child: Text('Current')),
            ],
            onChanged: (v) => setState(() => _accountType = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _lastFourCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'Last 4 Digits', hintText: '1234', counterText: '')),
          const SizedBox(height: 12),
          TextField(controller: _nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname (optional)', hintText: 'e.g. My Salary Account')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addAccount,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Add Account'),
          ),
        ]),
      ),
    );
  }

  Future<void> _addAccount() async {
    if (_bankNameCtrl.text.trim().isEmpty) return;
    final family = context.read<FamilyProvider>();
    if (family.myMembership == null) return;

    final account = BankAccountModel(
      id: '', familyMemberId: family.myMembership!.id,
      bankName: _bankNameCtrl.text.trim(),
      accountType: _accountType,
      lastFourDigits: _lastFourCtrl.text.isEmpty ? null : _lastFourCtrl.text,
      nickname: _nicknameCtrl.text.isEmpty ? null : _nicknameCtrl.text,
      isActive: true, createdAt: DateTime.now(),
    );

    final ok = await family.addBankAccount(account);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Bank account added!' : 'Failed to add account'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
    }
  }

  Future<void> _uploadStatement(String accountId, String accountName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await File(file.path!).readAsBytes();
      final ext = file.extension?.toLowerCase() ?? 'csv';
      final filePath = '${accountId}/${DateTime.now().millisecondsSinceEpoch}.${ext}';

      // Upload file to Supabase storage
      final statement = await SupabaseService.createStatement(
        bankAccountId: accountId, filename: file.name,
        fileType: ext, filePath: filePath,
      );

      // Parse CSV inline (for demo; real PDF parsing needs backend)
      if (ext == 'csv') {
        final csvStr = String.fromCharCodes(bytes);
        final rows = const CsvToListConverter().convert(csvStr, eol: '\n');
        if (rows.length > 1) {
          final headers = rows[0].map((h) => h.toString().toLowerCase().trim()).toList();
          final dateIdx = headers.indexWhere((h) => h.contains('date'));
          final descIdx = headers.indexWhere((h) => h.contains('desc') || h.contains('narr') || h.contains('particular'));
          final debitIdx = headers.indexWhere((h) => h.contains('debit') || h.contains('dr'));
          final creditIdx = headers.indexWhere((h) => h.contains('credit') || h.contains('cr'));

          final txns = <TransactionModel>[];
          for (final row in rows.skip(1)) {
            if (row.length <= dateIdx || dateIdx < 0) continue;
            final debit = debitIdx >= 0 && row[debitIdx].toString().isNotEmpty
                ? double.tryParse(row[debitIdx].toString().replaceAll(RegExp(r'[₹,]'), '')) ?? 0.0 : 0.0;
            final credit = creditIdx >= 0 && row[creditIdx].toString().isNotEmpty
                ? double.tryParse(row[creditIdx].toString().replaceAll(RegExp(r'[₹,]'), '')) ?? 0.0 : 0.0;
            final desc = descIdx >= 0 ? row[descIdx].toString() : 'Transaction';

            if (debit == 0 && credit == 0) continue;

            txns.add(TransactionModel(
              id: '', bankAccountId: accountId,
              statementId: statement.id,
              date: DateTime.tryParse(row[dateIdx].toString()) ?? DateTime.now(),
              description: desc, merchant: extractMerchant(desc),
              amount: debit > 0 ? debit : credit,
              transactionType: debit > 0 ? 'debit' : 'credit',
              category: categorize(desc), createdAt: DateTime.now(),
            ));
          }

          await SupabaseService.insertTransactions(txns);
          await SupabaseService.updateStatementStatus(statement.id, 'completed', count: txns.length);

          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Imported ${txns.length} transactions from ${file.name}'),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        await SupabaseService.updateStatementStatus(statement.id, 'completed');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File uploaded. PDF/Excel parsing requires backend processing.'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'), backgroundColor: AppColors.danger,
      ));
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Accounts')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: family.myMembership != null ? _showAddAccountSheet : null,
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
      body: family.myAccounts.isEmpty
          ? const Center(child: Text('No bank accounts yet.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                Text('My Accounts (${family.myAccounts.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_uploading)
                  const LinearProgressIndicator(),
                ...family.myAccounts.map((acc) => _AccountCard(
                  account: acc,
                  onUpload: () => _uploadStatement(acc.id, acc.displayName),
                )),
                const SizedBox(height: 24),
                if (family.familyAccounts.length > family.myAccounts.length) ...[
                  const Text('Family Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...family.familyAccounts
                      .where((a) => !family.myAccounts.any((m) => m.id == a.id))
                      .map((acc) => _AccountCard(account: acc, readOnly: true)),
                ],
              ],
            ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final BankAccountModel account;
  final VoidCallback? onUpload;
  final bool readOnly;
  const _AccountCard({required this.account, this.onUpload, this.readOnly = false});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(account.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(children: [
            _TypeBadge(type: account.accountType),
            if (account.lastFourDigits != null) ...[
              const SizedBox(width: 6),
              Text('••••${account.lastFourDigits}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ]),
        ])),
        if (!readOnly && onUpload != null)
          IconButton(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            tooltip: 'Upload Statement',
          ),
      ]),
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final labels = {'savings': 'Savings', 'credit_card': 'Credit Card', 'current': 'Current'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
      child: Text(labels[type] ?? type, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    );
  }
}
