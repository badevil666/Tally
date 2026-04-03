import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class AllocationScreen extends StatelessWidget {
  const AllocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          )
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unallocated', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('\$${provider.unallocated.toStringAsFixed(2)}', 
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Limit', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('\$${provider.totalAllocated.toStringAsFixed(2)}', 
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppTheme.accent)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.categories.isEmpty 
                  ? Center(child: Text('Add categories to allocate your budget.', style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                  itemCount: provider.categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Spent: \$${cat.spent} / Limit: \$${cat.limit}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.accent),
                          onPressed: () => _showEditCategoryDialog(context, cat.id, cat.name, cat.limit),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name', filled: true)),
            const SizedBox(height: 12),
            TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Limit (\$)', filled: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && limitCtrl.text.isNotEmpty) {
                context.read<BudgetProvider>().addCategory(nameCtrl.text, double.parse(limitCtrl.text));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            child: const Text('Add'),
          )
        ],
      )
    );
  }

  void _showEditCategoryDialog(BuildContext context, String id, String name, double currentLimit) {
    final limitCtrl = TextEditingController(text: currentLimit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Edit Limit - $name'),
        content: TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Limit (\$)', filled: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (limitCtrl.text.isNotEmpty) {
                context.read<BudgetProvider>().updateCategoryLimit(id, double.parse(limitCtrl.text));
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
