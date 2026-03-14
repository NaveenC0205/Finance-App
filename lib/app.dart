import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/bank_accounts/bank_accounts_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/insights/insights_screen.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String _initialLocation = '/sign-in';

  @override
  void initState() {
    super.initState();

    // Check if already authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) _initialLocation = '/dashboard';

    // Listen for password recovery deep link
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _router?.go('/reset-password');
      }
    });
  }

  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()..loadFamily()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          _router = GoRouter(
            initialLocation: auth.isAuthenticated ? '/dashboard' : _initialLocation,
            redirect: (context, state) {
              final isAuth = context.read<AuthProvider>().isAuthenticated;
              final loc = state.matchedLocation;
              final isLoginRoute = loc == '/sign-in';
              final isResetRoute = loc == '/reset-password';
              if (isResetRoute) return null; // always allow reset
              if (!isAuth && !isLoginRoute) return '/sign-in';
              if (isAuth && isLoginRoute) return '/dashboard';
              return null;
            },
            routes: [
              GoRoute(path: '/sign-in',        builder: (_, __) => const LoginScreen()),
              GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
              GoRoute(path: '/dashboard',      builder: (_, __) => const DashboardScreen()),
              GoRoute(path: '/family',         builder: (_, __) => const FamilyScreen()),
              GoRoute(path: '/bank-accounts',  builder: (_, __) => const BankAccountsScreen()),
              GoRoute(path: '/transactions',   builder: (_, __) => const TransactionsScreen()),
              GoRoute(path: '/insights',       builder: (_, __) => const InsightsScreen()),
              GoRoute(path: '/reports',        builder: (_, __) => const DashboardScreen()),
              GoRoute(path: '/settings',       builder: (_, __) => const DashboardScreen()),
            ],
          );

          return MaterialApp.router(
            title: 'Family Finance Tracker',
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: _router!,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
