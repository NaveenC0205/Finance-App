import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/transaction_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/drawer/app_drawer.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
    _scrollCtrl.addListener(_onScroll);
  }

  void _loadFirst() {
    final family = context.read<FamilyProvider>();
    context.read<TransactionProvider>().loadTransactions(family.allAccountIds, refresh: true);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final family = context.read<FamilyProvider>();
      context.read<TransactionProvider>().loadTransactions(family.allAccountIds);
    }
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final txns = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: _showFilters),
          if (txns.filterCategory != null || txns.filterType != null)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: AppColors.danger),
              onPressed: () {
                context.read<TransactionProvider>().clearFilters();
                _loadFirst();
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(children: [
        // Summary bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _SummaryChip(label: 'Debit', value: formatCurrency(txns.totalSpend), color: AppColors.danger),
            const SizedBox(width: 12),
            _SummaryChip(label: 'Credit', value: formatCurrency(txns.totalIncome), color: AppColors.success),
            const Spacer(),
            Text('${txns.transactions.length} txns', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const Divider(height: 1),

        Expanded(
          child: txns.transactions.isEmpty && txns.loading
              ? const Center(child: CircularProgressIndicator())
              : txns.transactions.isEmpty
                  ? const Center(child: Text('No transactions found', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: txns.transactions.length + (txns.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) {
                        if (i >= txns.transactions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _TransactionTile(txn: txns.transactions[i]);
                      },
                    ),
        ),
      ]),
    );
  }

  void _showFilters() {
    final txns = context.read<TransactionProvider>();
    String? selectedCategory = txns.filterCategory;
    String? selectedType = txns.filterType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filter Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['all', 'debit', 'credit'].map((t) => FilterChip(
            label: Text(t.toUpperCase()),
            selected: selectedType == (t == 'all' ? null : t),
            onSelected: (_) => setModal(() => selectedType = t == 'all' ? null : t),
            selectedColor: AppColors.primaryLight,
          )).toList()),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['all', ...AppConstants.categories].map((c) => FilterChip(
            label: Text(c == 'all' ? 'All' : '${AppConstants.categoryEmojis[c]} ${AppConstants.categoryLabels[c]}'),
            selected: selectedCategory == (c == 'all' ? null : c),
            onSelected: (_) => setModal(() => selectedCategory = c == 'all' ? null : c),
            selectedColor: AppColors.primaryLight,
          )).toList()),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              txns.applyFilters(category: selectedCategory, type: selectedType);
              final family = context.read<FamilyProvider>();
              txns.loadTransactions(family.allAccountIds, refresh: true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Apply Filters'),
          ),
        ]),
      )),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  ]);
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[txn.category] ?? AppColors.textSecondary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(AppConstants.categoryEmojis[txn.category] ?? '📦', style: const TextStyle(fontSize: 20))),
      ),
      title: Text(
        txn.merchant ?? txn.description,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        maxLines: 1, overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(AppConstants.categoryLabels[txn.category] ?? txn.category,
            style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 6),
        Text(formatDate(txn.date), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ]),
      trailing: Text(
        txn.amountDisplay,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txn.typeColor),
      ),
    );
  }
}
