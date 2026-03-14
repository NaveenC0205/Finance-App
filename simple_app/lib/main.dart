import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'models/transaction.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const FamilyExpenseApp());
}

class FamilyExpenseApp extends StatelessWidget {
  const FamilyExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Expense Tracker',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purpleAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purpleAccent,
          secondary: Colors.cyanAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _selectedProfile = 'Family';
  final List<String> _profiles = ['Family', 'Father', 'Mother', 'Son', 'Daughter'];
  
  List<Transaction> _transactions = [];
  final StorageService _storageService = StorageService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txs = await _storageService.loadTransactions();
    setState(() {
      _transactions = txs;
      _isLoading = false;
    });
  }

  void _onUploadSuccess(List<Transaction> newTxs) {
    setState(() {
      _transactions.addAll(newTxs);
      _storageService.saveTransactions(_transactions);
      _currentIndex = 0; // go back to dashboard
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully parsed \${newTxs.length} transactions!')),
    );
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedProfile == 'Family') return _transactions;
    return _transactions.where((t) => t.person == _selectedProfile).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(transactions: _filteredTransactions, profile: _selectedProfile),
      UploadPage(onUploadSuccess: _onUploadSuccess, profiles: _profiles.where((p) => p != 'Family').toList()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProfile,
                dropdownColor: const Color(0xFF1E1E1E),
                icon: const Icon(Icons.person, color: Colors.purpleAccent),
                items: _profiles.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProfile = val);
                },
              ),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1E1E1E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// DASHBOARD PAGE
// ----------------------------------------------------
class DashboardPage extends StatelessWidget {
  final List<Transaction> transactions;
  final String profile;

  const DashboardPage({super.key, required this.transactions, required this.profile});

  double get _totalExpense => transactions
      .where((t) => t.type == 'Expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalIncome => transactions
      .where((t) => t.type == 'Income')
      .fold(0.0, (sum, t) => sum + t.amount);

  Map<String, double> get _expenseByCategory {
    final Map<String, double> map = {};
    for (var t in transactions.where((t) => t.type == 'Expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '\$');

    if (transactions.isEmpty) {
      return Center(
        child: Text('No transactions for \$profile.\\nGo to Upload to add statements.', 
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16)
        )
      );
    }

    final catData = _expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text('\$profile Overview', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Spent', currencyFmt.format(_totalExpense), Colors.redAccent),
                  _buildStat('Income', currencyFmt.format(_totalIncome), Colors.greenAccent),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Chart
        if (catData.isNotEmpty) ...[
          const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: catData.asMap().entries.map((e) {
                  final i = e.key;
                  final data = e.value;
                  final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.yellow];
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: data.value,
                    title: '\${(data.value / _totalExpense * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: catData.asMap().entries.map((e) {
              final i = e.key;
              final data = e.value;
              final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.yellow];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: colors[i % colors.length]),
                  const SizedBox(width: 4),
                  Text('\${data.key}: \${currencyFmt.format(data.value)}', style: const TextStyle(fontSize: 12))
                ],
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 32),
        // Text Insights
        if (catData.isNotEmpty) ...[
          const Text('AI Spending Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Most of the spending is on \${catData.first.key} (\${((catData.first.value / _totalExpense) * 100).toStringAsFixed(1)}%).',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (catData.length > 1) 
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Consider cutting back on \${catData[1].key} to increase savings.',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...transactions.take(10).map((t) => Card(
          color: const Color(0xFF1E1E1E),
          child: ListTile(
            title: Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('\${t.date} • \${t.person} • \${t.bank}'),
            trailing: Text(
              '\${t.type == "Income" ? "+" : "-"}\${currencyFmt.format(t.amount)}',
              style: TextStyle(
                color: t.type == 'Income' ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        )).toList(),
      ],
    );
  }

  Widget _buildStat(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ----------------------------------------------------
// UPLOAD PAGE
// ----------------------------------------------------
class UploadPage extends StatefulWidget {
  final Function(List<Transaction>) onUploadSuccess;
  final List<String> profiles;

  const UploadPage({super.key, required this.onUploadSuccess, required this.profiles});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ApiService _api = ApiService();
  bool _isUploading = false;
  String _selectedPerson = 'Father';
  String _bankName = '';

  Future<void> _pickAndUpload() async {
    if (_bankName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a bank name')));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'pdf', 'xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      
      try {
        File file = File(result.files.single.path!);
        final txs = await _api.uploadStatement(file, _selectedPerson, _bankName);
        widget.onUploadSuccess(txs);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: \$e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.purpleAccent),
          const SizedBox(height: 24),
          const Text('Upload Bank Statement', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Supports CSV, Excel, and PDF formats', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 48),
          
          DropdownButtonFormField<String>(
            value: _selectedPerson,
            decoration: const InputDecoration(labelText: 'Who does this belong to?', border: OutlineInputBorder()),
            items: widget.profiles.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _selectedPerson = v!),
          ),
          const SizedBox(height: 16),
          
          TextField(
            onChanged: (v) => _bankName = v,
            decoration: const InputDecoration(
              labelText: 'Bank Name (e.g. Chase, HDFC)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          _isUploading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.folder_open),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Select File & Upload', style: TextStyle(fontSize: 16)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
        ],
      ),
    );
  }
}
