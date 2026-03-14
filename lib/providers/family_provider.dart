import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/bank_account_model.dart';
import '../core/services/supabase_service.dart';

class FamilyProvider extends ChangeNotifier {
  FamilyModel? _family;
  FamilyMemberModel? _myMembership;
  List<FamilyMemberModel> _members = [];
  List<BankAccountModel> _myAccounts = [];
  List<BankAccountModel> _familyAccounts = [];
  bool _loading = false;
  String? _error;

  FamilyModel? get family => _family;
  FamilyMemberModel? get myMembership => _myMembership;
  List<FamilyMemberModel> get members => _members;
  List<BankAccountModel> get myAccounts => _myAccounts;
  List<BankAccountModel> get familyAccounts => _familyAccounts;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasFamily => _family != null;

  Future<void> loadFamily() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _family = await SupabaseService.getMyFamily();
      if (_family != null) {
        await _loadMembers();
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadMembers() async {
    if (_family == null) return;
    _members = await SupabaseService.getFamilyMembers(_family!.id);
    _myMembership = await SupabaseService.getMyMembership(_family!.id);

    if (_myMembership != null) {
      _myAccounts = await SupabaseService.getBankAccounts(_myMembership!.id);
      final allIds = _members.map((m) => m.id).toList();
      _familyAccounts = await SupabaseService.getFamilyBankAccounts(allIds);
    }
    notifyListeners();
  }

  Future<bool> createFamily(String name) async {
    try {
      _family = await SupabaseService.createFamily(name);
      await _loadMembers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinFamily(String inviteCode) async {
    try {
      _family = await SupabaseService.joinFamily(inviteCode);
      if (_family != null) {
        await _loadMembers();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addBankAccount(BankAccountModel account) async {
    try {
      final added = await SupabaseService.addBankAccount(account);
      _myAccounts.add(added);
      _familyAccounts.add(added);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => loadFamily();

  List<String> get allAccountIds => _familyAccounts.map((a) => a.id).toList();
  List<String> get myAccountIds => _myAccounts.map((a) => a.id).toList();
}
