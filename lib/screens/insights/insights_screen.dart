import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/drawer/app_drawer.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txns = context.watch<TransactionProvider>();
    final byCategory = txns.byCategory;
    final totalSpend = txns.totalSpend;

    // Generate insights from current data
    final insights = generateInsights(byCategory, totalSpend, {});

    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights')),
      drawer: const AppDrawer(),
      body: insights.isEmpty
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.lightbulb_outline_rounded, size: 64, color: AppColors.textTertiary),
                SizedBox(height: 16),
                Text('No insights yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Upload bank statements to get AI-powered insights.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('This Month\'s Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Based on your family\'s spending',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ...insights.map((insight) => _InsightCard(insight: insight)),
                const SizedBox(height: 24),
                const Text('Spending Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (byCategory.isNotEmpty) ..._buildCategoryInsights(byCategory, totalSpend),
              ],
            ),
    );
  }

  List<Widget> _buildCategoryInsights(Map<String, double> byCategory, double total) {
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) {
      final pct = total > 0 ? (e.value / total * 100).round() : 0;
      final color = AppColors.categoryColors[e.key] ?? AppColors.textSecondary;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Text(AppConstants.categoryEmojis[e.key] ?? '📦', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppConstants.categoryLabels[e.key] ?? e.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$pct% of total spend', style: TextStyle(fontSize: 12, color: color)),
          ])),
          Text(formatCurrency(e.value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
    }).toList();
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _InsightCard({required this.insight});

  Color get _bgColor {
    return switch (insight['type']) {
      'warning' => const Color(0xFFFFFBEB),
      'positive' => const Color(0xFFF0FDF4),
      'alert' => const Color(0xFFFEF2F2),
      _ => const Color(0xFFEFF6FF),
    };
  }

  Color get _iconColor {
    return switch (insight['type']) {
      'warning' => AppColors.warning,
      'positive' => AppColors.success,
      'alert' => AppColors.danger,
      _ => AppColors.info,
    };
  }

  IconData get _icon {
    return switch (insight['type']) {
      'warning' => Icons.warning_amber_rounded,
      'positive' => Icons.thumb_up_rounded,
      'alert' => Icons.error_rounded,
      _ => Icons.lightbulb_rounded,
    };
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(14)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: _iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(_icon, color: _iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(insight['text'] as String,
        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary))),
    ]),
  );
}
