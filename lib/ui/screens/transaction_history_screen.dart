import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.transactions.isEmpty) {
            return Center(
              child: Text('No transactions yet.', style: Theme.of(context).textTheme.bodyMedium),
            );
          }

          return ListView.builder(
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final tx = provider.transactions[index];
              final cat = provider.categories.firstWhere(
                (c) => c.id == tx.categoryId, 
                orElse: () => provider.categories.isNotEmpty ? provider.categories.first : throw Exception('No cat')
              );
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.surface,
                  child: Icon(Icons.receipt_long, color: AppTheme.accent),
                ),
                title: Text(tx.description.isNotEmpty ? tx.description : cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                trailing: Text(
                  '-\$${tx.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final provider = context.read<BudgetProvider>();
    
    if (provider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a category first.')));
      return;
    }

    String selectedCategoryId = provider.categories.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Transaction'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', filled: true),
                  items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => selectedCategoryId = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (\$)', filled: true)),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', filled: true)),
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                provider.addTransaction(selectedCategoryId, double.parse(amountCtrl.text), descCtrl.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            child: const Text('Save'),
          )
        ],
      )
    );
  }
}
