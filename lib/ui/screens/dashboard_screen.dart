import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';

class _SpendingCircle extends StatelessWidget {
  final String label;
  final double spent;
  final double limit;
  final double percentage;
  final Color color;
  final String currencySymbol;

  const _SpendingCircle({
    required this.label,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      height: 155,
      child: CustomPaint(
        painter: SafeToSpendPainter(percentage: percentage, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '$currencySymbol${spent.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                '/ $currencySymbol${limit.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafeToSpendPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  SafeToSpendPainter({required this.percentage, required this.color, this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final Rect rect = Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth);

    // Track — the unspent remainder
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Spent arc — proportional to percentage
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi, false, trackPaint);
    if (percentage > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * percentage, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SafeToSpendPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final monthlySpent = provider.monthlyExpenseTotal;
        // Use income pool as limit when no category budgets are set
        final monthlyLimit = provider.totalAllocated > 0 ? provider.totalAllocated : provider.totalMonthlyPool;
        final monthlyPct = monthlyLimit > 0 ? (monthlySpent / monthlyLimit).clamp(0.0, 1.0) : 0.0;
        final monthlyColor = monthlyPct < 0.7 ? AppTheme.success : monthlyPct < 0.9 ? AppTheme.accent : AppTheme.error;

        final dailySpent = provider.todayExpenseTotal;
        final dailyLimit = provider.dailySpendingAllowance;
        final dailyPct = dailyLimit > 0 ? (dailySpent / dailyLimit).clamp(0.0, 1.0) : 0.0;
        final dailyColor = dailyPct < 0.7 ? AppTheme.success : dailyPct < 0.9 ? AppTheme.accent : AppTheme.error;

        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SpendingCircle(
                    label: 'Monthly',
                    spent: monthlySpent,
                    limit: monthlyLimit,
                    percentage: monthlyPct,
                    color: monthlyColor,
                    currencySymbol: provider.currencySymbol,
                  ),
                  _SpendingCircle(
                    label: 'Today',
                    spent: dailySpent,
                    limit: dailyLimit,
                    percentage: dailyPct,
                    color: dailyColor,
                    currencySymbol: provider.currencySymbol,
                  ),
                ],
              ).animate().fade(duration: 500.ms).scale(),
              
              const SizedBox(height: 48),
              
              Text('Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)).animate().fade(delay: 200.ms),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final cat = provider.categories[index];
                  double spent = provider.spentInCategory(cat.id);
                  double rem = cat.limit - spent;
                  double progress = cat.limit > 0 ? (spent / cat.limit).clamp(0.0, 1.0) : 0;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black12)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rem: ${provider.currencySymbol}${rem.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.background,
                              color: progress > 0.8 ? AppTheme.error : AppTheme.accent,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        )
                      ],
                    ),
                  ).animate().fade(delay: (300 + (index * 100)).ms).slideY(begin: 0.1, end: 0);
                },
              ),
              
              const SizedBox(height: 48),
              
              Text('Recent Transfers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)).animate().fade(delay: 400.ms),
              const SizedBox(height: 16),
              
              ...provider.transactions.take(5).map((tx) {
                return Dismissible(
                  key: Key('tx_${tx.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    color: AppTheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (dir) {
                    provider.deleteTransaction(tx.id);
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tx.category.value?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(tx.description),
                    trailing: Text('-${provider.currencySymbol}${tx.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error)),
                  ),
                );
              }),

              ...provider.inflows.take(5).map((inf) {
                return Dismissible(
                  key: Key('inflow_${inf.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    color: AppTheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (dir) {
                    provider.deleteInflow(inf.id);
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(inf.title.isEmpty ? inf.sourceCategory : inf.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Added Income'),
                    trailing: Text('+${provider.currencySymbol}${inf.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success)),
                  ),
                );
              }),
              
              const SizedBox(height: 80),

            ],
          ),
        );
      },
    );
  }
}
