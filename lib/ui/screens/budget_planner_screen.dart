import 'dart:math';
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
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Income & Savings',
                onPressed: () => _showEditBudgetSheet(context, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              _AllocationHeroCard(provider: provider)
                  .animate().fade(duration: 400.ms).slideY(begin: -0.15, end: 0),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSectionHeader('Lifestyle'),
                    _buildCategoryGrid(context, provider, CategoryType.variable),
                    const SizedBox(height: 12),
                    _buildSectionHeader('Fixed Bills'),
                    _buildCategoryGrid(context, provider, CategoryType.fixed),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton(
              backgroundColor: AppTheme.accent,
              onPressed: () => _showAddCategoryDialog(context),
              child: const Icon(Icons.add, color: Colors.black),
            ).animate().scale(delay: 500.ms),
          ),
        );
      },
    );
  }

  void _showEditBudgetSheet(BuildContext context, BudgetProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBudgetSheet(provider: provider),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, BudgetProvider provider, CategoryType type) {
    final cats = provider.categories.where((c) => c.type == type).toList()
      ..sort((a, b) => b.limit.compareTo(a.limit));
    if (cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('No categories yet', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      const cols = 3;
      const spacing = 10.0;
      final itemW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cats.map((cat) => SizedBox(
          width: itemW,
          height: itemW / 0.85,
          child: _buildCategorySquare(context, provider, cat),
        )).toList(),
      );
    });
  }

  Widget _buildCategorySquare(BuildContext context, BudgetProvider provider, CategoryModel cat) {
    final color = _hexToColor(cat.colorHex);
    final iconData = _iconFromName(cat.icon);

    return GestureDetector(
      onTap: () => _showEditCategoryDialog(context, provider, cat),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              cat.limit > 0 ? '${provider.currencySymbol}${cat.limit.toStringAsFixed(0)}' : 'No limit',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                cat.name,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.isEmpty) return Colors.white;
    final buf = StringBuffer();
    if (cleaned.length == 6) buf.write('ff');
    buf.write(cleaned);
    return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFE2E2E2);
  }

  IconData _iconFromName(String name) {
    const map = <String, IconData>{
      'fastfood': Icons.fastfood, 'coffee': Icons.coffee,
      'local_pizza': Icons.local_pizza, 'local_bar': Icons.local_bar,
      'cake': Icons.cake, 'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe, 'grocery': Icons.local_grocery_store,
      'ramen_dining': Icons.ramen_dining, 'lunch_dining': Icons.lunch_dining,
      'directions_car': Icons.directions_car, 'flight_takeoff': Icons.flight_takeoff,
      'train': Icons.train, 'directions_bus': Icons.directions_bus,
      'two_wheeler': Icons.two_wheeler, 'local_taxi': Icons.local_taxi,
      'pedal_bike': Icons.pedal_bike, 'local_shipping': Icons.local_shipping,
      'subway': Icons.subway, 'boat': Icons.directions_boat,
      'home_work': Icons.home_work, 'bolt': Icons.bolt,
      'water_drop': Icons.water_drop, 'router': Icons.router,
      'gas_meter': Icons.gas_meter, 'plumbing': Icons.plumbing,
      'cleaning': Icons.cleaning_services, 'chair': Icons.chair,
      'yard': Icons.yard, 'microwave': Icons.microwave,
      'shopping_bag': Icons.shopping_bag, 'checkroom': Icons.checkroom,
      'diamond': Icons.diamond, 'watch': Icons.watch,
      'storefront': Icons.storefront, 'redeem': Icons.redeem,
      'local_mall': Icons.local_mall, 'sell': Icons.sell,
      'style': Icons.style, 'dry_cleaning': Icons.dry_cleaning,
      'local_hospital': Icons.local_hospital, 'medication': Icons.medication,
      'fitness_center': Icons.fitness_center, 'spa': Icons.spa,
      'psychology': Icons.psychology, 'health_safety': Icons.health_and_safety,
      'medical_services': Icons.medical_services, 'vaccines': Icons.vaccines,
      'monitor_heart': Icons.monitor_heart, 'self_improvement': Icons.self_improvement,
      'movie': Icons.movie, 'sports_esports': Icons.sports_esports,
      'music_note': Icons.music_note, 'headphones': Icons.headphones,
      'sports_soccer': Icons.sports_soccer, 'sports_cricket': Icons.sports_cricket,
      'sports_basketball': Icons.sports_basketball, 'beach_access': Icons.beach_access,
      'hiking': Icons.hiking, 'camera_alt': Icons.camera_alt,
      'theater_comedy': Icons.theater_comedy, 'casino': Icons.casino,
      'payments': Icons.payments, 'account_balance': Icons.account_balance,
      'savings': Icons.savings, 'credit_card': Icons.credit_card,
      'trending_up': Icons.trending_up, 'attach_money': Icons.attach_money,
      'receipt': Icons.receipt, 'subscriptions': Icons.subscriptions,
      'currency_rupee': Icons.currency_rupee, 'price_check': Icons.price_check,
      'business': Icons.business, 'work': Icons.work,
      'laptop': Icons.laptop, 'print': Icons.print,
      'smartphone': Icons.smartphone, 'headset_mic': Icons.headset_mic,
      'cloud': Icons.cloud, 'memory': Icons.memory,
      'code': Icons.code, 'design_services': Icons.design_services,
      'school': Icons.school, 'menu_book': Icons.menu_book,
      'science': Icons.science, 'architecture': Icons.architecture,
      'calculate': Icons.calculate, 'history_edu': Icons.history_edu,
      'biotech': Icons.biotech, 'palette': Icons.palette,
      'pets': Icons.pets, 'child_care': Icons.child_care,
      'volunteer': Icons.volunteer_activism, 'church': Icons.church,
      'star': Icons.star, 'favorite': Icons.favorite,
      'travel_explore': Icons.travel_explore, 'celebration': Icons.celebration,
      'card_giftcard': Icons.card_giftcard, 'category': Icons.category,
      'family_restroom': Icons.family_restroom,
    };
    return map[name] ?? Icons.category;
  }


  void _showAddCategoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCategorySheet(currencySymbol: context.read<BudgetProvider>().currencySymbol),
    ).then((result) {
      if (result != null) {
        context.read<BudgetProvider>().addCategory(
          result['name'], result['limit'], result['type'],
          icon: result['icon'], colorHex: result['color'],
        );
      }
    });
  }

  void _showEditCategoryDialog(BuildContext context, BudgetProvider provider, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditCategorySheet(cat: cat, currencySymbol: provider.currencySymbol),
    ).then((result) {
      if (result == null) return;
      if (result['action'] == 'delete') {
        provider.deleteCategory(cat.id);
      } else {
        provider.updateCategory(
          cat.id,
          name: result['name'],
          limit: result['limit'],
          icon: result['icon'],
          colorHex: result['color'],
        );
      }
    });
  }
}

// ─── Edit Category Sheet ──────────────────────────────────────────────────────

class _EditCategorySheet extends StatefulWidget {
  final CategoryModel cat;
  final String currencySymbol;
  const _EditCategorySheet({required this.cat, required this.currencySymbol});

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _limitCtrl;
  late String _icon;
  late String _color;
  late TabController _tabCtrl;

  static const _colorOptions = [
    '#FFD3B6', '#A1C4FD', '#D4AF37', '#E2E2E2',
    '#8B94FF', '#FFEFBA', '#7EF9FF', '#B9FBC0',
    '#FFCFD2', '#FF8C69', '#C3B1E1', '#90EE90',
    '#FFB347', '#87CEEB', '#FF6B6B', '#98FF98',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cat.name);
    _limitCtrl = TextEditingController(
      text: widget.cat.limit > 0 ? widget.cat.limit.toStringAsFixed(0) : '',
    );
    _icon = widget.cat.icon.isNotEmpty ? widget.cat.icon : 'category';
    _color = widget.cat.colorHex.isNotEmpty ? widget.cat.colorHex : '#E2E2E2';
    _tabCtrl = TabController(length: _iconGroups.length, vsync: this);
    // Jump to the tab that contains the current icon
    final groupKeys = _iconGroups.keys.toList();
    for (int i = 0; i < groupKeys.length; i++) {
      if (_iconGroups[groupKeys[i]]!.any((e) => e.$1 == _icon)) {
        _tabCtrl.index = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Color _hex(String h) {
    final cleaned = h.replaceFirst('#', '');
    if (cleaned.isEmpty) return Colors.white;
    final buf = StringBuffer();
    if (cleaned.length == 6) buf.write('ff');
    buf.write(cleaned);
    return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFE2E2E2);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hex(_color);
    final screenH = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: screenH * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header preview
            Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  _iconGroups.values.expand((e) => e)
                      .firstWhere((e) => e.$1 == _icon, orElse: () => ('', Icons.category)).$2,
                  color: accentColor, size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text('Edit Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),

            // Name + Limit row
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true, fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Limit',
                    prefixText: '${widget.currencySymbol} ',
                    filled: true, fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Color dots
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colorOptions.map((hex) {
                  final sel = _color == hex;
                  final c = _hex(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26, height: 26,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                        boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 5)] : [],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Icon tabs
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              dividerColor: Colors.white10,
              tabs: _iconGroups.keys.map((k) => Tab(text: k)).toList(),
            ),
            const SizedBox(height: 8),

            // Icon grid
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: _iconGroups.entries.map((entry) {
                  return GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    children: entry.value.map((opt) {
                      final sel = _icon == opt.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _icon = opt.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: sel ? accentColor.withValues(alpha: 0.2) : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? accentColor : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(opt.$2, size: 24,
                              color: sel ? accentColor : AppTheme.textMuted),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  Navigator.pop(context, {
                    'action': 'save',
                    'name': name.isNotEmpty ? name : widget.cat.name,
                    'limit': double.tryParse(_limitCtrl.text) ?? widget.cat.limit,
                    'icon': _icon,
                    'color': _color,
                  });
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            if (!widget.cat.isProtected) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Delete Category'),
                        content: const Text(
                          'All transactions in this category will be moved to "Other". This cannot be undone.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context, {'action': 'delete'});
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Icon groups ─────────────────────────────────────────────────────────────

const _iconGroups = <String, List<(String, IconData)>>{
  'Food': [
    ('fastfood', Icons.fastfood), ('coffee', Icons.coffee),
    ('restaurant', Icons.restaurant), ('local_pizza', Icons.local_pizza),
    ('local_cafe', Icons.local_cafe), ('local_bar', Icons.local_bar),
    ('cake', Icons.cake), ('grocery', Icons.local_grocery_store),
    ('ramen_dining', Icons.ramen_dining), ('lunch_dining', Icons.lunch_dining),
  ],
  'Transport': [
    ('directions_car', Icons.directions_car), ('flight_takeoff', Icons.flight_takeoff),
    ('train', Icons.train), ('directions_bus', Icons.directions_bus),
    ('two_wheeler', Icons.two_wheeler), ('local_taxi', Icons.local_taxi),
    ('pedal_bike', Icons.pedal_bike), ('local_shipping', Icons.local_shipping),
    ('subway', Icons.subway), ('boat', Icons.directions_boat),
  ],
  'Home': [
    ('home_work', Icons.home_work), ('bolt', Icons.bolt),
    ('water_drop', Icons.water_drop), ('router', Icons.router),
    ('gas_meter', Icons.gas_meter), ('plumbing', Icons.plumbing),
    ('cleaning', Icons.cleaning_services), ('chair', Icons.chair),
    ('yard', Icons.yard), ('microwave', Icons.microwave),
  ],
  'Shopping': [
    ('shopping_bag', Icons.shopping_bag), ('checkroom', Icons.checkroom),
    ('diamond', Icons.diamond), ('watch', Icons.watch),
    ('storefront', Icons.storefront), ('redeem', Icons.redeem),
    ('local_mall', Icons.local_mall), ('sell', Icons.sell),
    ('style', Icons.style), ('dry_cleaning', Icons.dry_cleaning),
  ],
  'Health': [
    ('local_hospital', Icons.local_hospital), ('medication', Icons.medication),
    ('fitness_center', Icons.fitness_center), ('spa', Icons.spa),
    ('psychology', Icons.psychology), ('health_safety', Icons.health_and_safety),
    ('medical_services', Icons.medical_services), ('vaccines', Icons.vaccines),
    ('monitor_heart', Icons.monitor_heart), ('self_improvement', Icons.self_improvement),
  ],
  'Fun': [
    ('movie', Icons.movie), ('sports_esports', Icons.sports_esports),
    ('music_note', Icons.music_note), ('headphones', Icons.headphones),
    ('sports_soccer', Icons.sports_soccer), ('sports_cricket', Icons.sports_cricket),
    ('sports_basketball', Icons.sports_basketball), ('beach_access', Icons.beach_access),
    ('hiking', Icons.hiking), ('camera_alt', Icons.camera_alt),
    ('theater_comedy', Icons.theater_comedy), ('casino', Icons.casino),
  ],
  'Finance': [
    ('payments', Icons.payments), ('account_balance', Icons.account_balance),
    ('savings', Icons.savings), ('credit_card', Icons.credit_card),
    ('trending_up', Icons.trending_up), ('attach_money', Icons.attach_money),
    ('receipt', Icons.receipt), ('subscriptions', Icons.subscriptions),
    ('currency_rupee', Icons.currency_rupee), ('price_check', Icons.price_check),
  ],
  'Work': [
    ('business', Icons.business), ('work', Icons.work),
    ('laptop', Icons.laptop), ('print', Icons.print),
    ('smartphone', Icons.smartphone), ('headset_mic', Icons.headset_mic),
    ('cloud', Icons.cloud), ('memory', Icons.memory),
    ('code', Icons.code), ('design_services', Icons.design_services),
  ],
  'Education': [
    ('school', Icons.school), ('menu_book', Icons.menu_book),
    ('science', Icons.science), ('architecture', Icons.architecture),
    ('calculate', Icons.calculate), ('history_edu', Icons.history_edu),
    ('biotech', Icons.biotech), ('palette', Icons.palette),
  ],
  'Other': [
    ('pets', Icons.pets), ('child_care', Icons.child_care),
    ('volunteer', Icons.volunteer_activism), ('church', Icons.church),
    ('star', Icons.star), ('favorite', Icons.favorite),
    ('travel_explore', Icons.travel_explore), ('celebration', Icons.celebration),
    ('card_giftcard', Icons.card_giftcard), ('category', Icons.category),
  ],
};

// ─── Add Category Sheet ───────────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  final String currencySymbol;
  const _AddCategorySheet({required this.currencySymbol});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  CategoryType _type = CategoryType.variable;
  String _icon = 'fastfood';
  String _color = '#FFD3B6';
  late TabController _tabCtrl;

  static const _colorOptions = [
    '#FFD3B6', '#A1C4FD', '#D4AF37', '#E2E2E2',
    '#8B94FF', '#FFEFBA', '#7EF9FF', '#B9FBC0',
    '#FFCFD2', '#FF8C69', '#C3B1E1', '#90EE90',
    '#FFB347', '#87CEEB', '#FF6B6B', '#98FF98',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _iconGroups.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Color _hex(String h) {
    final cleaned = h.replaceFirst('#', '');
    if (cleaned.isEmpty) return Colors.white;
    final buf = StringBuffer();
    if (cleaned.length == 6) buf.write('ff');
    buf.write(cleaned);
    return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFE2E2E2);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _hex(_color);
    final screenH = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: screenH * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header row with preview
            Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withOpacity(0.5)),
                ),
                child: Icon(_iconGroups.values.expand((e) => e)
                    .firstWhere((e) => e.$1 == _icon, orElse: () => ('', Icons.category)).$2,
                    color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              const Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),

            // Name + Limit row
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true, fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Limit',
                    prefixText: '${widget.currencySymbol} ',
                    filled: true, fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Type chips
            Row(children: [
              _TypeChip(label: 'Lifestyle', selected: _type == CategoryType.variable,
                  onTap: () => setState(() => _type = CategoryType.variable)),
              const SizedBox(width: 8),
              _TypeChip(label: 'Fixed Bill', selected: _type == CategoryType.fixed,
                  onTap: () => setState(() => _type = CategoryType.fixed)),
            ]),
            const SizedBox(height: 10),
            // Color dots
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colorOptions.map((hex) {
                  final sel = _color == hex;
                  final c = _hex(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26, height: 26,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                        boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 5)] : [],
                      ),
                    ),
                  );
                }).toList(),
                ),
              ),
            const SizedBox(height: 14),

            // Icon category tabs
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              dividerColor: Colors.white10,
              tabs: _iconGroups.keys.map((k) => Tab(text: k)).toList(),
            ),
            const SizedBox(height: 8),

            // Icon grid per tab
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: _iconGroups.entries.map((entry) {
                  return GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    children: entry.value.map((opt) {
                      final sel = _icon == opt.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _icon = opt.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: sel ? accentColor.withOpacity(0.2) : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? accentColor : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(opt.$2, size: 24,
                              color: sel ? accentColor : AppTheme.textMuted),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (_nameCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'name': _nameCtrl.text,
                      'limit': double.tryParse(_limitCtrl.text) ?? 0,
                      'type': _type,
                      'icon': _icon,
                      'color': _color,
                    });
                  }
                },
                child: const Text('Create Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.2) : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? AppTheme.accent : AppTheme.textMuted,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }
}

// ─── Allocation Hero Card ─────────────────────────────────────────────────────

class _AllocationHeroCard extends StatelessWidget {
  final BudgetProvider provider;
  const _AllocationHeroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final currency = provider.currencySymbol;
    final income = provider.totalMonthlyPool;
    final savings = provider.savingsGoal;
    final allocated = provider.totalAllocated;
    final spendable = income - savings;
    final unallocated = spendable - allocated;
    final isOver = unallocated < 0;
    final pct = spendable > 0 ? (allocated / spendable).clamp(0.0, 1.0) : 0.0;

    final heroColor = isOver
        ? AppTheme.error
        : pct > 0.9
            ? AppTheme.accent
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            heroColor.withValues(alpha: 0.18),
            heroColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: heroColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: heroColor.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Arc gauge ──────────────────────────────────────────────────
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _ArcGaugePainter(pct: pct, color: heroColor),
                child: Center(
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: TextStyle(
                      color: heroColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // ── Numbers ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOver ? 'Over-allocated' : 'Left to allocate',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency${unallocated.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      color: heroColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // breakdown
                  _Row(label: 'Income', value: '$currency${income.toStringAsFixed(0)}',
                      color: AppTheme.success),
                  const SizedBox(height: 4),
                  _Row(label: 'Savings goal',
                      value: '− $currency${savings.toStringAsFixed(0)}',
                      color: AppTheme.accent),
                  const SizedBox(height: 4),
                  _Row(label: 'Allocated',
                      value: '− $currency${allocated.toStringAsFixed(0)}',
                      color: AppTheme.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Row({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double pct;
  final Color color;
  const _ArcGaugePainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 7;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const strokeW = 7.0;
    const startAngle = -pi * 0.75;
    const sweepFull = pi * 1.5;

    // Track
    canvas.drawArc(
      rect,
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    if (pct > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepFull * pct,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.pct != pct || old.color != color;
}

// ── Edit Budget Sheet ─────────────────────────────────────────────────────────

class _EditBudgetSheet extends StatefulWidget {
  final BudgetProvider provider;
  const _EditBudgetSheet({required this.provider});

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
  late TextEditingController _incomeCtrl;
  late TextEditingController _savingsCtrl;
  String? _incomeError;
  String? _savingsError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _incomeCtrl = TextEditingController(
      text: p.totalIncome > 0 ? p.totalIncome.toStringAsFixed(0) : '',
    );
    _savingsCtrl = TextEditingController(
      text: p.savingsGoal > 0 ? p.savingsGoal.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _savingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', ''));
    final savings = double.tryParse(_savingsCtrl.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _incomeError = income == null || income <= 0 ? 'Enter a valid income' : null;
      _savingsError = income != null && savings >= income ? 'Must be less than income' : null;
    });
    if (_incomeError != null || _savingsError != null) return;
    setState(() => _saving = true);
    await widget.provider.setBudget(
      income!,
      savings,
      country: widget.provider.budget?.country ?? 'India',
      currencySymbol: widget.provider.currencySymbol,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.provider.currencySymbol;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(children: [
            const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            const Text('Edit Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 28),
          _Field(
            label: 'Monthly Income',
            controller: _incomeCtrl,
            prefix: currency,
            error: _incomeError,
            onChanged: (_) => setState(() => _incomeError = null),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Savings Goal',
            controller: _savingsCtrl,
            prefix: currency,
            error: _savingsError,
            onChanged: (_) => setState(() => _savingsError = null),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String prefix;
  final String? error;
  final void Function(String) onChanged;

  const _Field({
    required this.label,
    required this.controller,
    required this.prefix,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: InputDecoration(
            prefixText: '$prefix ',
            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.accent, width: 1.5)),
            filled: true,
            fillColor: AppTheme.cardSurface,
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
