import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final pendings = provider.pendingTransactions;
        final totalPending = provider.totalPending;

        return Scaffold(
          appBar: AppBar(title: const Text('Smart Inbox')),
          body: pendings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.success),
                      const SizedBox(height: 24),
                      Text('All Caught Up!', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      const Text('Your vault is perfectly organized.', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ).animate().fade().scale(),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending Total', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                          Text('${provider.currencySymbol}${totalPending.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.accent)),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.1),

                    const SizedBox(height: 32),

                    ...pendings.map((pt) {
                      final isHighlighted = provider.highlightedPendingId == pt.id;
                      return Dismissible(
                        key: Key('pending_${pt.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (dir) => provider.removePendingTransaction(pt.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isHighlighted ? AppTheme.accent.withOpacity(0.12) : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isHighlighted ? AppTheme.accent : AppTheme.accentBlue.withOpacity(0.3),
                              width: isHighlighted ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: Text(pt.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 8),
                                  Text('${provider.currencySymbol}${pt.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.error)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(DateFormat('MMM d, h:mm a').format(pt.timestamp), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: provider.categories.map((cat) {
                                    return GestureDetector(
                                      onTap: () {
                                        provider.categorizePendingTransaction(pt.id, cat.id);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardSurface,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                                        ),
                                        child: Text(cat.name, style: const TextStyle(fontSize: 14)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            ],
                          ),
                        ).animate().fade().slideX(begin: 0.1),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}
