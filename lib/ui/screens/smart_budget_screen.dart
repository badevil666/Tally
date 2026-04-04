import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/daily_snapshot.dart';

class SmartBudgetScreen extends StatelessWidget {
  const SmartBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final currency = provider.currencySymbol;
        final snapshots = provider.monthDailyBreakdown;
        final today = snapshots.isNotEmpty && snapshots.first.isToday
            ? snapshots.first
            : null;

        return Scaffold(
          appBar: AppBar(title: const Text('Daily Tracker')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Piggy Bank card ──
              _PiggyBankCard(provider: provider, currency: currency)
                  .animate().fade(duration: 400.ms).slideY(begin: -0.1),

              const SizedBox(height: 20),

              // ── Today's card ──
              if (today != null) ...[
                _TodayCard(snapshot: today, provider: provider, currency: currency)
                    .animate().fade(delay: 100.ms).slideY(begin: -0.1),
                const SizedBox(height: 24),
              ],

              // ── Daily history header ──
              Text('This Month',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fade(delay: 200.ms),
              const SizedBox(height: 12),

              // ── Day rows ──
              ...snapshots.asMap().entries.map((e) {
                final i = e.key;
                final snap = e.value;
                if (snap.isToday) return const SizedBox.shrink();
                return _DayRow(snap: snap, currency: currency)
                    .animate()
                    .fade(delay: (i * 30 + 250).ms)
                    .slideX(begin: 0.05);
              }),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ── Piggy Bank Card ───────────────────────────────────────────────────────────

class _PiggyBankCard extends StatefulWidget {
  final BudgetProvider provider;
  final String currency;
  const _PiggyBankCard({required this.provider, required this.currency});

  @override
  State<_PiggyBankCard> createState() => _PiggyBankCardState();
}

class _PiggyBankCardState extends State<_PiggyBankCard> {
  static const _decidedKey = 'piggy_decision_date';
  static const _defaultKey = 'eod_default';
  bool _bankingToday = false; // true while async add is in progress
  bool _decidedToday = false;
  String? _eodDefault;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    setState(() {
      _decidedToday = prefs.getString(_decidedKey) == today;
      _eodDefault = prefs.getString(_defaultKey);
    });
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// How much of today's limit is still available to bank manually.
  /// = dailyLimit − spent − already banked today
  double _availableSurplus() {
    final provider = widget.provider;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final bankedToday = provider.piggyEntries
        .where((e) => e.amount > 0 && !e.date.isBefore(todayStart))
        .fold(0.0, (s, e) => s + e.amount);
    final limit = provider.dailyLimitFor(today);
    final spent = provider.dailySpentFor(today);
    return (limit - spent - bankedToday).floorToDouble();
  }

  Future<void> _addToday(double surplus) async {
    setState(() => _bankingToday = true);
    await widget.provider.addToPiggyBank(
      surplus,
      note: 'Daily surplus ${DateFormat('MMM d').format(DateTime.now())}',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_decidedKey, _todayKey());
    await prefs.setBool('eod_handled_${_todayKey()}', true);
    if (mounted) setState(() { _bankingToday = false; _decidedToday = true; });
  }

  void _showWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(provider: widget.provider, currency: widget.currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final currency = widget.currency;
    final balance = provider.piggyBankBalance;
    final entries = provider.piggyEntries.where((e) => e.amount > 0).take(3).toList();
    final surplus = _availableSurplus();
    final hasSurplus = surplus > 0 && !_decidedToday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent.withValues(alpha: 0.25), AppTheme.accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Row(children: [
            const Text('🐷', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Piggy Bank',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                Text('$currency${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent)),
              ]),
            ),
            if (balance > 0)
              TextButton.icon(
                onPressed: () => _showWithdrawSheet(context),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ]),

          // ── Today's surplus add section ──────────────────────────────────
          if (hasSurplus || _decidedToday) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            if (_decidedToday)
              Row(children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 15),
                const SizedBox(width: 6),
                const Text("Today's surplus banked",
                    style: TextStyle(color: AppTheme.success, fontSize: 13)),
                const Spacer(),
                if (_eodDefault != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _eodDefault == 'piggy' ? 'Auto → 🐷' : 'Auto → Pool',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
              ])
            else ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Today's leftover",
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text('$currency${surplus.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight)),
                ]),
                if (_eodDefault != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _eodDefault == 'piggy' ? 'Auto → 🐷 at midnight' : 'Auto → Pool at midnight',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _bankingToday ? null : () => _addToday(surplus),
                icon: _bankingToday
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('🐷', style: TextStyle(fontSize: 14)),
                label: Text(
                  _bankingToday
                      ? 'Banking...'
                      : 'Add $currency${surplus.toStringAsFixed(0)} to Piggy',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ],

          // ── Recent deposits ──────────────────────────────────────────────
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM d').format(e.date),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      Text('+$currency${e.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Withdraw Sheet ────────────────────────────────────────────────────────────

class _WithdrawSheet extends StatefulWidget {
  final BudgetProvider provider;
  final String currency;
  const _WithdrawSheet({required this.provider, required this.currency});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.provider.piggyBankBalance;
    final fmt = NumberFormat('#,##0');

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Transfer from Piggy 🐷',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 4),
          Text('Available: ${widget.currency}${fmt.format(balance)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accent),
            decoration: InputDecoration(
              prefixText: '${widget.currency} ',
              prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              border: InputBorder.none,
              hintText: '0',
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 4),
          const Text('This money will be added back to your spendable pool,\nraising your daily limits for the rest of the month.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_ctrl.text) ?? 0;
              if (amount <= 0) {
                setState(() => _error = 'Enter a valid amount');
                return;
              }
              if (amount > balance) {
                setState(() => _error = 'Not enough in piggy bank');
                return;
              }
              HapticFeedback.heavyImpact();
              await widget.provider.withdrawFromPiggy(amount);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Transfer to Pool', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ── Today Card ────────────────────────────────────────────────────────────────

class _TodayCard extends StatefulWidget {
  final DailySnapshot snapshot;
  final BudgetProvider provider;
  final String currency;

  const _TodayCard(
      {required this.snapshot, required this.provider, required this.currency});

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  String? _eodDefault; // 'piggy' | 'pool' | null

  static const _defaultKey = 'eod_default';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _eodDefault = prefs.getString(_defaultKey));
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.snapshot;
    final surplus = snap.surplus;
    final isOver = surplus < 0;
    final color = isOver ? AppTheme.error : AppTheme.success;
    final pct = snap.limit > 0 ? (snap.spent / snap.limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(children: [
              if (_eodDefault != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _eodDefault == 'piggy' ? 'Auto → 🐷' : 'Auto → Pool',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOver ? 'Over Budget' : 'On Track',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),

          // ── Progress bar ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white12,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          // ── Numbers row ────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Stat(label: 'Limit', value: '${widget.currency}${snap.limit.toStringAsFixed(0)}', color: AppTheme.textLight),
            _Stat(label: 'Spent', value: '${widget.currency}${snap.spent.toStringAsFixed(0)}', color: AppTheme.error),
            _Stat(
              label: isOver ? 'Over by' : 'Surplus',
              value: '${widget.currency}${surplus.abs().toStringAsFixed(0)}',
              color: color,
              bold: true,
            ),
          ]),

          // ── Surplus / auto-action note ─────────────────────────────────
          if (!isOver && surplus > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _eodDefault == 'piggy'
                      ? '🐷  Auto-banks to Piggy at end of day'
                      : _eodDefault == 'pool'
                          ? '🔄  Auto-spreads to Daily Pool at end of day'
                          : '💡  Set auto-behavior in Dashboard → ⚙️',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

// ── Day Row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final DailySnapshot snap;
  final String currency;
  const _DayRow({required this.snap, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isOver = snap.isOverspent;
    final pct = snap.limit > 0 ? (snap.spent / snap.limit).clamp(0.0, 1.0) : 0.0;
    final color = isOver ? AppTheme.error : snap.spent == 0 ? AppTheme.textMuted : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        SizedBox(
          width: 52,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('EEE').format(snap.date),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            Text(DateFormat('d MMM').format(snap.date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$currency${snap.spent.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            snap.spent == 0
                ? 'No spend'
                : isOver
                    ? '-$currency${snap.surplus.abs().toStringAsFixed(0)}'
                    : '+$currency${snap.surplus.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ]),
      ]),
    );
  }
}

// ── Stat widget ───────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _Stat({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 14)),
    ]);
  }
}
