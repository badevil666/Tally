import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        double totalBudget = provider.dailySpendingAllowance;
        double daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day.toDouble();
        double targetBurnRate = totalBudget / daysInMonth;
        
        int currentDay = DateTime.now().day;
        double actualBurnRate = currentDay > 0 ? provider.totalLifestyleSpent / currentDay : 0;

        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Cash Flow', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accentBlue)).animate().fade(delay: 100.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('In', style: TextStyle(fontSize: 16)),
                        Text('+${provider.currencySymbol}${(provider.totalIncome + provider.totalExtraInflow).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Out', style: TextStyle(fontSize: 16)),
                        Text('-${provider.currencySymbol}${provider.totalExpenses.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.error)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${provider.currencySymbol}${((provider.totalIncome + provider.totalExtraInflow) - provider.totalExpenses).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0),
              
              const SizedBox(height: 48),

              Text('The Burn Rate', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accentBlue)).animate().fade(delay: 200.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                    children: [
                      const TextSpan(text: 'You are spending '),
                      TextSpan(text: '${provider.currencySymbol}${actualBurnRate.toStringAsFixed(0)}/day', style: TextStyle(color: actualBurnRate > targetBurnRate ? AppTheme.error : AppTheme.success, fontWeight: FontWeight.bold)),
                      const TextSpan(text: '. To hit your savings goal, you need to stay under '),
                      TextSpan(text: '${provider.currencySymbol}${targetBurnRate.toStringAsFixed(0)}/day', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
              
              const SizedBox(height: 48),
              
              Text('Spending Curve', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accentBlue)).animate().fade(delay: 300.ms),
              const SizedBox(height: 16),
              
              Container(
                height: 250,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 5,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateCurveSpots(provider),
                        isCurved: true,
                        color: AppTheme.accentBlue,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppTheme.accentBlue.withOpacity(0.1)),
                      ),
                      LineChartBarData(
                        spots: _generateCeilingSpots(provider),
                        isCurved: true,
                        isStepLineChart: true,
                        color: AppTheme.success,
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 400.ms).scale(),
            ],
          ),
        );
      },
    );
  }

  List<FlSpot> _generateCurveSpots(BudgetProvider provider) {
    if (provider.transactions.isEmpty) return [const FlSpot(1, 0)];
    Map<int, double> dailySpends = {};
    for (var tx in provider.transactions.where((t) => t.category.value?.type == CategoryType.variable)) {
      int day = tx.date.day;
      dailySpends[day] = (dailySpends[day] ?? 0) + tx.amount;
    }
    
    List<FlSpot> spots = [];
    double cumulative = 0;
    for (int i = 1; i <= DateTime.now().day; i++) {
      cumulative += dailySpends[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    return spots;
  }

  List<FlSpot> _generateCeilingSpots(BudgetProvider provider) {
    double baseline = provider.totalIncome - provider.savingsGoal - provider.sumOfFixedBills;
    Map<int, double> dailyInflows = {};
    for (var inf in provider.inflows) {
      int day = inf.date.day;
      dailyInflows[day] = (dailyInflows[day] ?? 0) + inf.amount;
    }
    
    List<FlSpot> spots = [];
    double cumulative = baseline;
    for (int i = 1; i <= DateTime.now().day; i++) {
      cumulative += dailyInflows[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    return spots;
  }
}
