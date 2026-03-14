import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;
  bool _obscure  = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose(); _otpCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  // Step 1 — send OTP via signInWithOtp (sends real 6-digit code)
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // only works for existing users
      );
      if (mounted) setState(() { _loading = false; _codeSent = true; });
    } on AuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to send code. Try again.'; });
    }
  }

  // Step 2 — verify OTP, sign in, then update password
  Future<void> _verifyAndUpdate() async {
    final otp  = _otpCtrl.text.trim();
    final pass = _passCtrl.text;
    if (otp.isEmpty || pass.isEmpty) return;
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Verify OTP — this signs the user in
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: otp,
        type: OtpType.email,
      );
      // Update password now that user is signed in
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Invalid or expired code. Request a new one.';
      });
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
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Reset Password',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.primaryLight, size: 28),
            ),
            const SizedBox(height: 24),

            Text(
              _codeSent ? 'Enter the code' : 'Forgot Password?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'A 6-digit code was sent to ${_emailCtrl.text.trim()}. Enter it below with your new password.'
                  : 'Enter your registered email. We\'ll send a 6-digit code to reset your password.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Email field
            TextField(
              controller: _emailCtrl,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: const Icon(Icons.mail_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: _codeSent
                    ? AppColors.surfaceVariant.withOpacity(0.4)
                    : AppColors.surfaceVariant,
              ),
            ),

            if (_codeSent) ...[
              const SizedBox(height: 16),

              // OTP input
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24, fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                decoration: const InputDecoration(
                  labelText: '6-digit code',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // New password
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary, size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ],

            // Error box
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

            // Primary button
            _GradientBtn(
              loading: _loading,
              label: _codeSent ? 'Reset Password' : 'Send Code',
              onTap: _loading ? null : (_codeSent ? _verifyAndUpdate : _sendOtp),
            ),

            if (_codeSent) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => setState(() {
                    _codeSent = false;
                    _otpCtrl.clear(); _passCtrl.clear(); _error = null;
                  }),
                  child: const Text('Didn\'t get a code? Resend',
                    style: TextStyle(color: AppColors.primaryLight,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback? onTap;
  const _GradientBtn({required this.loading, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onTap == null
              ? [AppColors.textTertiary, AppColors.textTertiary]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null ? [BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 16, offset: const Offset(0, 6),
        )] : [],
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}
