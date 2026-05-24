import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final daysInMonth =
            DateTime(now.year, now.month + 1, 0).day.toDouble();
        final currentDay = now.day;
        final daysRemaining = (daysInMonth - currentDay).clamp(0, daysInMonth);

        final inflow = provider.totalIncome + provider.totalExtraInflow;
        final outflow = provider.totalExpenses;
        final net = inflow - outflow;

        final totalBudget = provider.dailySpendingAllowance;
        final targetBurn = totalBudget / daysInMonth;
        final actualBurn =
            currentDay > 0 ? provider.totalLifestyleSpent / currentDay : 0.0;
        final burnPct = targetBurn > 0
            ? (actualBurn / targetBurn).clamp(0.0, 2.0)
            : 0.0;
        final burnColor = actualBurn > targetBurn * 1.1
            ? AppTheme.error
            : actualBurn > targetBurn
                ? AppTheme.accent
                : AppTheme.success;
        final burnStatus = actualBurn > targetBurn * 1.1
            ? 'OVER PACE'
            : actualBurn > targetBurn
                ? 'WATCH PACE'
                : 'ON PACE';

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: const Text('Analytics',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('MMMM yyyy').format(now),
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // ── Cash Flow ─────────────────────────────────────────
              _SectionHeader(
                icon: Icons.swap_vert_rounded,
                title: 'Cash Flow',
              ).animate().fade(delay: 50.ms),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _FlowMini(
                        label: 'INCOME',
                        amount: inflow,
                        symbol: provider.currencySymbol,
                        color: AppTheme.success,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FlowMini(
                        label: 'EXPENSE',
                        amount: outflow,
                        symbol: provider.currencySymbol,
                        color: AppTheme.error,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 10),
              _NetCard(
                net: net,
                symbol: provider.currencySymbol,
              ).animate().fade(delay: 150.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 28),

              // ── Burn Rate ─────────────────────────────────────────
              _SectionHeader(
                icon: Icons.local_fire_department_rounded,
                title: 'Burn Rate',
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 12),
              _BurnRateCard(
                actual: actualBurn.toDouble(),
                target: targetBurn,
                burnPct: burnPct.toDouble(),
                color: burnColor,
                status: burnStatus,
                symbol: provider.currencySymbol,
                daysElapsed: currentDay,
                daysRemaining: daysRemaining.toInt(),
              ).animate().fade(delay: 250.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 28),

              // ── Spending Curve ────────────────────────────────────
              _SectionHeader(
                icon: Icons.show_chart_rounded,
                title: 'Spending Curve',
              ).animate().fade(delay: 300.ms),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cumulative lifestyle spend vs. your safe ceiling',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
              _ChartCard(
                spendSpots: _generateCurveSpots(provider),
                ceilingSpots: _generateCeilingSpots(provider),
                daysInMonth: daysInMonth.toInt(),
                today: currentDay,
                symbol: provider.currencySymbol,
              ).animate().fade(delay: 350.ms).scale(begin: const Offset(0.98, 0.98)),
            ],
          ),
        );
      },
    );
  }

  List<FlSpot> _generateCurveSpots(BudgetProvider provider) {
    if (provider.transactions.isEmpty) return [const FlSpot(1, 0)];
    final dailySpends = <int, double>{};
    for (final tx in provider.transactions
        .where((t) => t.category.value?.type == CategoryType.variable)) {
      final day = tx.date.day;
      dailySpends[day] = (dailySpends[day] ?? 0) + tx.amount;
    }
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int i = 1; i <= DateTime.now().day; i++) {
      cumulative += dailySpends[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    return spots;
  }

  List<FlSpot> _generateCeilingSpots(BudgetProvider provider) {
    final baseline =
        provider.totalIncome - provider.savingsGoal - provider.sumOfFixedBills;
    final dailyInflows = <int, double>{};
    for (final inf in provider.inflows) {
      final day = inf.date.day;
      dailyInflows[day] = (dailyInflows[day] ?? 0) + inf.amount;
    }
    final spots = <FlSpot>[];
    double cumulative = baseline;
    for (int i = 1; i <= DateTime.now().day; i++) {
      cumulative += dailyInflows[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    return spots;
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.accentBlue),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight)),
      ],
    );
  }
}

// ─── Cash Flow ───────────────────────────────────────────────────────────────

class _FlowMini extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final Color color;
  final IconData icon;
  const _FlowMini({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.14), AppTheme.cardSurface],
          stops: const [0.0, 0.75],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: symbol,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: amount.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                        letterSpacing: -0.5,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetCard extends StatelessWidget {
  final double net;
  final String symbol;
  const _NetCard({required this.net, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    final color = positive ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive
                  ? Icons.savings_rounded
                  : Icons.priority_high_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NET FLOW',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0)),
                Text('What\'s left of this month',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '-'}$symbol${net.abs().toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

// ─── Burn Rate Card ──────────────────────────────────────────────────────────

class _BurnRateCard extends StatelessWidget {
  final double actual;
  final double target;
  final double burnPct;
  final Color color;
  final String status;
  final String symbol;
  final int daysElapsed;
  final int daysRemaining;

  const _BurnRateCard({
    required this.actual,
    required this.target,
    required this.burnPct,
    required this.color,
    required this.status,
    required this.symbol,
    required this.daysElapsed,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final pctClamped = burnPct.clamp(0.0, 1.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.12), AppTheme.cardSurface],
          stops: const [0.0, 0.75],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status pill + days info
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
              ),
              const Spacer(),
              Text(
                'Day $daysElapsed · $daysRemaining left',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actual amount as the hero
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: symbol,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: actual.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: -1.0,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const TextSpan(
                    text: ' / day',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: $symbol${target.toStringAsFixed(0)} / day',
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),

          const SizedBox(height: 18),

          // Bar with target marker at the 1.0 (100%) point
          LayoutBuilder(builder: (context, c) {
            final fullW = c.maxWidth;
            // The bar maxes out at 1.5x target; target sits at 2/3 of width.
            final targetPos = (1.0 / 1.5) * fullW;
            final fillW = (pctClamped / 1.5) * fullW;
            return SizedBox(
              height: 14,
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 8,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Fill
                  Container(
                    height: 8,
                    width: fillW,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Target tick
                  Positioned(
                    left: targetPos - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Bar legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0',
                  style:
                      TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Text('Target $symbol${target.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              Text('$symbol${(target * 1.5).toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card ──────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<FlSpot> spendSpots;
  final List<FlSpot> ceilingSpots;
  final int daysInMonth;
  final int today;
  final String symbol;

  const _ChartCard({
    required this.spendSpots,
    required this.ceilingSpots,
    required this.daysInMonth,
    required this.today,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    // Compute Y range with headroom so the curve isn't cramped at the top.
    double maxY = 0;
    for (final s in [...spendSpots, ...ceilingSpots]) {
      if (s.y > maxY) maxY = s.y;
    }
    maxY = maxY <= 0 ? 100 : maxY * 1.15;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: maxY / 4,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _fmtCompact(value, symbol),
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (daysInMonth / 5).ceilToDouble(),
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Day ${value.toInt()}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: today.toDouble(),
                      color: Colors.white.withValues(alpha: 0.25),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppTheme.background.withValues(alpha: 0.95),
                    tooltipBorder: const BorderSide(color: Colors.white24),
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        'Day ${s.x.toInt()}\n$symbol${s.y.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spendSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppTheme.accentBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentBlue.withValues(alpha: 0.25),
                          AppTheme.accentBlue.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: ceilingSpots,
                    isCurved: false,
                    color: AppTheme.success,
                    barWidth: 2,
                    dashArray: [6, 5],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.accentBlue, label: 'Spent', filled: true),
              SizedBox(width: 18),
              _LegendDot(color: AppTheme.success, label: 'Safe ceiling', filled: false),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtCompact(double v, String symbol) {
    if (v >= 100000) return '$symbol${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '$symbol${(v / 1000).toStringAsFixed(1)}k';
    return '$symbol${v.toStringAsFixed(0)}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;
  const _LegendDot({required this.color, required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: filled ? null : Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
