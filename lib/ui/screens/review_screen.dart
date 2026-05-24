import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/quick_add_modal.dart' show AttachmentViewer;
import '../widgets/banner_ad_widget.dart';
import '../../services/ad_service.dart';

import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/inflow_model.dart';

void _showEditTransactionSheet(BuildContext context, BudgetProvider provider, TransactionModel tx) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditTransactionSheet(provider: provider, tx: tx),
  );
}

class _EditTransactionSheet extends StatefulWidget {
  final BudgetProvider provider;
  final TransactionModel tx;
  const _EditTransactionSheet({required this.provider, required this.tx});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late final TextEditingController _amountCtrl;
  int? _selectedCategoryId;
  late String _currentAttachmentPath;
  String? _newAttachmentPath; // picked but not yet saved
  bool _clearAttachment = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.tx.amount.toStringAsFixed(0));
    _selectedCategoryId = widget.tx.category.value?.id ?? (widget.provider.categories.isNotEmpty ? widget.provider.categories.first.id : null);
    _currentAttachmentPath = widget.tx.attachmentPath;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _newAttachmentPath = result.files.single.path;
        _clearAttachment = false;
      });
    }
  }

  String get _displayAttachmentPath => _newAttachmentPath ?? (_clearAttachment ? '' : _currentAttachmentPath);
  bool get _hasAttachment => _displayAttachmentPath.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isPdf = _displayAttachmentPath.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${provider.currencySymbol} ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.categories.map((cat) {
                final selected = cat.id == _selectedCategoryId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent.withOpacity(0.2) : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
                    ),
                    child: Text(cat.name, style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textLight,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Receipt section ──────────────────────────────────────────
            const Text('Receipt', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            if (_hasAttachment)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => AttachmentViewer.open(context, _displayAttachmentPath),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, size: 20, color: AppTheme.accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => AttachmentViewer.open(context, _displayAttachmentPath),
                    child: Text(
                      _newAttachmentPath != null ? 'New receipt selected' : 'View receipt',
                      style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  )),
                  GestureDetector(
                    onTap: () => setState(() { _newAttachmentPath = null; _clearAttachment = true; }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                    ),
                  ),
                ]),
              )
            else
              GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text('Attach receipt', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ]),
                ),
              ),
            if (_hasAttachment) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAttachment,
                child: const Text('Replace receipt', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final amount = double.tryParse(_amountCtrl.text);
                  if (amount != null && amount > 0 && _selectedCategoryId != null) {
                    provider.updateTransaction(
                      widget.tx.id, amount, _selectedCategoryId!,
                      newAttachmentSourcePath: _newAttachmentPath,
                      clearAttachment: _clearAttachment,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _searchCtrl = TextEditingController();
  bool _timelineView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) => _iconDataMap[name] ?? Icons.category;

  static const _iconDataMap = <String, IconData>{
    'fastfood': Icons.fastfood, 'coffee': Icons.coffee,
    'local_pizza': Icons.local_pizza, 'local_bar': Icons.local_bar,
    'cake': Icons.cake, 'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe, 'grocery': Icons.local_grocery_store,
    'directions_car': Icons.directions_car, 'flight_takeoff': Icons.flight_takeoff,
    'train': Icons.train, 'directions_bus': Icons.directions_bus,
    'two_wheeler': Icons.two_wheeler, 'local_taxi': Icons.local_taxi,
    'pedal_bike': Icons.pedal_bike, 'local_shipping': Icons.local_shipping,
    'home_work': Icons.home_work, 'bolt': Icons.bolt,
    'water_drop': Icons.water_drop, 'router': Icons.router,
    'gas_meter': Icons.gas_meter, 'plumbing': Icons.plumbing,
    'cleaning': Icons.cleaning_services, 'chair': Icons.chair,
    'shopping_bag': Icons.shopping_bag, 'checkroom': Icons.checkroom,
    'diamond': Icons.diamond, 'watch': Icons.watch,
    'storefront': Icons.storefront, 'redeem': Icons.redeem,
    'local_hospital': Icons.local_hospital, 'medication': Icons.medication,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center, 'spa': Icons.spa,
    'psychology': Icons.psychology, 'health_safety': Icons.health_and_safety,
    'movie': Icons.movie, 'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note, 'headphones': Icons.headphones,
    'sports_soccer': Icons.sports_soccer, 'sports_cricket': Icons.sports_cricket,
    'sports_basketball': Icons.sports_basketball, 'beach_access': Icons.beach_access,
    'hiking': Icons.hiking, 'camera_alt': Icons.camera_alt,
    'payments': Icons.payments, 'account_balance': Icons.account_balance,
    'savings': Icons.savings, 'credit_card': Icons.credit_card,
    'business': Icons.business, 'work': Icons.work,
    'laptop': Icons.laptop, 'print': Icons.print,
    'smartphone': Icons.smartphone, 'tablet': Icons.tablet,
    'tv': Icons.tv, 'headset_mic': Icons.headset_mic,
    'cloud': Icons.cloud, 'memory': Icons.memory,
    'school': Icons.school, 'menu_book': Icons.menu_book,
    'science': Icons.science, 'architecture': Icons.architecture,
    'pets': Icons.pets, 'child_care': Icons.child_care,
    'family_restroom': Icons.family_restroom, 'volunteer': Icons.volunteer_activism,
    'church': Icons.church, 'star': Icons.star,
    'favorite': Icons.favorite, 'travel_explore': Icons.travel_explore,
    'celebration': Icons.celebration, 'card_giftcard': Icons.card_giftcard,
    'subscriptions': Icons.subscriptions, 'attach_money': Icons.attach_money,
  };

  Color _fromHex(String hexString) {
    final cleaned = hexString.replaceFirst('#', '');
    if (cleaned.isEmpty) return Colors.white;
    final buffer = StringBuffer();
    if (cleaned.length == 6) buffer.write('ff');
    buffer.write(cleaned);
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFFE2E2E2);
  }

  Future<void> _exportCsv(BuildContext context, BudgetProvider provider) async {
    final inflows = provider.monthlyInflows;
    final txs = provider.monthlyTransactions;

    if (inflows.isEmpty && txs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to export for this month')),
        );
      }
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(["Date", "Type", "Category/Source", "Title/Description", "Amount"]);

    for (var inf in inflows) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(inf.date),
        "In",
        inf.sourceCategory,
        inf.title,
        inf.amount,
      ]);
    }

    for (var tx in txs) {
      // Guard the IsarLink — if the link relation is broken (e.g., category
      // was deleted without reassign), value could throw on access. Wrap in
      // try/catch so a corrupt link never aborts the whole export.
      String catName;
      try {
        catName = tx.category.value?.name ?? 'Uncategorized';
      } catch (_) {
        catName = 'Uncategorized';
      }
      rows.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        "Out",
        catName,
        tx.description,
        tx.amount,
      ]);
    }

    String csv = rows.map((row) {
      return row.map((e) {
        String val = e.toString();
        if (val.contains(',') || val.contains('"') || val.contains('\n')) {
          return '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }).join(',');
    }).join('\n');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/export_${provider.selectedMonth.month}_${provider.selectedMonth.year}.csv');
    await file.writeAsString(csv);

    final xfile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: 'Monthly Finance Export'),
    );
  }

  Widget _ledgerTab(IconData icon, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 18, color: active ? AppTheme.accent : AppTheme.textMuted),
    ),
  );

  List<Widget> _buildListLedger(BuildContext context, List<dynamic> combinedList, BudgetProvider provider) {
    return combinedList.map((item) {
      final isExpense = item is TransactionModel;
      final title = isExpense ? (item.category.value?.name ?? 'Unknown') : (item.title.isEmpty ? item.sourceCategory : item.title);
      final sub = isExpense ? item.description : 'Income';
      final amount = (item as dynamic).amount as double;
      final date = (item as dynamic).date as DateTime;
      final iconData = isExpense ? _getIconData(item.category.value?.icon ?? '') : Icons.south_west;
      final iconColor = isExpense ? _fromHex(item.category.value?.colorHex ?? '#FFFFFF') : AppTheme.success;

      return Dismissible(
        key: Key(isExpense ? 'tx_${item.id}' : 'inf_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          if (isExpense) provider.deleteTransaction(item.id);
          else provider.deleteInflow(item.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppTheme.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF333333))),
          child: ListTile(
            onTap: isExpense ? () => _showEditTransactionSheet(context, provider, item as TransactionModel) : null,
            leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.2), child: Icon(iconData, color: iconColor)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${DateFormat('MMM d').format(date)}${sub.isNotEmpty ? " • $sub" : ""}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isExpense && (item as TransactionModel).attachmentPath.isNotEmpty)
                GestureDetector(
                  onTap: () => AttachmentViewer.open(context, item.attachmentPath),
                  child: Container(
                    padding: const EdgeInsets.all(6), margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.attachmentPath.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image, size: 14, color: AppTheme.accent),
                  ),
                ),
              Text('${isExpense ? "-" : "+"}${provider.currencySymbol}${amount.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isExpense ? AppTheme.error : AppTheme.success)),
              if (isExpense) ...[const SizedBox(width: 8), const Icon(Icons.edit, size: 14, color: AppTheme.textMuted)],
            ]),
          ),
        ).animate().fade().slideX(begin: 0.1),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final net = provider.monthlyNet;
        final monthName = DateFormat('MMMM yyyy').format(provider.selectedMonth);

        List<dynamic> combinedList = [...provider.monthlyInflows, ...provider.monthlyTransactions];
        combinedList.sort((a, b) => b.date.compareTo(a.date));

        // Category spending data for selected month
        final catSpending = <_CatSpend>[];
        for (final cat in provider.categories) {
          final spent = provider.transactions
              .where((t) => t.category.value?.id == cat.id && t.date.year == provider.selectedMonth.year && t.date.month == provider.selectedMonth.month)
              .fold(0.0, (s, t) => s + t.amount);
          if (spent == 0 && cat.limit <= 0) continue;
          catSpending.add(_CatSpend(cat: cat, spent: spent));
        }
        catSpending.sort((a, b) => b.spent.compareTo(a.spent));

        return Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              child: const Icon(Icons.auto_graph_rounded),
              onPressed: () {
                AdService.showInterstitial(onComplete: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AnalyticsSheet(provider: provider, month: provider.selectedMonth),
                  );
                });
              },
            ),
          ),
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => provider.setMonth(DateTime(provider.selectedMonth.year, provider.selectedMonth.month - 1)),
                ),
                Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => provider.setMonth(DateTime(provider.selectedMonth.year, provider.selectedMonth.month + 1)),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              // Top Card: Net Result
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF333333)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Net Result', style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: net >= 0 ? AppTheme.success.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(net >= 0 ? 'Profit' : 'Overspent', style: TextStyle(color: net >= 0 ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${net >= 0 ? '+' : ''}${provider.currencySymbol}${net.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: net >= 0 ? AppTheme.textLight : AppTheme.error),
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('In', style: TextStyle(color: AppTheme.textMuted)),
                            Text('+${provider.currencySymbol}${provider.monthlyInflowTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Out', style: TextStyle(color: AppTheme.textMuted)),
                            Text('-${provider.currencySymbol}${provider.monthlyExpenseTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: -0.1),

              const SizedBox(height: 24),
              const Center(child: BannerAdWidget()),
              const SizedBox(height: 24),

              Text('Spending by Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)).animate().fade(delay: 200.ms),
              const SizedBox(height: 16),

              catSpending.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppTheme.cardSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF333333))),
                      child: const Center(child: Text('No spending this month', style: TextStyle(color: AppTheme.textMuted))),
                    )
                  : _CategorySpendingList(
                      catSpending: catSpending,
                      currency: provider.currencySymbol,
                      getIcon: _getIconData,
                      fromHex: _fromHex,
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 32),

              _ComparisonSection(provider: provider).animate().fade(delay: 350.ms),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: Text('Ledger History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                  // view toggle
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: AppTheme.cardSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF333333))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _ledgerTab(Icons.list_rounded, !_timelineView, () => setState(() => _timelineView = false)),
                      _ledgerTab(Icons.timeline_rounded, _timelineView, () => setState(() => _timelineView = true)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.accent),
                    onPressed: () => _exportCsv(context, provider),
                  ),
                ],
              ).animate().fade(delay: 400.ms),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search by category, description or amount...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                          onPressed: () { _searchCtrl.clear(); provider.setSearch(''); },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF333333))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              if (_timelineView)
                _TimelineLedger(
                  combinedList: combinedList,
                  provider: provider,
                  getIcon: _getIconData,
                  fromHex: _fromHex,
                  onEditTx: (tx) => _showEditTransactionSheet(context, provider, tx),
                )
              else
                ..._buildListLedger(context, combinedList, provider),

              const SizedBox(height: 80),
            ],
          )
        );
      },
    );
  }
}

// ── Analytics Sheet ───────────────────────────────────────────────────────────

class _AnalyticsSheet extends StatefulWidget {
  final BudgetProvider provider;
  final DateTime month;
  const _AnalyticsSheet({required this.provider, required this.month});

  @override
  State<_AnalyticsSheet> createState() => _AnalyticsSheetState();
}

class _AnalyticsSheetState extends State<_AnalyticsSheet> {
  late DateTime _month;

  BudgetProvider get provider => widget.provider;
  DateTime get month => _month;

  @override
  void initState() {
    super.initState();
    _month = widget.month;
  }

  List<TransactionModel> get _monthTx => provider.transactions
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  double get _monthLifestyleSpent => _monthTx
      .where((t) => t.category.value?.type == CategoryType.variable)
      .fold(0.0, (s, t) => s + t.amount);

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.year < now.year || (next.year == now.year && next.month <= now.month)) {
      setState(() { _month = next; });
    }
  }

  // ── 1. Burn Rate / Pace ───────────────────────────────────────────────────
  Map<String, dynamic> _pace() {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysPassed = isCurrentMonth ? now.day : daysInMonth;
    final daysLeft = isCurrentMonth ? (daysInMonth - daysPassed + 1) : 0;
    final pool = provider.totalMonthlyPool - provider.savingsGoal - provider.sumOfFixedBills;
    final spent = _monthLifestyleSpent;
    final idealDailyRate = pool / daysInMonth;
    final actualDailyRate = daysPassed > 0 ? spent / daysPassed : 0.0;
    final ratio = idealDailyRate > 0 ? actualDailyRate / idealDailyRate : 1.0;
    final projected = actualDailyRate * daysInMonth;
    final String pace;
    final Color paceColor;
    if (ratio < 0.7) { pace = 'Under Pace'; paceColor = Colors.blueAccent; }
    else if (ratio < 1.1) { pace = 'Optimal'; paceColor = AppTheme.success; }
    else if (ratio < 1.4) { pace = 'Hot'; paceColor = AppTheme.accent; }
    else { pace = 'Critical'; paceColor = AppTheme.error; }
    return {
      'pace': pace, 'paceColor': paceColor, 'ratio': ratio,
      'actualDaily': actualDailyRate, 'idealDaily': idealDailyRate,
      'projected': projected, 'pool': pool, 'daysLeft': daysLeft,
    };
  }

  // ── 2. Anomaly Detection (Z-Score per category) ───────────────────────────
  List<Map<String, dynamic>> _anomalies() {
    final results = <Map<String, dynamic>>[];
    for (final cat in provider.categories.where((c) => c.type == CategoryType.variable)) {
      final allTx = provider.transactions
          .where((t) => t.category.value?.id == cat.id)
          .toList();
      if (allTx.length < 3) continue;
      final amounts = allTx.map((t) => t.amount).toList();
      final mean = amounts.fold(0.0, (s, a) => s + a) / amounts.length;
      if (mean == 0) continue;
      final variance = amounts.fold(0.0, (s, a) => s + pow(a - mean, 2)) / amounts.length;
      final stdDev = sqrt(variance);
      if (stdDev == 0) continue;
      // Check selected month's total vs historical pattern
      final currentMonthSpent = _monthTx
          .where((t) => t.category.value?.id == cat.id)
          .fold(0.0, (s, t) => s + t.amount);
      if (currentMonthSpent == 0) continue;
      final z = (currentMonthSpent - mean) / stdDev;
      if (z > 1.5) {
        final pctAbove = ((currentMonthSpent - mean) / mean * 100).round();
        results.add({'cat': cat.name, 'z': z, 'pct': pctAbove, 'amount': currentMonthSpent});
      }
    }
    results.sort((a, b) => (b['z'] as double).compareTo(a['z'] as double));
    return results.take(3).toList();
  }

  // ── 3. Projected end-of-month spend (linear) ─────────────────────────────
  List<FlSpot> _actualSpots() {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final lastDay = isCurrentMonth ? now.day : DateTime(month.year, month.month + 1, 0).day;
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int d = 1; d <= lastDay; d++) {
      final daySpend = _monthTx
          .where((t) => t.date.day == d && t.category.value?.type == CategoryType.variable)
          .fold(0.0, (s, t) => s + t.amount);
      cumulative += daySpend;
      spots.add(FlSpot(d.toDouble(), cumulative));
    }
    return spots;
  }

  // ── 4. Safe to Spend ──────────────────────────────────────────────────────
  double _safeToSpend() {
    final pool = provider.totalMonthlyPool - provider.savingsGoal - provider.sumOfFixedBills;
    return (pool - _monthLifestyleSpent).clamp(0.0, double.infinity);
  }

  // ── 5. Opportunity Cost (FV of overspend at 7% annual) ───────────────────
  Map<String, dynamic> _opportunityCost(double monthlyOverspend) {
    const r = 0.07;
    const n = 12.0;
    final monthly = r / n;
    double fv10 = 0, fv20 = 0, fv30 = 0;
    if (monthlyOverspend > 0) {
      fv10 = monthlyOverspend * (pow(1 + monthly, n * 10) - 1) / monthly;
      fv20 = monthlyOverspend * (pow(1 + monthly, n * 20) - 1) / monthly;
      fv30 = monthlyOverspend * (pow(1 + monthly, n * 30) - 1) / monthly;
    }
    return {'monthly': monthlyOverspend, 'fv10': fv10, 'fv20': fv20, 'fv30': fv30};
  }

  // ── 6. Phantom Subscriptions (autocorrelation on merchant intervals) ──────
  List<Map<String, dynamic>> _phantomSubscriptions() {
    final txByMerchant = <String, List<DateTime>>{};
    for (final tx in provider.transactions) {
      final key = '${tx.description.toLowerCase().trim()}__${tx.amount.toStringAsFixed(0)}';
      txByMerchant.putIfAbsent(key, () => []).add(tx.date);
    }
    final results = <Map<String, dynamic>>[];
    txByMerchant.forEach((key, dates) {
      if (dates.length < 2) return;
      dates.sort();
      final intervals = <double>[];
      for (int i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inDays.toDouble());
      }
      final mean = intervals.fold(0.0, (s, v) => s + v) / intervals.length;
      final variance = intervals.fold(0.0, (s, v) => s + pow(v - mean, 2)) / intervals.length;
      final stdDev = sqrt(variance);
      // Check if it looks like weekly, monthly, or yearly recurring
      final isRecurring = stdDev < 5 && (
        (mean >= 25 && mean <= 35) ||
        (mean >= 5 && mean <= 9) ||
        (mean >= 360 && mean <= 370)
      );
      if (!isRecurring) return;
      final parts = key.split('__');
      final String cycle = mean <= 9 ? 'Weekly' : mean <= 35 ? 'Monthly' : 'Yearly';
      results.add({
        'name': parts[0],
        'amount': double.tryParse(parts[1]) ?? 0.0,
        'cycle': cycle,
        'count': dates.length,
        'lastDate': dates.last,
      });
    });
    return results;
  }

  // ── 7. Pareto Drain (80/20) ───────────────────────────────────────────────
  Map<String, dynamic> _paretoDrain() {
    final merchantTotals = <String, double>{};
    for (final tx in _monthTx) {
      if (tx.category.value?.type != CategoryType.variable) continue;
      final m = tx.description.trim().isEmpty ? 'Unknown' : tx.description.trim();
      merchantTotals[m] = (merchantTotals[m] ?? 0) + tx.amount;
    }
    if (merchantTotals.isEmpty) return {'merchants': [], 'totalMerchants': 0, 'paretoCount': 0, 'pareto80pct': 0.0};
    final sorted = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    double cumulative = 0;
    final paretoMerchants = <Map<String, dynamic>>[];
    for (final e in sorted) {
      cumulative += e.value;
      paretoMerchants.add({'name': e.key, 'amount': e.value, 'pct': e.value / total * 100});
      if (cumulative >= total * 0.8) break;
    }
    return {
      'merchants': paretoMerchants,
      'totalMerchants': sorted.length,
      'paretoCount': paretoMerchants.length,
      'pareto80pct': cumulative / total * 100,
    };
  }

  // ── 8. Time Heatmap (day-of-week × hour) ─────────────────────────────────
  Map<String, dynamic> _timeHeatmap() {
    // 7 rows (Mon-Sun) × 4 cols (6h buckets: 0-5, 6-11, 12-17, 18-23)
    final grid = List.generate(7, (_) => List.filled(4, 0.0));
    for (final tx in _monthTx) {
      final dow = tx.date.weekday - 1; // 0=Mon
      final bucket = (tx.date.hour / 6).floor().clamp(0, 3);
      grid[dow][bucket] += tx.amount;
    }
    double peak = 0;
    int peakDow = 0, peakBucket = 0;
    for (int d = 0; d < 7; d++) {
      for (int b = 0; b < 4; b++) {
        if (grid[d][b] > peak) { peak = grid[d][b]; peakDow = d; peakBucket = b; }
      }
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const bucketLabels = ['12am–6am', '6am–12pm', '12pm–6pm', '6pm–12am'];
    return {'grid': grid, 'peak': peak, 'peakDay': days[peakDow], 'peakTime': bucketLabels[peakBucket]};
  }

  // ── 9. Markov Chain next-spend prediction ────────────────────────────────
  Map<String, dynamic> _markov() {
    final txSorted = [..._monthTx]..sort((a, b) => a.date.compareTo(b.date));
    final transitions = <String, Map<String, int>>{};
    for (int i = 0; i < txSorted.length - 1; i++) {
      final from = txSorted[i].category.value?.name ?? 'Unknown';
      final to = txSorted[i + 1].category.value?.name ?? 'Unknown';
      transitions.putIfAbsent(from, () => {})[to] = (transitions[from]![to] ?? 0) + 1;
    }
    if (txSorted.isEmpty) return {'prediction': null};
    final lastCat = txSorted.last.category.value?.name ?? 'Unknown';
    final nextMap = transitions[lastCat];
    if (nextMap == null || nextMap.isEmpty) return {'prediction': null, 'lastCat': lastCat};
    final total = nextMap.values.fold(0, (s, v) => s + v);
    final sorted = nextMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final probability = (top.value / total * 100).round();
    return {
      'prediction': top.key,
      'probability': probability,
      'lastCat': lastCat,
      'top3': sorted.take(3).map((e) => {'cat': e.key, 'pct': (e.value / total * 100).round()}).toList(),
    };
  }

  // ── Health Score (0–100) ──────────────────────────────────────────────────
  int _healthScore(Map<String, dynamic> pace) {
    int score = 100;
    final ratio = pace['ratio'] as double;
    if (ratio > 1.4) score -= 40;
    else if (ratio > 1.1) score -= 20;
    else if (ratio < 0.5) score -= 5;
    final anomalies = _anomalies();
    score -= (anomalies.length * 10).clamp(0, 30);
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final cur = provider.currencySymbol;
    final pace = _pace();
    final anomalies = _anomalies();
    final safeToSpend = _safeToSpend();
    final health = _healthScore(pace);
    final actualSpots = _actualSpots();
    final pool = pace['pool'] as double;
    final projected = pace['projected'] as double;
    final monthlyOverspend = (projected - pool).clamp(0.0, double.infinity);
    final oppCost = _opportunityCost(monthlyOverspend);
    final pareto = _paretoDrain();
    final heatmap = _timeHeatmap();
    final markov = _markov();
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final paceColor = pace['paceColor'] as Color;

    // Month summary figures
    final monthInflows = provider.inflows
        .where((i) => i.date.year == month.year && i.date.month == month.month)
        .fold(0.0, (s, i) => s + i.amount);
    final monthTotalIncome = provider.totalIncome + monthInflows;
    final monthTotalSpent = _monthTx.fold(0.0, (s, t) => s + t.amount);
    final monthNet = monthTotalIncome - monthTotalSpent;
    final savedFromGoal = monthNet - provider.savingsGoal;

    // Budget line: flat at pool
    final budgetSpots = [FlSpot(1, 0), FlSpot(daysInMonth.toDouble(), pool)];
    // Projected line from today to end of month (only for current month)
    final currentSpent = actualSpots.isNotEmpty ? actualSpots.last.y : 0.0;
    final actualDaily = pace['actualDaily'] as double;
    final projectedEnd = (currentSpent + actualDaily * (daysInMonth - now.day)).clamp(0.0, pool * 1.3);
    final projectedSpots = (isCurrentMonth && actualSpots.isNotEmpty) ? [
      FlSpot(now.day.toDouble(), currentSpent),
      FlSpot(daysInMonth.toDouble(), projectedEnd),
    ] : <FlSpot>[];

    final healthColor = health >= 75 ? AppTheme.success : health >= 50 ? AppTheme.accent : AppTheme.error;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),

            Row(children: [
              const Icon(Icons.auto_graph_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              const Text('Financial Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),

            // Month selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    color: Colors.white70,
                  ),
                  SizedBox(
                    width: 130,
                    child: Center(
                      child: Text(
                        () {
                          const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
                          final now = DateTime.now();
                          final label = '${months[month.month - 1]} ${month.year}';
                          final isCurrent = month.year == now.year && month.month == now.month;
                          return isCurrent ? '$label ·  Now' : label;
                        }(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final isCurrentOrFuture = month.year == now.year && month.month >= now.month;
                      if (!isCurrentOrFuture) _nextMonth();
                    },
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: () {
                        final now = DateTime.now();
                        return (month.year == now.year && month.month >= now.month) ? Colors.white24 : Colors.white70;
                      }(),
                    ),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── SECTION 1: STATUS ════════════════════════════════════════
            const _AnalyticsSectionHeader(
                label: 'STATUS', subtitle: 'Where you stand right now'),
            const SizedBox(height: 14),

            // ── Health Score ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [healthColor.withOpacity(0.2), healthColor.withOpacity(0.05)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: healthColor.withOpacity(0.3)),
              ),
              child: Row(children: [
                SizedBox(width: 80, height: 80,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: health / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: healthColor,
                    ),
                    Text('$health', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: healthColor)),
                  ]),
                ),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Financial Health Score', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    health >= 75 ? 'Excellent — On Track' : health >= 50 ? 'Fair — Watch Spending' : 'Critical — Overspending',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: healthColor),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Month Summary ─────────────────────────────────────────────
            _AnalyticsCard(
              title: isCurrentMonth ? 'Month So Far' : 'Month Summary',
              icon: Icons.summarize_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Income row
                _SummaryRow(
                  label: 'Total Income',
                  value: '$cur${monthTotalIncome.toStringAsFixed(0)}',
                  color: AppTheme.success,
                  icon: Icons.south_west_rounded,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total Spent',
                  value: '− $cur${monthTotalSpent.toStringAsFixed(0)}',
                  color: AppTheme.error,
                  icon: Icons.north_east_rounded,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          monthNet >= 0 ? 'Net Saved' : 'Overspent',
                          style: TextStyle(
                            fontSize: 12, color: monthNet >= 0 ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${monthNet >= 0 ? '+' : '−'}$cur${monthNet.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: monthNet >= 0 ? AppTheme.success : AppTheme.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (monthNet >= 0 ? AppTheme.success : AppTheme.error).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        monthNet >= 0 ? Icons.savings_rounded : Icons.warning_amber_rounded,
                        color: monthNet >= 0 ? AppTheme.success : AppTheme.error,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                if (!isCurrentMonth) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (savedFromGoal >= 0 ? AppTheme.success : AppTheme.accent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(
                        savedFromGoal >= 0 ? Icons.check_circle_outline : Icons.info_outline,
                        size: 14,
                        color: savedFromGoal >= 0 ? AppTheme.success : AppTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        savedFromGoal >= 0
                            ? 'Met savings goal · $cur${savedFromGoal.toStringAsFixed(0)} extra saved'
                            : 'Missed savings goal by $cur${savedFromGoal.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12, height: 1.4,
                          color: savedFromGoal >= 0 ? AppTheme.success : AppTheme.accent,
                        ),
                      )),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 14),

            // ── Pace / Burn Rate ─────────────────────────────────────────
            _AnalyticsCard(
              title: 'Burn Rate',
              icon: Icons.speed_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pace['pace'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: paceColor)),
                    const SizedBox(height: 4),
                    Text('Actual: $cur${(pace['actualDaily'] as double).toStringAsFixed(0)}/day', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text('Ideal:  $cur${(pace['idealDaily'] as double).toStringAsFixed(0)}/day', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: paceColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${((pace['ratio'] as double) * 100).toStringAsFixed(0)}%\nof budget rate',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: paceColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ((pace['ratio'] as double)).clamp(0.0, 2.0) / 2.0,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: paceColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  projected <= pool
                      ? 'On track — projected to spend $cur${projected.toStringAsFixed(0)} this month'
                      : 'Will exceed budget by $cur${(projected - pool).toStringAsFixed(0)} at this rate',
                  style: TextStyle(fontSize: 11, color: projected <= pool ? AppTheme.textMuted : AppTheme.error),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Safe to Spend (current month only) ──────────────────────
            if (isCurrentMonth) ...[
              _AnalyticsCard(
                title: 'Safe to Spend Right Now',
                icon: Icons.wallet_rounded,
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$cur${safeToSpend.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold,
                        color: safeToSpend > 0 ? AppTheme.success : AppTheme.error,
                      )),
                    const SizedBox(height: 4),
                    Text(
                      safeToSpend > 0
                          ? 'You can spend this freely without touching savings or missing any bill'
                          : 'You have exceeded your discretionary budget',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // ── Projection Chart ─────────────────────────────────────────
            _AnalyticsCard(
              title: 'Spending Trajectory',
              icon: Icons.show_chart_rounded,
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(enabled: false),
                    minX: 1, maxX: daysInMonth.toDouble(),
                    minY: 0, maxY: (pool * 1.3).ceilToDouble(),
                    clipData: FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
                      getDrawingVerticalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                        interval: 5,
                      )),
                    ),
                    lineBarsData: [
                      // Budget line
                      LineChartBarData(
                        spots: budgetSpots,
                        isCurved: false,
                        color: AppTheme.accentBlue.withOpacity(0.5),
                        barWidth: 1.5,
                        dotData: FlDotData(show: false),
                        dashArray: [6, 4],
                      ),
                      // Actual spending
                      if (actualSpots.isNotEmpty)
                        LineChartBarData(
                          spots: actualSpots,
                          isCurved: true,
                          color: AppTheme.success,
                          barWidth: 2.5,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.success.withOpacity(0.08),
                          ),
                        ),
                      // Projected trajectory
                      if (projectedSpots.isNotEmpty)
                        LineChartBarData(
                          spots: projectedSpots,
                          isCurved: false,
                          color: projected > pool ? AppTheme.error : AppTheme.accent,
                          barWidth: 1.5,
                          dotData: FlDotData(show: false),
                          dashArray: [4, 4],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── SECTION 2: PATTERNS ══════════════════════════════════════
            const _AnalyticsSectionHeader(
                label: 'PATTERNS', subtitle: 'How your spending behaves'),
            const SizedBox(height: 14),

            // ── Anomalies ────────────────────────────────────────────────
            _AnalyticsCard(
              title: 'Spending Anomalies',
              icon: Icons.warning_amber_rounded,
              child: anomalies.isEmpty
                  ? const Row(children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                      SizedBox(width: 10),
                      Text('No unusual spending detected', style: TextStyle(color: AppTheme.textMuted)),
                    ])
                  : Column(
                      children: anomalies.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('Z ${(a['z'] as double).toStringAsFixed(1)}',
                              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['cat'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${a['pct']}% above your normal pattern · $cur${(a['amount'] as double).toStringAsFixed(0)} this month',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ])),
                        ]),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 14),

            // ── Pareto Drain ─────────────────────────────────────────────
            _AnalyticsCard(
              title: 'The Vital Few — 80/20 Drain',
              icon: Icons.pie_chart_rounded,
              child: (pareto['totalMerchants'] as int) == 0
                  ? const Text('No transactions yet', style: TextStyle(color: AppTheme.textMuted))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RichText(text: TextSpan(
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                        children: [
                          const TextSpan(text: 'You spent across '),
                          TextSpan(text: '${pareto['totalMerchants']} merchants', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const TextSpan(text: ', but '),
                          TextSpan(text: '${(pareto['pareto80pct'] as double).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' went to just '),
                          TextSpan(text: '${pareto['paretoCount']}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                          const TextSpan(text: ':'),
                        ],
                      )),
                      const SizedBox(height: 14),
                      ...(pareto['merchants'] as List<Map<String, dynamic>>).take(5).map((m) {
                        final pct = m['pct'] as double;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text('$cur${(m['amount'] as double).toStringAsFixed(0)} · ${pct.toStringAsFixed(0)}%',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 5,
                                backgroundColor: Colors.white10,
                                color: AppTheme.error,
                              ),
                            ),
                          ]),
                        );
                      }),
                    ]),
            ),
            const SizedBox(height: 14),

            // ── Time Heatmap ─────────────────────────────────────────────
            _AnalyticsCard(
              title: 'Spending Heatmap',
              icon: Icons.grid_view_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((heatmap['peak'] as double) > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '🔥 Peak spending: ${heatmap['peakDay']} ${heatmap['peakTime']}',
                      style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                Row(children: [
                  const SizedBox(width: 28),
                  ...['Midnight', 'Morning', 'Afternoon', 'Evening'].map((l) =>
                    Expanded(child: Text(l, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8), textAlign: TextAlign.center)),
                  ),
                ]),
                const SizedBox(height: 4),
                ...List.generate(7, (d) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final grid = heatmap['grid'] as List<List<double>>;
                  final peak = heatmap['peak'] as double;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text(days[d], style: const TextStyle(color: AppTheme.textMuted, fontSize: 9))),
                      ...List.generate(4, (b) {
                        final val = grid[d][b];
                        final intensity = peak > 0 ? (val / peak) : 0.0;
                        final cellColor = intensity == 0
                            ? Colors.white.withOpacity(0.04)
                            : Color.lerp(const Color(0xFF2D1B69), const Color(0xFFD4AF37), intensity)!;
                        return Expanded(
                          child: Container(
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 24),

            // ── SECTION 3: FORECASTS ═════════════════════════════════════
            const _AnalyticsSectionHeader(
                label: 'FORECASTS', subtitle: 'What might come next'),
            const SizedBox(height: 14),

            // ── Opportunity Cost ─────────────────────────────────────────
            _AnalyticsCard(
              title: 'Opportunity Cost',
              icon: Icons.trending_up_rounded,
              child: monthlyOverspend <= 0
                  ? const Row(children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('No overspend this month — you\'re building wealth!', style: TextStyle(color: AppTheme.textMuted))),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('If you invested your $cur${monthlyOverspend.toStringAsFixed(0)}/mo overspend at 7% annual return:',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _OppCostColumn(label: '10 yrs', value: oppCost['fv10'] as double, currency: cur),
                        _OppCostColumn(label: '20 yrs', value: oppCost['fv20'] as double, currency: cur),
                        _OppCostColumn(label: '30 yrs', value: oppCost['fv30'] as double, currency: cur),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '💸 Every $cur${monthlyOverspend.toStringAsFixed(0)} you overspend this month costs you $cur${(oppCost['fv10'] as double).toStringAsFixed(0)} in potential wealth over 10 years.',
                          style: const TextStyle(color: AppTheme.error, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ]),
            ),
            const SizedBox(height: 14),

            // ── Markov Chain Prediction ──────────────────────────────────
            _AnalyticsCard(
              title: 'Crystal Ball — Next Spend',
              icon: Icons.auto_awesome_rounded,
              child: markov['prediction'] == null
                  ? const Text('Not enough transaction history yet', style: TextStyle(color: AppTheme.textMuted))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Last purchase: ${markov['lastCat']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.accent.withOpacity(0.2), const Color(0xFF2D1B69).withOpacity(0.3)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Text('🔮', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${markov['probability']}% chance your next purchase is:',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(markov['prediction'] as String,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      ...(markov['top3'] as List).map((e) {
                        final pct = e['pct'] as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            SizedBox(width: 80, child: Text(e['cat'] as String, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Expanded(child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                color: AppTheme.accent,
                              ),
                            )),
                            const SizedBox(width: 8),
                            Text('$pct%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ]),
                        );
                      }),
                    ]),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OppCostColumn extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  const _OppCostColumn({required this.label, required this.value, required this.currency});

  String _format(double v) {
    if (v >= 10000000) return '$currency${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '$currency${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '$currency${(v / 1000).toStringAsFixed(0)}K';
    return '$currency${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(_format(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
    ]);
  }
}

// Section divider for the analytics sheet — groups related cards under a
// single header so the sheet stops feeling like a long undifferentiated list.
class _AnalyticsSectionHeader extends StatelessWidget {
  final String label;
  final String subtitle;
  const _AnalyticsSectionHeader({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _AnalyticsCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.accent, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Spending Comparison Section ───────────────────────────────────────────────

class _ComparisonSection extends StatefulWidget {
  final BudgetProvider provider;
  const _ComparisonSection({required this.provider});

  @override
  State<_ComparisonSection> createState() => _ComparisonSectionState();
}

class _ComparisonSectionState extends State<_ComparisonSection> {
  bool _weekly = true;

  BudgetProvider get provider => widget.provider;

  List<TransactionModel> get _monthTx => provider.transactions
      .where((t) =>
          t.date.year == provider.selectedMonth.year &&
          t.date.month == provider.selectedMonth.month)
      .toList();

  @override
  Widget build(BuildContext context) {
    final monthTx = _monthTx;
    final now = DateTime.now();
    final sel = provider.selectedMonth;
    final isCurrentMonth = sel.year == now.year && sel.month == now.month;
    final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    final cats = provider.categories
        .where((c) => monthTx.any((t) => t.category.value?.id == c.id))
        .toList();

    if (cats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Spending Comparison',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _tab('Weekly', _weekly, () => setState(() => _weekly = true)),
                _tab('Daily', !_weekly, () => setState(() => _weekly = false)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_weekly)
          _WeeklyComparison(cats: cats, monthTx: monthTx, cur: provider.currencySymbol, lastDay: lastDay)
        else
          _DailyComparison(cats: cats, monthTx: monthTx, cur: provider.currencySymbol),
      ],
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        color: active ? Colors.black : AppTheme.textMuted,
      )),
    ),
  );
}

// ── Weekly Comparison ─────────────────────────────────────────────────────────

class _WeeklyComparison extends StatelessWidget {
  final List<CategoryModel> cats;
  final List<TransactionModel> monthTx;
  final String cur;
  final int lastDay;
  const _WeeklyComparison({required this.cats, required this.monthTx, required this.cur, required this.lastDay});

  static int _weekOf(int day) => ((day - 1) ~/ 7).clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    final weeksCount = _weekOf(lastDay) + 1;
    final weekLabels = ['W1', 'W2', 'W3', 'W4'].sublist(0, weeksCount);

    final data = <Map<String, dynamic>>[];
    for (final cat in cats) {
      final weekAmounts = List.filled(4, 0.0);
      for (final tx in monthTx.where((t) => t.category.value?.id == cat.id)) {
        weekAmounts[_weekOf(tx.date.day)] += tx.amount;
      }
      final total = weekAmounts.fold(0.0, (s, v) => s + v);
      if (total == 0) continue;
      data.add({
        'cat': cat,
        'weeks': weekAmounts,
        'total': total,
        'max': weekAmounts.reduce(max),
      });
    }
    data.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              const Expanded(flex: 3, child: Text('Category',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold))),
              ...weekLabels.map((l) => Expanded(
                child: Text(l, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 64),
            ]),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...data.map((d) => _WeekRow(d: d, weeksCount: weeksCount, cur: cur)),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final Map<String, dynamic> d;
  final int weeksCount;
  final String cur;
  const _WeekRow({required this.d, required this.weeksCount, required this.cur});

  @override
  Widget build(BuildContext context) {
    final cat = d['cat'] as CategoryModel;
    final weeks = d['weeks'] as List<double>;
    final total = d['total'] as double;
    final maxVal = d['max'] as double;

    // Week-over-week trend
    int lastFilled = -1, prevFilled = -1;
    for (int i = weeksCount - 1; i >= 0; i--) {
      if (weeks[i] > 0) { if (lastFilled == -1) lastFilled = i; else { prevFilled = i; break; } }
    }
    IconData trendIcon = Icons.remove;
    Color trendColor = AppTheme.textMuted;
    Color maxBarColor = AppTheme.accent;
    if (lastFilled >= 0 && prevFilled >= 0) {
      if (weeks[lastFilled] > weeks[prevFilled] * 1.1) {
        trendIcon = Icons.arrow_upward_rounded;
        trendColor = AppTheme.error;
        maxBarColor = AppTheme.error;
      } else if (weeks[lastFilled] < weeks[prevFilled] * 0.9) {
        trendIcon = Icons.arrow_downward_rounded;
        trendColor = AppTheme.success;
        maxBarColor = AppTheme.success;
      }
    }

    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(cat.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        ...List.generate(weeksCount, (i) {
          final val = weeks[i];
          final isMax = val == maxVal && val > 0;
          final barFrac = maxVal > 0 ? (val / maxVal) : 0.0;
          return Expanded(
            child: Column(children: [
              Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: val > 0 ? barFrac.clamp(0.08, 1.0) : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMax ? maxBarColor.withOpacity(0.85) : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                val > 0 ? '${cur}${val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0)}' : '—',
                style: TextStyle(
                  fontSize: 10,
                  color: isMax ? maxBarColor : AppTheme.textMuted,
                  fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          );
        }),
        SizedBox(
          width: 64,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Icon(trendIcon, size: 13, color: trendColor),
            const SizedBox(width: 3),
            Flexible(child: Text(
              '${cur}${total >= 1000 ? '${(total / 1000).toStringAsFixed(1)}k' : total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      ]),
    );
  }
}

// ── Daily (Day-of-Week) Comparison ───────────────────────────────────────────

class _DailyComparison extends StatelessWidget {
  final List<CategoryModel> cats;
  final List<TransactionModel> monthTx;
  final String cur;
  const _DailyComparison({required this.cats, required this.monthTx, required this.cur});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final data = <Map<String, dynamic>>[];
    for (final cat in cats) {
      final dayAmounts = List.filled(7, 0.0);
      for (final tx in monthTx.where((t) => t.category.value?.id == cat.id)) {
        dayAmounts[tx.date.weekday - 1] += tx.amount;
      }
      final total = dayAmounts.fold(0.0, (s, v) => s + v);
      if (total == 0) continue;
      data.add({
        'cat': cat,
        'days': dayAmounts,
        'total': total,
        'max': dayAmounts.reduce(max),
        'peakDow': dayAmounts.indexOf(dayAmounts.reduce(max)),
      });
    }
    data.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              const Expanded(flex: 3, child: Text('Category',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold))),
              ...dayLabels.map((l) => Expanded(
                child: Text(l, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 56),
            ]),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...data.map((d) => _DayRow(d: d, cur: cur)),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final Map<String, dynamic> d;
  final String cur;
  const _DayRow({required this.d, required this.cur});

  @override
  Widget build(BuildContext context) {
    final cat = d['cat'] as CategoryModel;
    final days = d['days'] as List<double>;
    final total = d['total'] as double;
    final maxVal = d['max'] as double;
    final peakDow = d['peakDow'] as int;
    final peakLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][peakDow];

    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
            Text('peak: $peakLabel',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
        ),
        ...List.generate(7, (i) {
          final val = days[i];
          final isMax = i == peakDow && val > 0;
          final barFrac = maxVal > 0 ? (val / maxVal) : 0.0;
          final isWeekend = i >= 5;
          return Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: val > 0 ? barFrac.clamp(0.08, 1.0) : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isMax
                        ? AppTheme.error.withOpacity(0.85)
                        : isWeekend
                            ? AppTheme.accent.withOpacity(0.38)
                            : AppTheme.accent.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }),
        SizedBox(
          width: 56,
          child: Text(
            '${cur}${total >= 1000 ? '${(total / 1000).toStringAsFixed(1)}k' : total.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryRow({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ]),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ── Category Spending List ────────────────────────────────────────────────────

class _CatSpend {
  final CategoryModel cat;
  final double spent;
  const _CatSpend({required this.cat, required this.spent});
}

class _CategorySpendingList extends StatelessWidget {
  final List<_CatSpend> catSpending;
  final String currency;
  final IconData Function(String) getIcon;
  final Color Function(String) fromHex;

  const _CategorySpendingList({
    required this.catSpending,
    required this.currency,
    required this.getIcon,
    required this.fromHex,
  });

  @override
  Widget build(BuildContext context) {
    final totalSpent = catSpending.fold(0.0, (s, c) => s + c.spent);
    final maxSpent = catSpending.fold(0.0, (s, c) => s > c.spent ? s : c.spent);

    // Split lifestyle and fixed
    final lifestyle = catSpending.where((c) => c.cat.type == CategoryType.variable).toList();
    final fixed = catSpending.where((c) => c.cat.type == CategoryType.fixed).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total pill at top
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currency${totalSpent.toStringAsFixed(0)} total',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${catSpending.length} categories',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 24),

          if (lifestyle.isNotEmpty) ...[
            _SectionLabel('Lifestyle', Icons.local_fire_department_rounded, AppTheme.accent),
            ...lifestyle.map((c) => _CatRow(c: c, totalSpent: totalSpent, maxSpent: maxSpent, currency: currency, getIcon: getIcon, fromHex: fromHex)),
            if (fixed.isNotEmpty) const Divider(color: Colors.white10, height: 24),
          ],
          if (fixed.isNotEmpty) ...[
            _SectionLabel('Fixed Bills', Icons.receipt_long_rounded, AppTheme.accentBlue),
            ...fixed.map((c) => _CatRow(c: c, totalSpent: totalSpent, maxSpent: maxSpent, currency: currency, getIcon: getIcon, fromHex: fromHex)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _SectionLabel(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.1)),
      ]),
    );
  }
}

class _CatRow extends StatelessWidget {
  final _CatSpend c;
  final double totalSpent;
  final double maxSpent;
  final String currency;
  final IconData Function(String) getIcon;
  final Color Function(String) fromHex;

  const _CatRow({
    required this.c,
    required this.totalSpent,
    required this.maxSpent,
    required this.currency,
    required this.getIcon,
    required this.fromHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = fromHex(c.cat.colorHex);
    final hasLimit = c.cat.limit > 0;
    final pct = hasLimit ? (c.spent / c.cat.limit).clamp(0.0, 1.0) : 0.0;
    // Bar shows progress toward THIS category's own limit (intuitive: empty
    // bar = nothing spent, full bar = at limit, red = over). Categories
    // without a limit fall back to relative-to-max comparison.
    final barFrac = hasLimit
        ? (c.spent / c.cat.limit).clamp(0.0, 1.0)
        : (maxSpent > 0 ? c.spent / maxSpent : 0.0);
    final isOver = hasLimit && c.spent > c.cat.limit;
    final shareOfTotal = totalSpent > 0 ? (c.spent / totalSpent * 100) : 0.0;

    // Show "<1%" for tiny fractions so a real ₹40 spend doesn't display
    // as "0% of limit" against an ₹8.9k limit.
    String fmtPct(double p) {
      if (p <= 0) return '0%';
      if (p < 1) return '<1%';
      return '${p.toStringAsFixed(0)}%';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Icon
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(getIcon(c.cat.icon), size: 15, color: color),
            ),
            const SizedBox(width: 12),
            // Name + share
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(c.cat.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
                  if (isOver)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Over', style: TextStyle(fontSize: 9, color: AppTheme.error, fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 1),
                Text(
                  hasLimit
                      ? '${fmtPct(pct * 100)} of ${currency}${c.cat.limit >= 1000 ? '${(c.cat.limit / 1000).toStringAsFixed(1)}k' : c.cat.limit.toStringAsFixed(0)} limit'
                      : 'No limit set',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            )),
            const SizedBox(width: 12),
            // Amount
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$currency${c.spent >= 1000 ? '${(c.spent / 1000).toStringAsFixed(1)}k' : c.spent.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: isOver ? AppTheme.error : Colors.white)),
              if (hasLimit)
                Text('/ $currency${c.cat.limit >= 1000 ? '${(c.cat.limit / 1000).toStringAsFixed(1)}k' : c.cat.limit.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ]),
          ]),
          const SizedBox(height: 8),
          // Progress bar: fills as spend approaches the limit; red when over.
          LayoutBuilder(builder: (_, constraints) {
            final w = constraints.maxWidth;
            return Stack(children: [
              // Background track
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Spend bar
              Container(
                height: 5,
                width: w * barFrac,
                decoration: BoxDecoration(
                  color: isOver ? AppTheme.error : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

// ── Timeline Ledger ───────────────────────────────────────────────────────────

class _TimelineLedger extends StatelessWidget {
  final List<dynamic> combinedList;
  final BudgetProvider provider;
  final IconData Function(String) getIcon;
  final Color Function(String) fromHex;
  final void Function(TransactionModel) onEditTx;

  const _TimelineLedger({
    required this.combinedList,
    required this.provider,
    required this.getIcon,
    required this.fromHex,
    required this.onEditTx,
  });

  @override
  Widget build(BuildContext context) {
    if (combinedList.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No transactions', style: TextStyle(color: AppTheme.textMuted)),
      ));
    }

    // Group by day
    final Map<String, List<dynamic>> grouped = {};
    for (final item in combinedList) {
      final date = (item as dynamic).date as DateTime;
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys.map((key) {
        final items = grouped[key]!;
        final date = DateTime.parse(key);
        final dayTotal = items.fold(0.0, (s, item) {
          final isExpense = item is TransactionModel;
          return s + (isExpense ? -(item as dynamic).amount : (item as dynamic).amount);
        });
        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == key;

        return _TimelineDay(
          date: date,
          items: items,
          dayTotal: dayTotal,
          isToday: isToday,
          provider: provider,
          getIcon: getIcon,
          fromHex: fromHex,
          onEditTx: onEditTx,
        );
      }).toList(),
    );
  }
}

class _TimelineDay extends StatelessWidget {
  final DateTime date;
  final List<dynamic> items;
  final double dayTotal;
  final bool isToday;
  final BudgetProvider provider;
  final IconData Function(String) getIcon;
  final Color Function(String) fromHex;
  final void Function(TransactionModel) onEditTx;

  const _TimelineDay({
    required this.date,
    required this.items,
    required this.dayTotal,
    required this.isToday,
    required this.provider,
    required this.getIcon,
    required this.fromHex,
    required this.onEditTx,
  });

  @override
  Widget build(BuildContext context) {
    final cur = provider.currencySymbol;
    final totalColor = dayTotal >= 0 ? AppTheme.success : AppTheme.error;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ──────────────────────────────────────────────
          SizedBox(
            width: 52,
            child: Column(
              children: [
                // Checkpoint node
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isToday ? AppTheme.accent : AppTheme.cardSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday ? AppTheme.accent : Colors.white24,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: isToday ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                // Spine line down
                Expanded(
                  child: Center(
                    child: Container(width: 1.5, color: Colors.white12),
                  ),
                ),
              ],
            ),
          ),

          // ── Day content ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            isToday ? 'Today' : DateFormat('EEEE').format(date),
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold,
                              color: isToday ? AppTheme.accent : Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM').format(date),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: totalColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${dayTotal >= 0 ? "+" : ""}$cur${dayTotal.abs().toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: totalColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction cards
                  ...items.map((item) {
                    final isExpense = item is TransactionModel;
                    final title = isExpense
                        ? (item.category.value?.name ?? 'Unknown')
                        : (item.title.isEmpty ? item.sourceCategory : item.title);
                    final sub = isExpense ? item.description : 'Income';
                    final amount = (item as dynamic).amount as double;
                    final time = DateFormat('h:mm a').format((item as dynamic).date as DateTime);
                    final iconData = isExpense ? getIcon(item.category.value?.icon ?? '') : Icons.south_west;
                    final iconColor = isExpense ? fromHex(item.category.value?.colorHex ?? '#FFFFFF') : AppTheme.success;

                    return Dismissible(
                      key: Key(isExpense ? 'tl_tx_${item.id}' : 'tl_inf_${item.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.only(right: 16),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete, color: Colors.white, size: 18),
                      ),
                      onDismissed: (_) {
                        if (isExpense) provider.deleteTransaction(item.id);
                        else provider.deleteInflow(item.id);
                      },
                      child: GestureDetector(
                        onTap: isExpense ? () => onEditTx(item as TransactionModel) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
                              child: Icon(iconData, size: 16, color: iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text(
                                sub.isNotEmpty ? '$time · $sub' : time,
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ])),
                            const SizedBox(width: 8),
                            if (isExpense && (item as TransactionModel).attachmentPath.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => AttachmentViewer.open(context, item.attachmentPath),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.attachmentPath.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                                    size: 13, color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              '${isExpense ? "−" : "+"}$cur${amount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isExpense ? AppTheme.error : AppTheme.success),
                            ),
                            if (isExpense) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.edit, size: 12, color: AppTheme.textMuted),
                            ],
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
