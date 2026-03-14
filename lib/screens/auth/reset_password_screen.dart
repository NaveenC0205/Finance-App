import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _updatePassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pass.isEmpty || confirm.isEmpty) return;
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to update password.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('New Password',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 24),
            const Text('Set New Password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Choose a strong password for your account.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            // New password
            TextField(
              controller: _passCtrl,
              obscureText: _obscure1,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20,
                  ),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Confirm password
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscure2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loading ? null : _updatePassword,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _loading
                        ? [AppColors.textTertiary, AppColors.textTertiary]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _loading ? [] : [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6),
                  )],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password',
                          style: TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
