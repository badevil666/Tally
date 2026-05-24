import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../../logic/providers/budget_provider.dart';
import '../../services/seed_service.dart';
import '../../services/consent_manager.dart';
import '../../data/models/category_model.dart';
import '../../core/theme/app_theme.dart';
import 'smart_budget_screen.dart';
import 'onboarding_screen.dart' show kPrivacyPolicyUrl;
import '../widgets/banner_ad_widget.dart';

// ─── Painters ────────────────────────────────────────────────────────────────

class SafeToSpendPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  SafeToSpendPainter({required this.percentage, required this.color, this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

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
  bool shouldRepaint(covariant SafeToSpendPainter old) =>
      old.percentage != percentage || old.color != color;
}

class _ConcentricPainter extends CustomPainter {
  final List<_CatData> cats;

  _ConcentricPainter(this.cats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final strokeW = maxR / (cats.length + 1) * 0.6;
    final gap = maxR / (cats.length + 1);

    for (int i = 0; i < cats.length; i++) {
      final r = maxR - (i + 1) * gap;
      final rect = Rect.fromCircle(center: center, radius: r);

      // track
      canvas.drawArc(rect, -pi / 2, 2 * pi, false,
          Paint()
            ..color = cats[i].color.withOpacity(0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round);

      // arc
      if (cats[i].pct > 0) {
        canvas.drawArc(rect, -pi / 2, 2 * pi * cats[i].pct, false,
            Paint()
              ..color = cats[i].color
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricPainter old) => true;
}

// ─── Data helper ─────────────────────────────────────────────────────────────

class _CatData {
  final CategoryModel cat;
  final double spent;
  final double pct;
  final Color color;
  _CatData({required this.cat, required this.spent, required this.pct, required this.color});
}

Color _fromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.isEmpty) return Colors.white;
  final buf = StringBuffer();
  if (cleaned.length == 6) buf.write('ff');
  buf.write(cleaned);
  return Color(int.tryParse(buf.toString(), radix: 16) ?? 0xFFE2E2E2);
}

IconData _iconData(String name) {
  const map = <String, IconData>{
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
  return map[name] ?? Icons.category;
}

// ─── Spending Card ───────────────────────────────────────────────────────────
// Replaces the old _SpendingCircle. Card-style layout with status pill, big
// amount, progress bar, and "left/over" footer — scannable at a glance.

class _SpendingCard extends StatelessWidget {
  final String label;
  final double spent;
  final double limit;
  final double percentage;
  final Color color;
  final String currencySymbol;
  final IconData icon;

  const _SpendingCard({
    required this.label,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.color,
    required this.currencySymbol,
    required this.icon,
  });

  String get _statusText {
    if (percentage >= 1.0) return 'OVER';
    if (percentage >= 0.9) return 'TIGHT';
    if (percentage >= 0.7) return 'WATCH';
    return 'HEALTHY';
  }

  @override
  Widget build(BuildContext context) {
    final pctClamped = percentage.clamp(0.0, 1.0);
    final pctDisplay = (percentage * 100).clamp(0, 999).round();
    final remaining = (limit - spent).clamp(0.0, double.infinity);
    final hasLimit = limit > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            AppTheme.cardSurface,
          ],
          stops: const [0.0, 0.7],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: icon + label + percentage pill ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (hasLimit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pctDisplay%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Big amount ──
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: currencySymbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.65),
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: spent.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: -0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasLimit
                ? 'of $currencySymbol${limit.toStringAsFixed(0)}'
                : 'no limit set',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),

          const SizedBox(height: 12),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasLimit ? pctClamped : 0,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // ── Footer: status + remaining/over ──
          Row(
            children: [
              Text(
                _statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                !hasLimit
                    ? '—'
                    : percentage >= 1.0
                        ? '+$currencySymbol${(spent - limit).toStringAsFixed(0)}'
                        : '$currencySymbol${remaining.toStringAsFixed(0)} left',
                style: TextStyle(
                  color: percentage >= 1.0 ? color : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: percentage >= 1.0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Layout 1: Grouped currency-note cards ───────────────────────────────────

class _GroupedBarsLayout extends StatelessWidget {
  final List<_CatData> cats;
  final String currencySymbol;
  const _GroupedBarsLayout({required this.cats, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final lifestyle = cats.where((d) => d.cat.type == CategoryType.variable).toList();
    final fixed = cats.where((d) => d.cat.type == CategoryType.fixed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lifestyle.isNotEmpty) ...[
          _SectionLabel(label: 'LIFESTYLE'),
          const SizedBox(height: 10),
          _BarsLayout(cats: lifestyle, currencySymbol: currencySymbol),
        ],
        if (fixed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: 'FIXED BILLS'),
          const SizedBox(height: 10),
          _BarsLayout(cats: fixed, currencySymbol: currencySymbol),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Layout 1: Category cards (3 per row) ────────────────────────────────────
// Clean, minimal card with gradient tint, icon chip, spent amount, progress
// bar, and a percentage/status footer. Replaces the older skeuomorphic
// "currency-note" look.

class _BarsLayout extends StatelessWidget {
  final List<_CatData> cats;
  final String currencySymbol;

  const _BarsLayout({required this.cats, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const cols = 3;
        final itemW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        // Slightly less elongated than before — modern card proportions.
        final itemH = itemW / 0.82;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cats.map((d) => SizedBox(
            width: itemW,
            height: itemH,
            child: _CategoryCard(d: d, currencySymbol: currencySymbol),
          )).toList(),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CatData d;
  final String currencySymbol;
  const _CategoryCard({required this.d, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final limit = d.cat.limit;
    final overBudget = limit > 0 && d.spent > limit;
    final accent = overBudget ? AppTheme.error : d.color;
    final pctClamped = d.pct.clamp(0.0, 1.0);
    final pctDisplay = (d.pct * 100).clamp(0, 999).round();
    final balance = limit > 0 ? (limit - d.spent) : 0.0;
    final hasLimit = limit > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: overBudget ? 0.22 : 0.13),
            AppTheme.cardSurface,
          ],
          stops: const [0.0, 0.7],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: overBudget ? 0.55 : 0.22),
          width: overBudget ? 1.2 : 0.8,
        ),
        boxShadow: overBudget
            ? [
                BoxShadow(
                  color: AppTheme.error.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon chip + name ──
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconData(d.cat.icon), size: 13, color: accent),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLight,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Spent amount ──
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: currencySymbol,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: d.spent.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: -0.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Limit subtitle ──
          if (hasLimit)
            Text(
              'of $currencySymbol${limit.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9, height: 1.2),
            )
          else
            const Text(
              'no limit',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),

          const SizedBox(height: 8),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: hasLimit ? pctClamped : 0,
                backgroundColor: accent.withValues(alpha: 0.13),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Footer: percent + remaining/over ──
          Row(
            children: [
              if (hasLimit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pctDisplay%',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  !hasLimit
                      ? ''
                      : overBudget
                          ? '+$currencySymbol${(d.spent - limit).toStringAsFixed(0)}'
                          : '$currencySymbol${balance.toStringAsFixed(0)} left',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: overBudget ? accent : AppTheme.textMuted,
                    fontWeight:
                        overBudget ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Layout 2: Grouped circles ───────────────────────────────────────────────

class _GroupedCirclesLayout extends StatelessWidget {
  final List<_CatData> cats;
  final String currencySymbol;
  const _GroupedCirclesLayout({required this.cats, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final lifestyle = cats.where((d) => d.cat.type == CategoryType.variable).toList();
    final fixed = cats.where((d) => d.cat.type == CategoryType.fixed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lifestyle.isNotEmpty) ...[
          _SectionLabel(label: 'LIFESTYLE'),
          const SizedBox(height: 10),
          _CirclesLayout(cats: lifestyle, currencySymbol: currencySymbol),
        ],
        if (fixed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: 'FIXED BILLS'),
          const SizedBox(height: 10),
          _CirclesLayout(cats: fixed, currencySymbol: currencySymbol),
        ],
      ],
    );
  }
}

// ─── Layout 2: Circles grid ──────────────────────────────────────────────────

class _CirclesLayout extends StatelessWidget {
  final List<_CatData> cats;
  final String currencySymbol;

  const _CirclesLayout({required this.cats, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const cols = 3;
      const hSpacing = 12.0;
      const vSpacing = 16.0;
      final itemW = (constraints.maxWidth - hSpacing * (cols - 1)) / cols;
      final balance_for = (d) => d.cat.limit - d.spent;
      return Wrap(
        spacing: hSpacing,
        runSpacing: vSpacing,
        children: cats.map((d) {
          final balance = balance_for(d);
          return SizedBox(
            width: itemW,
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: SafeToSpendPainter(percentage: d.pct, color: d.color, strokeWidth: 7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconData(d.cat.icon), color: d.color, size: 20),
                          if (d.cat.limit > 0) ...[
                            const SizedBox(height: 2),
                            Text('$currencySymbol${balance.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 9, color: d.color, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(d.cat.name,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

// ─── Layout 3: Grouped concentric ────────────────────────────────────────────

class _GroupedConcentricLayout extends StatelessWidget {
  final List<_CatData> cats;
  const _GroupedConcentricLayout({required this.cats});

  @override
  Widget build(BuildContext context) {
    final lifestyle = cats.where((d) => d.cat.type == CategoryType.variable).toList();
    final fixed = cats.where((d) => d.cat.type == CategoryType.fixed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lifestyle.isNotEmpty) ...[
          _SectionLabel(label: 'LIFESTYLE'),
          const SizedBox(height: 10),
          _ConcentricLayout(cats: lifestyle),
        ],
        if (fixed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: 'FIXED BILLS'),
          const SizedBox(height: 10),
          _ConcentricLayout(cats: fixed),
        ],
      ],
    );
  }
}

// ─── Layout 3: Concentric ────────────────────────────────────────────────────

class _ConcentricLayout extends StatelessWidget {
  final List<_CatData> cats;

  const _ConcentricLayout({required this.cats});

  @override
  Widget build(BuildContext context) {
    // Largest limit = outermost ring
    final sorted = [...cats]..sort((a, b) => b.cat.limit.compareTo(a.cat.limit));

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(painter: _ConcentricPainter(sorted)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sorted.map((d) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(d.cat.name, style: TextStyle(fontSize: 12, color: d.color)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _layoutIndex = 0; // 0=bars, 1=circles, 2=concentric
  static const _layoutIcons = [Icons.bar_chart, Icons.bubble_chart, Icons.donut_large];
  final _bannerKey = GlobalKey();

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      child: Center(child: BannerAdWidget(key: _bannerKey)),
      builder: (context, provider, bannerAd) {
        final monthlySpent = provider.monthlyExpenseTotal;
        final monthlyLimit = provider.totalAllocated > 0 ? provider.totalAllocated : provider.totalMonthlyPool;
        final monthlyPct = monthlyLimit > 0 ? (monthlySpent / monthlyLimit).clamp(0.0, 1.0) : 0.0;
        final monthlyColor = monthlyPct < 0.7 ? AppTheme.success : monthlyPct < 0.9 ? AppTheme.accent : AppTheme.error;

        final dailySpent = provider.todayExpenseTotal;
        final dailyLimit = provider.dailyLimitFor(DateTime.now());
        final dailyPct = dailyLimit > 0 ? (dailySpent / dailyLimit).clamp(0.0, 1.0) : 0.0;
        final dailyColor = dailyPct < 0.7 ? AppTheme.success : dailyPct < 0.9 ? AppTheme.accent : AppTheme.error;

        final catData = provider.categories.map((cat) {
          final spent = provider.spentInCategory(cat.id);
          final pct = cat.limit > 0 ? (spent / cat.limit).clamp(0.0, 1.0) : 0.0;
          final color = _fromHex(cat.colorHex);
          return _CatData(cat: cat, spent: spent, pct: pct, color: color);
        }).toList()
          ..sort((a, b) {
            // Variable (lifestyle) first, then fixed bills
            if (a.cat.type != b.cat.type) {
              return a.cat.type == CategoryType.variable ? -1 : 1;
            }
            // Within same type, higher spending first
            return b.spent.compareTo(a.spent);
          });

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => _showSettings(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 18, color: AppTheme.textMuted),
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SmartBudgetScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🐷', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.currencySymbol}${provider.piggyBankBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Spending cards ──
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SpendingCard(
                        label: 'Monthly',
                        icon: Icons.calendar_month_rounded,
                        spent: monthlySpent,
                        limit: monthlyLimit,
                        percentage: monthlyPct,
                        color: monthlyColor,
                        currencySymbol: provider.currencySymbol,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SpendingCard(
                        label: 'Today',
                        icon: Icons.today_rounded,
                        spent: dailySpent,
                        limit: dailyLimit,
                        percentage: dailyPct,
                        color: dailyColor,
                        currencySymbol: provider.currencySymbol,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 24),
              if (bannerAd != null) bannerAd,
              const SizedBox(height: 24),

              // ── Categories heading + layout switcher ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(3, (i) => GestureDetector(
                      onTap: () => setState(() => _layoutIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _layoutIndex == i ? AppTheme.accent.withOpacity(0.2) : AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _layoutIndex == i ? AppTheme.accent : Colors.transparent),
                        ),
                        child: Icon(_layoutIcons[i], size: 16,
                            color: _layoutIndex == i ? AppTheme.accent : AppTheme.textMuted),
                      ),
                    )),
                  ),
                ],
              ).animate().fade(delay: 200.ms),

              const SizedBox(height: 16),

              // ── Category layout ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(_layoutIndex),
                  child: _layoutIndex == 0
                      ? _GroupedBarsLayout(cats: catData, currencySymbol: provider.currencySymbol)
                      : _layoutIndex == 1
                          ? _GroupedCirclesLayout(cats: catData, currencySymbol: provider.currencySymbol)
                          : _GroupedConcentricLayout(cats: catData),
                ),
              ),

              const SizedBox(height: 48),

              // ── Recent transfers ──
              Text('Recent Transfers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fade(delay: 400.ms),
              const SizedBox(height: 16),

              ...provider.transactions.take(5).map((tx) => Dismissible(
                key: Key('tx_${tx.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  color: AppTheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => provider.deleteTransaction(tx.id),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tx.category.value?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(tx.description),
                  trailing: Text('-${provider.currencySymbol}${tx.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error)),
                ),
              )),

              ...provider.inflows.take(5).map((inf) => Dismissible(
                key: Key('inflow_${inf.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  color: AppTheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => provider.deleteInflow(inf.id),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(inf.title.isEmpty ? inf.sourceCategory : inf.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Added Income'),
                  trailing: Text('+${provider.currencySymbol}${inf.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success)),
                ),
              )),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  static const _defaultKey = 'eod_default';
  String? _eodDefault; // 'piggy' | 'pool' | null = ask each time
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _eodDefault = prefs.getString(_defaultKey);
      _loaded = true;
    });
  }

  Future<void> _setDefault(String? value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_defaultKey);
    } else {
      await prefs.setString(_defaultKey, value);
    }
    setState(() => _eodDefault = value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(children: [
            const Icon(Icons.tune_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            const Text('Preferences',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),

          const SizedBox(height: 24),

          const Text('END-OF-DAY SURPLUS',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          const Text(
              "What should Keep do with leftover daily budget at the end of each day?",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),

          const SizedBox(height: 16),

          if (!_loaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            _PrefTile(
              icon: Icons.touch_app_rounded,
              title: 'Ask me each day',
              subtitle: 'Show a prompt in the Daily Tracker',
              selected: _eodDefault == null,
              color: const Color(0xFFBF5AF2),
              onTap: () => _setDefault(null),
            ),
            const SizedBox(height: 10),
            _PrefTile(
              icon: Icons.savings_rounded,
              title: 'Piggy Bank',
              subtitle: 'Lock surplus as savings — deducted from future daily limits',
              selected: _eodDefault == 'piggy',
              color: AppTheme.accent,
              onTap: () => _setDefault('piggy'),
            ),
            const SizedBox(height: 10),
            _PrefTile(
              icon: Icons.waterfall_chart_rounded,
              title: 'Daily Pool',
              subtitle: 'Spread surplus across remaining days, raising their limits',
              selected: _eodDefault == 'pool',
              color: AppTheme.accentBlue,
              onTap: () => _setDefault('pool'),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _SeedDataButton(),
          const SizedBox(height: 8),
          _HardResetButton(),
          const SizedBox(height: 16),
          const Text('LEGAL',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          _LegalLinkTile(
            icon: Icons.shield_outlined,
            label: 'Privacy Policy',
            onTap: () async {
              final uri = Uri.parse(kPrivacyPolicyUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const _AdPreferencesTile(),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppTheme.textMuted,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SeedDataButton extends StatefulWidget {
  @override
  State<_SeedDataButton> createState() => _SeedDataButtonState();
}

class _SeedDataButtonState extends State<_SeedDataButton> {
  bool _loading = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading || _done ? null : () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardSurface,
            title: const Text('Seed Test Data?'),
            content: const Text('This will add 3 months of realistic transactions, piggy bank entries and income. Existing data is preserved.', style: TextStyle(color: AppTheme.textMuted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Seed', style: TextStyle(color: AppTheme.accent))),
            ],
          ),
        );
        if (confirmed != true) return;
        setState(() => _loading = true);
        final provider = context.read<BudgetProvider>();
        await SeedService.seedAll(provider);
        if (mounted) setState(() { _loading = false; _done = true; });
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: _done ? AppTheme.success : AppTheme.accent,
        side: BorderSide(color: _done ? AppTheme.success : AppTheme.accent.withOpacity(0.4)),
      ),
      icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
          : Icon(_done ? Icons.check_circle_rounded : Icons.science_rounded, size: 18),
      label: Text(_done ? 'Data Seeded!' : 'Seed Realistic Test Data'),
    );
  }
}

class _HardResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardSurface,
            title: const Text('Hard Reset?', style: TextStyle(color: AppTheme.error)),
            content: const Text(
              'This will permanently delete all your budgets, categories, transactions, and savings data.\n\nThis cannot be undone.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        Navigator.pop(context); // close settings sheet
        await context.read<BudgetProvider>().hardReset();
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: AppTheme.error,
        side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
      ),
      icon: const Icon(Icons.delete_forever_rounded, size: 18),
      label: const Text('Hard Reset'),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.color = AppTheme.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : Colors.white10,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: selected ? color : AppTheme.textLight)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? color.withValues(alpha: 0.75)
                              : AppTheme.textMuted,
                          height: 1.4)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 20)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LegalLinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: AppTheme.textLight)),
          ),
          const Icon(Icons.open_in_new, size: 14, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}

class _AdPreferencesTile extends StatefulWidget {
  const _AdPreferencesTile();
  @override
  State<_AdPreferencesTile> createState() => _AdPreferencesTileState();
}

class _AdPreferencesTileState extends State<_AdPreferencesTile> {
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final required = await ConsentManager.isPrivacyOptionsRequired();
    if (mounted) setState(() => _available = required);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return InkWell(
      onTap: () => ConsentManager.showPrivacyOptionsForm(),
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Icon(Icons.ads_click_rounded, size: 18, color: AppTheme.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text('Manage ad preferences',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight)),
          ),
          Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}
