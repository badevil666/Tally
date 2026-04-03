import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';

class QuickAddIncomeModal extends StatefulWidget {
  const QuickAddIncomeModal({super.key});

  @override
  State<QuickAddIncomeModal> createState() => _QuickAddIncomeModalState();
}

class _QuickAddIncomeModalState extends State<QuickAddIncomeModal> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  final List<String> _sources = ['Salary', 'Bonus', 'Gift', 'Other'];
  String _selectedSource = 'Salary';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppTheme.success, width: 2)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Income', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.success)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.success),
            decoration: InputDecoration(
              prefixText: '${provider.currencySymbol} ',
              prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              border: InputBorder.none,
              hintText: '0',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sources.length,
              itemBuilder: (context, index) {
                final source = _sources[index];
                bool isSelected = _selectedSource == source;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSource = source);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.success : AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        source,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'What was this for?',
              filled: true,
              fillColor: AppTheme.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_amountCtrl.text.isNotEmpty) {
                HapticFeedback.heavyImpact();
                provider.addInflow(double.parse(_amountCtrl.text), _noteCtrl.text, _selectedSource);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Save Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
