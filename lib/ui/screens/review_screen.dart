import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/inflow_model.dart';

void _showEditTransactionSheet(BuildContext context, BudgetProvider provider, TransactionModel tx) {
  final amountCtrl = TextEditingController(text: tx.amount.toStringAsFixed(0));
  int selectedCategoryId = tx.category.value?.id ?? provider.categories.first.id;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                controller: amountCtrl,
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
                  final selected = cat.id == selectedCategoryId;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryId = cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.accent.withOpacity(0.2) : AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
                      ),
                      child: Text(cat.name, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textLight, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount != null && amount > 0) {
                      provider.updateTransaction(tx.id, amount, selectedCategoryId);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  IconData _getIconData(String name) {
    switch (name) {
      case 'fastfood': return Icons.fastfood;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'checkroom': return Icons.checkroom;
      case 'home_work': return Icons.home_work;
      case 'bolt': return Icons.bolt;
      case 'water_drop': return Icons.water_drop;
      case 'router': return Icons.router;
      case 'smartphone': return Icons.smartphone;
      case 'payments': return Icons.payments;
      default: return Icons.category;
    }
  }

  Color _fromHex(String hexString) {
    if (hexString.isEmpty) return Colors.white;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _exportCsv(BuildContext context, BudgetProvider provider) async {
    List<List<dynamic>> rows = [];
    rows.add(["Date", "Type", "Category/Source", "Title/Description", "Amount"]);

    for (var inf in provider.monthlyInflows) {
      rows.add([DateFormat('yyyy-MM-dd').format(inf.date), "In", inf.sourceCategory, inf.title, inf.amount]);
    }

    for (var tx in provider.monthlyTransactions) {
      rows.add([DateFormat('yyyy-MM-dd').format(tx.date), "Out", tx.category.value?.name ?? 'Unknown', tx.description, tx.amount]);
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
    await Share.shareXFiles([xfile], text: 'Monthly Finance Export');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final net = provider.monthlyNet;
        final monthName = DateFormat('MMMM yyyy').format(provider.selectedMonth);

        List<dynamic> combinedList = [...provider.monthlyInflows, ...provider.monthlyTransactions];
        combinedList.sort((a, b) => b.date.compareTo(a.date));

        // Chart: Budgeted vs Actual — include any category with spending or a limit
        double maxAxisValue = 0;
        List<BarChartGroupData> barGroups = [];
        List<CategoryModel> chartCats = [];
        int index = 0;

        for (var cat in provider.categories) {
          final spent = provider.transactions
              .where((t) => t.category.value?.id == cat.id && t.date.year == provider.selectedMonth.year && t.date.month == provider.selectedMonth.month)
              .fold(0.0, (s, t) => s + t.amount);

          if (spent == 0 && cat.limit <= 0) continue;

          if (cat.limit > maxAxisValue) maxAxisValue = cat.limit;
          if (spent > maxAxisValue) maxAxisValue = spent;

          final rods = <BarChartRodData>[
            if (cat.limit > 0)
              BarChartRodData(toY: cat.limit, color: AppTheme.accentBlue.withOpacity(0.5), width: 12, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(
              toY: spent,
              color: cat.limit > 0 && spent > cat.limit ? AppTheme.error : AppTheme.success,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ];

          barGroups.add(BarChartGroupData(x: index, barRods: rods));
          chartCats.add(cat);
          index++;
        }

        return Scaffold(
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
              // Search Header
              TextField(
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search categories or notes...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF333333))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF333333))),
                ),
              ).animate().fade(duration: 300.ms),

              const SizedBox(height: 24),

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

              const SizedBox(height: 32),

              Text('Budget vs Actual', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)).animate().fade(delay: 200.ms),
              const SizedBox(height: 16),

              // Middle Section: Bar Chart
              Container(
                height: 250,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.cardSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF333333))),
                child: barGroups.isEmpty ? const Center(child: Text('No spending this month', style: TextStyle(color: AppTheme.textMuted))) : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAxisValue * 1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final i = value.toInt();
                            if (i >= 0 && i < chartCats.length) {
                              final cat = chartCats[i];
                              return Padding(padding: const EdgeInsets.only(top: 8), child: Icon(_getIconData(cat.icon), size: 16, color: _fromHex(cat.colorHex)));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ).animate().fade(delay: 300.ms).scale(),


              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ledger History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.accent),
                    onPressed: () => _exportCsv(context, provider),
                  )
                ],
              ).animate().fade(delay: 400.ms),
              const SizedBox(height: 16),

              // Bottom Section: Grouped Transactions
              ...combinedList.map((item) {
                bool isExpense = item is TransactionModel;
                String title = isExpense ? (item.category.value?.name ?? 'Unknown') : (item.title.isEmpty ? item.sourceCategory : item.title);
                String sub = isExpense ? item.description : 'Income';
                double amount = isExpense ? item.amount : item.amount;
                DateTime date = isExpense ? item.date : item.date;

                IconData iconData = isExpense ? _getIconData(item.category.value?.icon ?? '') : Icons.south_west;
                Color iconColor = isExpense ? _fromHex(item.category.value?.colorHex ?? '#FFFFFF') : AppTheme.success;

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
                  onDismissed: (dir) {
                    if (isExpense) provider.deleteTransaction(item.id);
                    else provider.deleteInflow(item.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: ListTile(
                      onTap: isExpense ? () => _showEditTransactionSheet(context, provider, item as TransactionModel) : null,
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.2),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('MMM d').format(date)} ${sub.isNotEmpty ? "• $sub" : ""}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isExpense ? "-" : "+"}${provider.currencySymbol}${amount.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isExpense ? AppTheme.error : AppTheme.success),
                          ),
                          if (isExpense) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fade().slideX(begin: 0.1),
                );
              }),

              const SizedBox(height: 80),
            ],
          )
        );
      },
    );
  }
}
