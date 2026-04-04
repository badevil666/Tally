import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../logic/providers/budget_provider.dart';
import '../../services/seed_service.dart';
import '../../data/models/category_model.dart';
import '../../core/theme/app_theme.dart';
import 'smart_budget_screen.dart';

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

// ─── Spending Circle ─────────────────────────────────────────────────────────

class _SpendingCircle extends StatelessWidget {
  final String label;
  final double spent;
  final double limit;
  final double percentage;
  final Color color;
  final String currencySymbol;

  const _SpendingCircle({
    required this.label, required this.spent, required this.limit,
    required this.percentage, required this.color, required this.currencySymbol,
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
              Text('$currencySymbol${spent.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text('/ $currencySymbol${limit.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ),
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

// ─── Layout 1: Currency-note cards (3 per row) ───────────────────────────────

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
        final itemH = itemW / 0.72;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cats.map((d) => SizedBox(
            width: itemW,
            height: itemH,
            child: _BillCard(d: d, currencySymbol: currencySymbol),
          )).toList(),
        );
      },
    );
  }
}

// ── Decorative note background painter ───────────────────────────────────────

class _NotePainter extends CustomPainter {
  final Color color;
  _NotePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Security thread strip (left edge) ────────────────────────────────
    final threadPaint = Paint()..color = color.withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 5, size.height),
        const Radius.circular(2),
      ),
      threadPaint,
    );

    // ── Fine diagonal hatching lines ──────────────────────────────────────
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    const spacing = 8.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }

    // ── Corner ornament circles ───────────────────────────────────────────
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const r = 5.0;
    const m = 6.0;
    for (final offset in [
      Offset(m + r, m + r),
      Offset(size.width - m - r, m + r),
      Offset(m + r, size.height - m - r),
      Offset(size.width - m - r, size.height - m - r),
    ]) {
      canvas.drawCircle(offset, r, dotPaint);
      canvas.drawCircle(offset, 2, Paint()..color = color.withValues(alpha: 0.2));
    }

    // ── Top and bottom micro-border lines ─────────────────────────────────
    final borderLinePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 0.6;
    canvas.drawLine(const Offset(14, 10), Offset(size.width - 14, 10), borderLinePaint);
    canvas.drawLine(Offset(14, size.height - 10), Offset(size.width - 14, size.height - 10), borderLinePaint);
  }

  @override
  bool shouldRepaint(_NotePainter old) => old.color != color;
}

// ── Currency note card ────────────────────────────────────────────────────────

class _BillCard extends StatefulWidget {
  final _CatData d;
  final String currencySymbol;
  const _BillCard({required this.d, required this.currencySymbol});

  @override
  State<_BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<_BillCard> with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.55).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _updateBlink();
  }

  @override
  void didUpdateWidget(_BillCard old) {
    super.didUpdateWidget(old);
    _updateBlink();
  }

  void _updateBlink() {
    final limit = widget.d.cat.limit;
    final overBudget = limit > 0 && widget.d.spent > limit;
    if (overBudget) {
      if (!_blinkCtrl.isAnimating) _blinkCtrl.repeat(reverse: true);
    } else {
      _blinkCtrl.stop();
      _blinkCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final currencySymbol = widget.currencySymbol;
    final limit = d.cat.limit;
    final overBudget = limit > 0 && d.spent > limit;
    final noteColor = overBudget ? AppTheme.error : d.color;
    final balance = limit > 0 ? (limit - d.spent) : 0.0;

    // Text is bright white when fill is high (hard to read dark text on filled bg)
    final fillAlpha = d.pct.clamp(0.0, 1.0);
    final textColor = Color.lerp(Colors.white70, Colors.white, fillAlpha)!;
    final mutedTextColor = Color.lerp(AppTheme.textMuted, Colors.white70, fillAlpha)!;

    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (context, child) => Opacity(
        opacity: overBudget ? _blinkAnim.value : 1.0,
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Base ─────────────────────────────────────────────────────
            Container(color: AppTheme.cardSurface),

            // ── Decorative note texture ───────────────────────────────────
            CustomPaint(painter: _NotePainter(noteColor)),

            // ── Solid fill — rises from bottom proportional to spending ───
            if (d.pct > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: d.pct.clamp(0.0, 1.0),
                  child: Container(color: noteColor.withValues(alpha: 0.55)),
                ),
              ),

            // ── Fine border ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: overBudget ? AppTheme.error.withValues(alpha: 0.8) : noteColor.withValues(alpha: 0.3),
                  width: overBudget ? 1.5 : 0.8,
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 10, 7, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon seal
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: noteColor.withValues(alpha: 0.2),
                      border: Border.all(color: noteColor.withValues(alpha: 0.5), width: 0.8),
                    ),
                    child: Icon(_iconData(d.cat.icon), size: 13, color: Colors.white),
                  ),

                  const SizedBox(height: 6),

                  // Category name — always bright
                  Text(
                    d.cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const Spacer(),

                  // Spent amount
                  Text(
                    '$currencySymbol${d.spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Limit line
                  if (limit > 0)
                    Text(
                      '/ $currencySymbol${limit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 8,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 2),

                  // Balance or overspend
                  if (limit > 0)
                    Text(
                      overBudget
                          ? '▲ +$currencySymbol${(d.spent - limit).toStringAsFixed(0)} over'
                          : '▽ $currencySymbol${balance.toStringAsFixed(0)} left',
                      style: TextStyle(
                        fontSize: 8,
                        color: overBudget ? Colors.white : mutedTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'no limit set',
                      style: TextStyle(fontSize: 8, color: mutedTextColor),
                    ),

                  const SizedBox(height: 6),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: d.pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      builder: (context, provider, child) {
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
              // ── Spending circles ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SpendingCircle(label: 'Monthly', spent: monthlySpent, limit: monthlyLimit,
                      percentage: monthlyPct, color: monthlyColor, currencySymbol: provider.currencySymbol),
                  _SpendingCircle(label: 'Today', spent: dailySpent, limit: dailyLimit,
                      percentage: dailyPct, color: dailyColor, currencySymbol: provider.currencySymbol),
                ],
              ).animate().fade(duration: 500.ms).scale(),

              const SizedBox(height: 40),

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
