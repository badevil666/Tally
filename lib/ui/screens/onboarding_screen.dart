import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _incomeController = TextEditingController();
  double _savingsGoal = 0;
  double _income = 0;
  
  String _selectedCountry = 'United States';
  final Map<String, String> _countryCurrency = {
    'United States': '\$',
    'United Kingdom': '£',
    'Eurozone': '€',
    'India': '₹',
    'Japan': '¥',
    'Australia': 'A\$',
    'Canada': 'C\$',
    'Brazil': 'R\$',
  };

  void _save(BuildContext context) {
    if (_income > 0) {
      HapticFeedback.heavyImpact();
      String currency = _countryCurrency[_selectedCountry] ?? '\$';
      context.read<BudgetProvider>().setBudget(
        _income, 
        _savingsGoal,
        country: _selectedCountry,
        currencySymbol: currency,
      );
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    double leftToSpend = _income - _savingsGoal;
    String currency = _countryCurrency[_selectedCountry] ?? '\$';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Financial North Star',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: AppTheme.accent),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              Text(
                'Pay Yourself First',
                style: Theme.of(context).textTheme.bodyLarge,
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 32),
              
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country Location',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                dropdownColor: AppTheme.cardSurface,
                items: _countryCurrency.keys.map((String c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCountry = val!;
                  });
                },
              ).animate().fade(delay: 250.ms),
              const SizedBox(height: 24),
              
              TextField(
                controller: _incomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Monthly Income ($currency)',
                  labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() {
                    _income = double.tryParse(val) ?? 0;
                    if (_savingsGoal > _income) _savingsGoal = _income;
                  });
                },
              ).animate().fade(delay: 300.ms),
              const SizedBox(height: 32),
              
              Text('Savings Goal: $currency${_savingsGoal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18)).animate().fade(delay: 400.ms),
              Slider(
                value: _savingsGoal,
                min: 0,
                max: _income > 0 ? _income : 100,
                activeColor: AppTheme.accent,
                inactiveColor: AppTheme.cardSurface,
                onChanged: (val) {
                  setState(() {
                    _savingsGoal = val;
                  });
                  HapticFeedback.selectionClick();
                },
              ).animate().fade(delay: 450.ms),
              
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black12)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Income', style: Theme.of(context).textTheme.bodyMedium),
                        Text('$currency${_income.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('- Savings', style: Theme.of(context).textTheme.bodyMedium),
                        Text('$currency${_savingsGoal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, color: AppTheme.accent)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Left to Spend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('$currency${leftToSpend.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.success)),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 500.ms).scale(),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('Start My Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
