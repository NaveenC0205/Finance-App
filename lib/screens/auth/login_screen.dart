import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _isSignUp = false;
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthProvider>();
    final err = _isSignUp
        ? await auth.signUp(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim())
        : await auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (mounted) {
      setState(() { _loading = false; _error = err; });
      if (err == null && mounted) context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(top: -100, right: -80,
            child: _GlowBlob(color: AppColors.primary, size: 300)),
          Positioned(bottom: 50, left: -100,
            child: _GlowBlob(color: AppColors.primaryDark, size: 250)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo mark
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20, offset: const Offset(0, 8),
                      )],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 28),

                  // Headline
                  Text(
                    _isSignUp ? 'Create\nAccount' : 'Welcome\nBack',
                    style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Start tracking family finances'
                        : 'Your finances, all in one place',
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Social buttons
                  _SocialBtn(
                    onTap: () async {
                      setState(() { _loading = true; _error = null; });
                      final err = await context.read<AuthProvider>().signInWithGoogle();
                      if (mounted) setState(() { _loading = false; _error = err; });
                      if (err == null && mounted) context.go('/dashboard');
                    },
                    icon: _googleIcon(),
                    label: 'Continue with Google',
                    bg: AppColors.cardHighlight,
                    fg: AppColors.textPrimary,
                    borderColor: AppColors.border,
                  ),
                  const SizedBox(height: 12),
                  _SocialBtn(
                    onTap: () async {
                      setState(() { _loading = true; _error = null; });
                      final err = await context.read<AuthProvider>().signInWithApple();
                      if (mounted) setState(() { _loading = false; _error = err; });
                    },
                    icon: const Icon(Icons.apple, color: AppColors.textPrimary, size: 22),
                    label: 'Continue with Apple',
                    bg: AppColors.cardHighlight,
                    fg: AppColors.textPrimary,
                    borderColor: AppColors.border,
                  ),

                  const SizedBox(height: 28),
                  _Divider(),
                  const SizedBox(height: 28),

                  // Name field (sign up only)
                  if (_isSignUp) ...[
                    _Field(ctrl: _nameCtrl, label: 'Full Name',
                        icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                  ],

                  _Field(ctrl: _emailCtrl, label: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
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

                  // Error
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
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13))),
                      ]),
                    ),
                  ],

                  // Forgot password (sign in only)
                  if (!_isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Forgot password?',
                          style: TextStyle(color: AppColors.primaryLight,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // CTA button
                  _GradientButton(
                    loading: _loading,
                    label: _isSignUp ? 'Create Account' : 'Sign In',
                    onTap: _loading ? null : _handleEmailAuth,
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Sign in' : 'Sign up',
                              style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleIcon() => SizedBox(
    width: 22, height: 22,
    child: Image.network(
      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.g_mobiledata, color: AppColors.textPrimary, size: 22),
    ),
  );
}

// ── Gradient glow blob ──────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withOpacity(0.25), Colors.transparent]),
    ),
  );
}

// ── Social button ───────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final Color bg, fg, borderColor;
  const _SocialBtn({required this.onTap, required this.icon, required this.label,
      required this.bg, required this.fg, required this.borderColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon,
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Divider with "or" ───────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: AppColors.border)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('or', style: TextStyle(
          color: AppColors.textTertiary, fontSize: 13)),
    ),
    const Expanded(child: Divider(color: AppColors.border)),
  ]);
}

// ── Text field ──────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  const _Field({required this.ctrl, required this.label, required this.icon, this.keyboard});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
    ),
  );
}

// ── Gradient CTA button ─────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback? onTap;
  const _GradientButton({required this.loading, required this.label, this.onTap});

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
