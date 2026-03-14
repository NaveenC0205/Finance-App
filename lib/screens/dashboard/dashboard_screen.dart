import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/charts/spending_pie_chart.dart';
import '../../widgets/charts/spending_line_chart.dart';
import '../../widgets/drawer/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    final txns = context.read<TransactionProvider>();
    if (family.allAccountIds.isNotEmpty) {
      await txns.loadDashboard(family.allAccountIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final txns   = context.watch<TransactionProvider>();

    final userName = auth.user?.userMetadata?['name'] ??
        auth.user?.email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: txns.dashboardLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: () async { await family.refresh(); await _loadData(); },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(context, userName, family),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // No family banner
                          if (!family.hasFamily) ...[
                            const SizedBox(height: 16),
                            _NoFamilyBanner(),
                          ],

                          const SizedBox(height: 20),

                          // Hero balance card
                          _HeroCard(
                            income: txns.totalIncome,
                            spend: txns.totalSpend,
                          ),
                          const SizedBox(height: 20),

                          // Quick stats row
                          Row(children: [
                            Expanded(child: _MiniStat(
                              label: 'Members',
                              value: '${family.members.length}',
                              icon: Icons.people_rounded,
                              color: AppColors.info,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStat(
                              label: 'Accounts',
                              value: '${family.familyAccounts.length}',
                              icon: Icons.account_balance_rounded,
                              color: AppColors.warning,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStat(
                              label: 'Txns',
                              value: '${txns.byCategory.values.fold<double>(0, (a, b) => a + b) ~/ 1}',
                              icon: Icons.swap_horiz_rounded,
                              color: AppColors.primary,
                            )),
                          ]),

                          // Monthly trend
                          if (txns.monthlyTrend.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _SectionHeader('Monthly Trend'),
                            const SizedBox(height: 12),
                            _ChartCard(child: SpendingLineChart(data: txns.monthlyTrend)),
                          ],

                          // Spending by category
                          if (txns.byCategory.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _SectionHeader('Spending Breakdown'),
                            const SizedBox(height: 12),
                            _ChartCard(child: SpendingPieChart(data: txns.byCategory)),
                            const SizedBox(height: 16),
                            _CategoryList(byCategory: txns.byCategory, total: txns.totalSpend),
                          ],

                          // Family members
                          if (family.members.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _SectionHeader('Family Members'),
                            const SizedBox(height: 12),
                            ...family.members.map((m) => _MemberCard(member: m)),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(BuildContext context, String userName, FamilyProvider family) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      pinned: false,
      leading: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hey, ${userName.split(' ').first} 👋',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        if (family.hasFamily)
          Text(family.family!.name,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                fontWeight: FontWeight.w400)),
      ]),
      actions: [
        GestureDetector(
          onTap: () async {
            await family.refresh();
            await _loadData();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }
}

// ── Hero balance card ──────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double income, spend;
  const _HeroCard({required this.income, required this.spend});

  @override
  Widget build(BuildContext context) {
    final net = income - spend;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0F1724)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.15),
          blurRadius: 30, offset: const Offset(0, 10),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Net Balance', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          formatCurrency(net),
          style: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w800,
            color: net >= 0 ? AppColors.success : AppColors.danger,
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _BalanceItem(
            label: 'Income',
            value: formatCurrency(income),
            color: AppColors.success,
            icon: Icons.arrow_downward_rounded,
          )),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _BalanceItem(
            label: 'Spending',
            value: formatCurrency(spend),
            color: AppColors.danger,
            icon: Icons.arrow_upward_rounded,
          )),
        ]),
      ]),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _BalanceItem({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          color: color, fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ── Mini stat cards ────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(
          fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary),
  );
}

// ── Chart container card ────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

// ── Category breakdown list ────────────────────────────────────
class _CategoryList extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  const _CategoryList({required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: sorted.take(6).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = total > 0 ? e.value / total : 0.0;
          final color = AppColors.categoryColors[e.key] ?? AppColors.textSecondary;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(children: [
                  Text(AppConstants.categoryEmojis[e.key] ?? '📦',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(AppConstants.categoryLabels[e.key] ?? e.key,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                        Text(formatCurrency(e.value),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      ]),
                      const SizedBox(height: 6),
                      Stack(children: [
                        Container(height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            )),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
              if (i < sorted.take(6).length - 1)
                Divider(height: 1, color: AppColors.border.withOpacity(0.5),
                    indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── No family banner ────────────────────────────────────────────
class _NoFamilyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: const Row(children: [
      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
      SizedBox(width: 12),
      Expanded(
        child: Text('Create or join a family to start tracking finances.',
          style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
      ),
    ]),
  );
}

// ── Member card ─────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final dynamic member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundImage: member.picture != null ? NetworkImage(member.picture) : null,
        backgroundColor: AppColors.primary,
        child: member.picture == null
            ? Text(member.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
            : null,
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(member.name, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(member.email, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: member.isAdmin
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: member.isAdmin
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Text(
          member.role.toUpperCase(),
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: member.isAdmin ? AppColors.primaryLight : AppColors.textSecondary,
          ),
        ),
      ),
    ]),
  );
}
