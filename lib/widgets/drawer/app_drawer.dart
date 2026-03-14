import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final location = GoRouterState.of(context).matchedLocation;

    final items = [
      _Item(Icons.dashboard_rounded,        'Dashboard',     '/dashboard'),
      _Item(Icons.people_rounded,            'Family',        '/family'),
      _Item(Icons.account_balance_rounded,   'Bank Accounts', '/bank-accounts'),
      _Item(Icons.swap_horiz_rounded,        'Transactions',  '/transactions'),
      _Item(Icons.bar_chart_rounded,         'Reports',       '/reports'),
      _Item(Icons.lightbulb_outline_rounded, 'Insights',      '/insights'),
      _Item(Icons.settings_rounded,          'Settings',      '/settings'),
    ];

    return Drawer(
      backgroundColor: AppColors.drawerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Family Finance',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                  if (family.hasFamily)
                    Text(family.family!.name,
                      style: const TextStyle(color: AppColors.drawerItem,
                          fontSize: 12, fontWeight: FontWeight.w400)),
                ]),
              ]),
            ),

            Divider(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 12),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final active = location.startsWith(item.route);
                  return _NavTile(
                    item: item, isActive: active,
                    onTap: () {
                      context.go(item.route);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),

            Divider(height: 1, color: Colors.white.withOpacity(0.08)),

            // User row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: auth.user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(auth.user!.userMetadata!['avatar_url'])
                      : null,
                  backgroundColor: AppColors.primary,
                  child: auth.user?.userMetadata?['avatar_url'] == null
                      ? Text(
                          (auth.user?.email ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    auth.user?.userMetadata?['name'] ?? auth.user?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    family.myMembership?.role.toUpperCase() ?? 'MEMBER',
                    style: const TextStyle(color: AppColors.drawerItem, fontSize: 10),
                  ),
                ])),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.drawerItem, size: 18),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) context.go('/sign-in');
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon; final String label, route;
  const _Item(this.icon, this.label, this.route);
}

class _NavTile extends StatelessWidget {
  final _Item item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(children: [
        Icon(item.icon,
          color: isActive ? AppColors.primaryLight : AppColors.drawerItem,
          size: 20),
        const SizedBox(width: 14),
        Text(item.label,
          style: TextStyle(
            color: isActive ? AppColors.drawerItemActive : AppColors.drawerItem,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          )),
      ]),
    ),
  );
}
