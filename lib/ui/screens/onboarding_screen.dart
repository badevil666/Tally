import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

IconData _catIcon(String name) {
  const map = <String, IconData>{
    'fastfood': Icons.fastfood, 'coffee': Icons.coffee,
    'restaurant': Icons.restaurant, 'local_pizza': Icons.local_pizza,
    'local_cafe': Icons.local_cafe, 'grocery': Icons.local_grocery_store,
    'ramen_dining': Icons.ramen_dining, 'lunch_dining': Icons.lunch_dining,
    'directions_car': Icons.directions_car, 'flight_takeoff': Icons.flight_takeoff,
    'train': Icons.train, 'directions_bus': Icons.directions_bus,
    'two_wheeler': Icons.two_wheeler, 'local_taxi': Icons.local_taxi,
    'home_work': Icons.home_work, 'bolt': Icons.bolt,
    'water_drop': Icons.water_drop, 'router': Icons.router,
    'gas_meter': Icons.gas_meter, 'plumbing': Icons.plumbing,
    'shopping_bag': Icons.shopping_bag, 'checkroom': Icons.checkroom,
    'local_hospital': Icons.local_hospital, 'medication': Icons.medication,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center, 'spa': Icons.spa,
    'movie': Icons.movie, 'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note, 'headphones': Icons.headphones,
    'payments': Icons.payments, 'account_balance': Icons.account_balance,
    'savings': Icons.savings, 'credit_card': Icons.credit_card,
    'smartphone': Icons.smartphone, 'laptop': Icons.laptop,
    'school': Icons.school, 'menu_book': Icons.menu_book,
    'subscriptions': Icons.subscriptions, 'attach_money': Icons.attach_money,
    'health_safety': Icons.health_and_safety, 'pets': Icons.pets,
    'child_care': Icons.child_care, 'category': Icons.category,
    'local_mall': Icons.local_mall, 'psychology': Icons.psychology,
    'directions_bike': Icons.directions_bike,
  };
  return map[name] ?? Icons.category;
}

Color _catColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length < 6) return Colors.white;
  final buf = StringBuffer();
  if (cleaned.length == 6) buf.write('ff');
  buf.write(cleaned);
  return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFE2E2E2);
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const int _totalSteps = 7;

  // Step 0
  String _country = 'India';
  static const Map<String, String> _countryCurrency = {
    'India': '₹',
    'United States': '\$',
    'United Kingdom': '£',
    'Eurozone': '€',
    'Australia': 'A\$',
    'Canada': 'C\$',
    'Japan': '¥',
    'Singapore': 'S\$',
    'UAE': 'د.إ',
    'Brazil': 'R\$',
    'South Korea': '₩',
    'Malaysia': 'RM',
    'Indonesia': 'Rp',
    'Thailand': '฿',
    'Pakistan': 'Rs',
    'Bangladesh': '৳',
    'Mexico': 'MX\$',
    'Switzerland': 'CHF',
    'Sweden': 'kr',
    'China': '¥',
  };

  // Step 1
  final _incomeCtrl = TextEditingController();
  double _income = 0;

  // Step 2
  double _savings = 0;
  final _savingsCtrl = TextEditingController();

  // Step 3: category selection
  Set<int>? _selectedCatIds; // null = not yet initialized

  // Steps 4-5
  final Map<int, TextEditingController> _limitCtrls = {};

  @override
  void dispose() {
    _pageCtrl.dispose();
    _incomeCtrl.dispose();
    _savingsCtrl.dispose();
    for (final c in _limitCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _step++);
    HapticFeedback.lightImpact();
  }

  void _prev() {
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _step--);
    HapticFeedback.lightImpact();
  }

  double _sumLimits(List<CategoryModel> cats) =>
      cats.fold(0.0, (s, c) => s + (double.tryParse(_limitCtrls[c.id]?.text ?? '') ?? 0));

  Future<void> _finish(BudgetProvider provider) async {
    final currency = _countryCurrency[_country] ?? '\$';
    await provider.setBudget(_income, _savings, country: _country, currencySymbol: currency);
    // Snapshot first — deleteCategory mutates the live _categories list,
    // so iterating provider.categories directly would skip entries.
    final selected = _selectedCatIds ?? {};
    final toDelete = provider.categories
        .where((c) => !c.isProtected && !selected.contains(c.id))
        .toList();
    for (final cat in toDelete) {
      await provider.deleteCategory(cat.id);
    }
    for (final entry in _limitCtrls.entries) {
      final limit = double.tryParse(entry.value.text) ?? 0;
      if (limit > 0) await provider.updateCategoryLimit(entry.key, limit);
    }
    HapticFeedback.heavyImpact();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final allFixedCats = provider.categories
            .where((c) => c.type == CategoryType.fixed && !c.isProtected)
            .toList();
        final allLifeCats = provider.categories
            .where((c) => c.type == CategoryType.variable && !c.isProtected)
            .toList();

        // Initialize to empty — user picks what they want
        _selectedCatIds ??= {};
        final selected = _selectedCatIds ?? {};

        // Only show selected categories in limit steps
        final fixedCats = allFixedCats.where((c) => selected.contains(c.id)).toList();
        final lifeCats = allLifeCats.where((c) => selected.contains(c.id)).toList();

        for (final cat in [...allFixedCats, ...allLifeCats]) {
          _limitCtrls.putIfAbsent(cat.id, () => TextEditingController());
        }

        final currency = _countryCurrency[_country] ?? '\$';
        final totalFixed = _sumLimits(fixedCats);
        final totalLife = _sumLimits(lifeCats);
        final remaining = _income - _savings - totalFixed - totalLife;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCountryStep(currency),
                      _buildIncomeStep(currency),
                      _buildSavingsStep(currency),
                      _buildCategorySelectionStep(allFixedCats, allLifeCats),
                      _buildLimitsStep(
                        title: 'Fixed Bills',
                        subtitle: 'Set your recurring monthly expenses',
                        cats: fixedCats,
                        currency: currency,
                        spendable: _income - _savings,
                        totalAllocated: totalFixed + totalLife,
                      ),
                      _buildLimitsStep(
                        title: 'Lifestyle Budget',
                        subtitle: 'How much do you plan to spend on each?',
                        cats: lifeCats,
                        currency: currency,
                        spendable: _income - _savings,
                        totalAllocated: totalFixed + totalLife,
                      ),
                      _buildSummaryStep(provider, currency, totalFixed, totalLife, remaining),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Progress bar ────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step ${_step + 1} of $_totalSteps',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _totalSteps,
              backgroundColor: AppTheme.cardSurface,
              color: AppTheme.accent,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Country ─────────────────────────────────────────────────────────

  Widget _buildCountryStep(String currency) {
    return _Page(
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.public, size: 64, color: AppTheme.accent)
              .animate().scale(duration: 400.ms),
          const SizedBox(height: 24),
          const Text('Where are you based?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center)
              .animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text("We'll use this to set your currency",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center)
              .animate().fade(delay: 200.ms),
          const SizedBox(height: 36),
          DropdownButtonFormField<String>(
            value: _country,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.cardSurface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            dropdownColor: AppTheme.cardSurface,
            items: _countryCurrency.keys
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _country = val!),
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_exchange, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Text('Currency: $currency',
                    style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ],
            ),
          ).animate().fade(delay: 350.ms),
          const Spacer(),
          _NavBtn(label: 'Continue', onTap: _next),
        ],
      ),
    );
  }

  // ── Step 1: Income ──────────────────────────────────────────────────────────

  Widget _buildIncomeStep(String currency) {
    return _Page(
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.account_balance_wallet, size: 64, color: AppTheme.success)
              .animate().scale(duration: 400.ms),
          const SizedBox(height: 24),
          const Text("What's your monthly income?",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center)
              .animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text('Include salary, freelance, and all sources',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center)
              .animate().fade(delay: 200.ms),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _income > 0 ? AppTheme.success : Colors.white12),
            ),
            child: Row(
              children: [
                Text(currency,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _incomeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        setState(() => _income = double.tryParse(val) ?? 0),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 300.ms),
          const Spacer(),
          Row(children: [
            _NavBtn(label: 'Back', onTap: _prev, secondary: true),
            const SizedBox(width: 12),
            Expanded(child: _NavBtn(label: 'Continue', onTap: _income > 0 ? _next : null)),
          ]),
        ],
      ),
    );
  }

  // ── Step 2: Savings goal ────────────────────────────────────────────────────

  Widget _buildSavingsStep(String currency) {
    final pct = _income > 0 ? (_savings / _income * 100).round() : 0;
    final double maxSavings = _income > 0 ? _income * 0.8 : 100.0;

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Center(
              child: Icon(Icons.savings, size: 64, color: AppTheme.accent))
              .animate().scale(duration: 400.ms),
          const SizedBox(height: 24),
          const Center(
            child: Text('How much would you like to save?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 32),
          // Editable amount + percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _savings > 0 ? AppTheme.accent : Colors.white12),
            ),
            child: Row(
              children: [
                Text(currency,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _savingsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val) ?? 0.0;
                      setState(() {
                        _savings = v.clamp(0.0, maxSavings);
                      });
                    },
                  ),
                ),
                Text('$pct%',
                    style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ).animate().fade(delay: 200.ms),
          const SizedBox(height: 16),
          Slider(
            value: _savings.clamp(0.0, maxSavings),
            min: 0.0,
            max: maxSavings,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.cardSurface,
            onChanged: (v) {
              final rounded = v.roundToDouble();
              setState(() => _savings = rounded);
              // Sync text field only if user is using the slider
              final newText = rounded.toStringAsFixed(0);
              if (_savingsCtrl.text != newText) {
                _savingsCtrl.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                );
              }
              HapticFeedback.selectionClick();
            },
          ).animate().fade(delay: 250.ms),
          const SizedBox(height: 8),
          // Quick-pick buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [10, 20, 30].map((p) {
              final val = (_income * p / 100).roundToDouble();
              final sel = (_savings - val).abs() < 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _savings = val);
                    final newText = val.toStringAsFixed(0);
                    _savingsCtrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppTheme.accent : Colors.transparent),
                    ),
                    child: Text('$p%',
                        style: TextStyle(
                          color: sel ? AppTheme.accent : AppTheme.textMuted,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ).animate().fade(delay: 300.ms),
          const Spacer(),
          Row(children: [
            _NavBtn(label: 'Back', onTap: _prev, secondary: true),
            const SizedBox(width: 12),
            Expanded(child: _NavBtn(label: 'Continue', onTap: _next)),
          ]),
        ],
      ),
    );
  }

  // ── Step 3: Category selection ──────────────────────────────────────────────

  Widget _buildCategorySelectionStep(
      List<CategoryModel> allFixedCats, List<CategoryModel> allLifeCats) {
    final selected = _selectedCatIds ?? {};
    final totalSelected = selected.length;

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Center(
              child: Icon(Icons.grid_view_rounded,
                  size: 52, color: AppTheme.accentBlue))
              .animate().scale(duration: 400.ms),
          const SizedBox(height: 14),
          const Center(
            child: Text('Pick Your Categories',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ).animate().fade(delay: 100.ms),
          const SizedBox(height: 6),
          Center(
            child: Text(
                '$totalSelected selected · tap to toggle',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
          ).animate().fade(delay: 150.ms),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectableCatSection(
                    title: 'Fixed Bills',
                    icon: Icons.receipt_long,
                    cats: allFixedCats,
                    selectedIds: selected,
                    onToggle: (id) => setState(() {
                      if (selected.contains(id)) {
                        _selectedCatIds!.remove(id);
                      } else {
                        _selectedCatIds!.add(id);
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  _SelectableCatSection(
                    title: 'Lifestyle',
                    icon: Icons.local_activity,
                    cats: allLifeCats,
                    selectedIds: selected,
                    onToggle: (id) => setState(() {
                      if (selected.contains(id)) {
                        _selectedCatIds!.remove(id);
                      } else {
                        _selectedCatIds!.add(id);
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
          Row(children: [
            _NavBtn(label: 'Back', onTap: _prev, secondary: true),
            const SizedBox(width: 12),
            Expanded(
              child: _NavBtn(
                label: 'Set Limits',
                onTap: totalSelected > 0 ? _next : null,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Steps 4 & 5: Limit setting ──────────────────────────────────────────────

  Widget _buildLimitsStep({
    required String title,
    required String subtitle,
    required List<CategoryModel> cats,
    required String currency,
    required double spendable,
    required double totalAllocated,
  }) {
    final leftover = spendable - totalAllocated;
    final allocPct = spendable > 0 ? (totalAllocated / spendable).clamp(0.0, 1.0) : 0.0;
    final leftoverColor = leftover < 0
        ? AppTheme.error
        : leftover < spendable * 0.1
            ? AppTheme.accent
            : AppTheme.success;

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Balance hero ─────────────────────────────────────────────────
          // ValueKey forces Flutter to reconcile this widget when leftover changes
          // inside the PageView, ensuring live updates as the user types.
          KeyedSubtree(
            key: ValueKey('balance_$leftover'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: leftoverColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: leftoverColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leftover < 0 ? 'Over by' : 'Left to allocate',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency${leftover.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      color: leftoverColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: allocPct,
                      backgroundColor: Colors.white10,
                      color: leftoverColor,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$currency${totalAllocated.toStringAsFixed(0)} allocated  ·  $currency${spendable.toStringAsFixed(0)} spendable',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 10),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                final color = _catColor(cat.colorHex);
                final ctrl = _limitCtrls[cat.id] ?? TextEditingController();
                return _LimitTile(
                  cat: cat,
                  color: color,
                  ctrl: ctrl,
                  currency: currency,
                  onChanged: () => setState(() {}),
                ).animate().fade(delay: (i * 40).ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                );
              },
            ),
          ),
          Row(children: [
            _NavBtn(label: 'Back', onTap: _prev, secondary: true),
            const SizedBox(width: 12),
            Expanded(child: _NavBtn(label: 'Continue', onTap: _next)),
          ]),
        ],
      ),
    );
  }

  // ── Step 6: Summary ─────────────────────────────────────────────────────────

  Widget _buildSummaryStep(BudgetProvider provider, String currency,
      double totalFixed, double totalLife, double remaining) {
    return _Page(
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.check_circle, size: 72, color: AppTheme.success)
              .animate().scale(duration: 500.ms),
          const SizedBox(height: 20),
          const Text('Your Budget is Ready!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center)
              .animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text("Here's where your money goes each month",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center)
              .animate().fade(delay: 200.ms),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Monthly Income',
                    value: '$currency${_income.toStringAsFixed(0)}',
                    color: AppTheme.success)
                    .animate().fade(delay: 300.ms),
                _SummaryRow(
                    label: 'Savings',
                    value: '- $currency${_savings.toStringAsFixed(0)}',
                    color: AppTheme.accent,
                    indent: true)
                    .animate().fade(delay: 400.ms),
                _SummaryRow(
                    label: 'Fixed Bills',
                    value: '- $currency${totalFixed.toStringAsFixed(0)}',
                    color: AppTheme.accentBlue,
                    indent: true)
                    .animate().fade(delay: 500.ms),
                _SummaryRow(
                    label: 'Lifestyle',
                    value: '- $currency${totalLife.toStringAsFixed(0)}',
                    color: Colors.orangeAccent,
                    indent: true)
                    .animate().fade(delay: 600.ms),
                const Divider(color: Colors.white24, height: 28),
                _SummaryRow(
                    label: 'Left to Spend',
                    value: '$currency${remaining.toStringAsFixed(0)}',
                    color: remaining >= 0 ? AppTheme.success : AppTheme.error,
                    bold: true)
                    .animate().fade(delay: 700.ms),
              ],
            ),
          ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
          const Spacer(),
          Row(children: [
            _NavBtn(label: 'Back', onTap: _prev, secondary: true),
            const SizedBox(width: 12),
            Expanded(
                child: _NavBtn(
                    label: 'Get Started',
                    onTap: () => _finish(provider),
                    primary: true)),
          ]),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _Page extends StatelessWidget {
  final Widget child;
  const _Page({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: child,
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final bool primary;

  const _NavBtn({
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMuted,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            onTap == null ? AppTheme.cardSurface : AppTheme.accent,
        foregroundColor: onTap == null ? AppTheme.textMuted : Colors.black,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool indent;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.indent = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: indent ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: indent ? AppTheme.textMuted : AppTheme.textLight,
                fontSize: bold ? 17 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: bold ? 24 : 14,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class _LimitTile extends StatefulWidget {
  final CategoryModel cat;
  final Color color;
  final TextEditingController ctrl;
  final String currency;
  final VoidCallback onChanged;

  const _LimitTile({
    required this.cat,
    required this.color,
    required this.ctrl,
    required this.currency,
    required this.onChanged,
  });

  @override
  State<_LimitTile> createState() => _LimitTileState();
}

class _LimitTileState extends State<_LimitTile> {
  bool _editing = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _editing = false);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final hasValue = (double.tryParse(widget.ctrl.text) ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        setState(() => _editing = true);
        _focus.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _editing
                ? color
                : hasValue
                    ? color.withValues(alpha: 0.4)
                    : Colors.white10,
            width: _editing ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_catIcon(widget.cat.icon), color: color, size: 18),
            ),
            const SizedBox(height: 6),
            // Amount field or placeholder
            _editing
                ? SizedBox(
                    width: 72,
                    child: TextField(
                      controller: widget.ctrl,
                      focusNode: _focus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        prefixText: '${widget.currency} ',
                        prefixStyle: TextStyle(fontSize: 11, color: color),
                      ),
                      onChanged: (_) => widget.onChanged(),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasValue
                            ? '${widget.currency}${widget.ctrl.text}'
                            : '0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasValue ? color : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit,
                          size: 11,
                          color: hasValue ? color : AppTheme.textMuted),
                    ],
                  ),
            const SizedBox(height: 4),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.cat.name,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableCatSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<CategoryModel> cats;
  final Set<int> selectedIds;
  final void Function(int id) onToggle;

  const _SelectableCatSection({
    required this.title,
    required this.icon,
    required this.cats,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((cat) {
            final color = _catColor(cat.colorHex);
            final isSelected = selectedIds.contains(cat.id);
            return GestureDetector(
              onTap: () => onToggle(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.7)
                        : Colors.white12,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_catIcon(cat.icon),
                        size: 13,
                        color: isSelected ? color : AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(cat.name,
                        style: TextStyle(
                            color: isSelected ? color : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle,
                          size: 12, color: color.withValues(alpha: 0.8)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
