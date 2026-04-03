import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import 'package:isar/isar.dart';

class BudgetPlannerScreen extends StatelessWidget {
  const BudgetPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        bool isOverAllocated = provider.unallocated < 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Budget Planner'),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: isOverAllocated ? Border.all(color: AppTheme.error, width: 2) : null,
                  boxShadow: [
                    if (isOverAllocated) BoxShadow(color: AppTheme.error.withOpacity(0.3), blurRadius: 20)
                    else const BoxShadow(color: Colors.black12, blurRadius: 20)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining to Allocate', style: TextStyle(fontSize: 16)),
                    Text('${provider.currencySymbol}${provider.unallocated.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isOverAllocated ? AppTheme.error : AppTheme.success)),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSectionHeader('Fixed Bills'),
                    ...provider.categories.where((c) => c.type == CategoryType.fixed).map((c) => _buildCategoryTile(context, provider, c)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Lifestyle'),
                    ...provider.categories.where((c) => c.type == CategoryType.variable).map((c) => _buildCategoryTile(context, provider, c)),
                    const SizedBox(height: 80), // for FAB padding
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accent,
            onPressed: () => _showAddCategoryDialog(context),
            child: const Icon(Icons.add, color: Colors.black),
          ).animate().scale(delay: 500.ms),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
    );
  }

  Widget _buildCategoryTile(BuildContext context, BudgetProvider provider, CategoryModel cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Allocated: ${provider.currencySymbol}${cat.limit.toStringAsFixed(0)}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppTheme.accent),
          onPressed: () => _showEditCategoryDialog(context, provider, cat),
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    CategoryType selectedType = CategoryType.variable;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Bucket'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bucket Name')),
                const SizedBox(height: 12),
                TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Limit (${context.read<BudgetProvider>().currencySymbol})')),
                const SizedBox(height: 16),
                DropdownButtonFormField<CategoryType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Category Type'),
                  items: const [
                    DropdownMenuItem(value: CategoryType.fixed, child: Text('Fixed Bill')),
                    DropdownMenuItem(value: CategoryType.variable, child: Text('Lifestyle (Variable)')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && limitCtrl.text.isNotEmpty) {
                context.read<BudgetProvider>().addCategory(nameCtrl.text, double.parse(limitCtrl.text), selectedType);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      )
    );
  }

  void _showEditCategoryDialog(BuildContext context, BudgetProvider provider, CategoryModel cat) {
    final limitCtrl = TextEditingController(text: cat.limit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit ${cat.name} Limit'),
        content: TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'New Limit (${provider.currencySymbol})')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            onPressed: () {
              if (limitCtrl.text.isNotEmpty) {
                provider.updateCategoryLimit(cat.id, double.parse(limitCtrl.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }
}
