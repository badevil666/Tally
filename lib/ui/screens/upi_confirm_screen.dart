import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:isar_community/isar.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../logic/providers/budget_provider.dart';
import '../../services/upi_service.dart';

/// Confirmation screen for a UPI payment.
///
/// Flow:
///  1. Prefill amount/name from the scanned QR (if available)
///  2. User picks a category, adjusts amount, optionally adds a note
///  3. Tap "Pay" — launches the OS UPI chooser
///  4. Screen switches to "awaiting confirmation" state while user pays
///  5. When user returns, ask "Did the payment succeed?"
///     - Yes → save expense in the chosen category
///     - No  → discard
class UpiConfirmScreen extends StatefulWidget {
  final UpiPaymentIntent intent;
  const UpiConfirmScreen({super.key, required this.intent});

  @override
  State<UpiConfirmScreen> createState() => _UpiConfirmScreenState();
}

enum _Stage { form, awaitingReturn, saving }

class _UpiConfirmScreenState extends State<UpiConfirmScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Id? _selectedCategoryId;
  _Stage _stage = _Stage.form;

  @override
  void initState() {
    super.initState();
    if (widget.intent.amount != null) {
      _amountCtrl.text = widget.intent.amount!.toStringAsFixed(
          widget.intent.amount! == widget.intent.amount!.truncateToDouble()
              ? 0 : 2);
    }
    if (widget.intent.note?.isNotEmpty ?? false) {
      _noteCtrl.text = widget.intent.note!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  bool get _canPay =>
      _amount > 0 &&
      _selectedCategoryId != null &&
      _stage == _Stage.form;

  Future<void> _pay() async {
    HapticFeedback.mediumImpact();
    final uri = UpiService.buildUri(
      vpa: widget.intent.vpa,
      payeeName: widget.intent.displayName,
      amount: _amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    setState(() => _stage = _Stage.awaitingReturn);
    final launched = await UpiService.launchPayment(uri);
    if (!launched && mounted) {
      setState(() => _stage = _Stage.form);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: const Text(
              'No UPI app found. Install Google Pay, PhonePe, or Paytm.'),
        ),
      );
    }
  }

  Future<void> _confirmSuccess(BudgetProvider provider) async {
    HapticFeedback.heavyImpact();
    setState(() => _stage = _Stage.saving);
    final description = _noteCtrl.text.trim().isNotEmpty
        ? 'UPI · ${widget.intent.displayName} — ${_noteCtrl.text.trim()}'
        : 'UPI · ${widget.intent.displayName}';
    await provider.addTransaction(_selectedCategoryId!, _amount, description);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.success,
        content: Text(
            'Logged ${provider.currencySymbol}${_amount.toStringAsFixed(0)} to your budget'),
      ),
    );
  }

  void _confirmFailed() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment discarded — nothing logged.')),
    );
  }

  void _retryLaunch() {
    setState(() => _stage = _Stage.form);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final categories = provider.categories
        .where((c) => c.type == CategoryType.variable)
        .toList();
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_stage == _Stage.form ? 'Pay via UPI' : 'Confirm payment'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: _stage == _Stage.form
              ? _buildForm(provider, categories)
              : _buildAwaitingReturn(provider),
        ),
      ),
    );
  }

  Widget _buildForm(BudgetProvider provider, List<CategoryModel> categories) {
    final locked = widget.intent.amountLocked && widget.intent.amount != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PayeeCard(intent: widget.intent)
              .animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0),
          const SizedBox(height: 24),

          // Amount
          const Text('AMOUNT',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            readOnly: locked,
            autofocus: !locked,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent),
            decoration: InputDecoration(
              prefixText: '${provider.currencySymbol} ',
              prefixStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted),
              hintText: '0',
              border: InputBorder.none,
              suffixIcon: locked
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock_outline,
                          color: AppTheme.textMuted, size: 18),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (locked) ...[
            const Text(
                'Amount is fixed by the merchant QR — not editable',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],

          const SizedBox(height: 24),

          // Category
          const Text('CATEGORY',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            const Text('No spending categories — add one first.',
                style: TextStyle(color: AppTheme.error, fontSize: 13))
          else
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final sel = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategoryId = cat.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.accent : AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(cat.name,
                            style: TextStyle(
                                color: sel ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),

          // Note
          const Text('NOTE (optional)',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLength: 50,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. lunch with team',
              counterText: '',
              filled: true,
              fillColor: AppTheme.cardSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canPay ? _pay : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _canPay ? AppTheme.accent : AppTheme.cardSurface,
                foregroundColor:
                    _canPay ? Colors.black : AppTheme.textMuted,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(
                _amount > 0
                    ? 'Pay ${provider.currencySymbol}${_amount.toStringAsFixed(_amount == _amount.truncateToDouble() ? 0 : 2)}'
                    : 'Enter an amount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'You\'ll be sent to your UPI app to authorize the payment.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingReturn(BudgetProvider provider) {
    final saving = _stage == _Stage.saving;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.payments_rounded,
                color: AppTheme.accent, size: 56),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05),
                  duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 24),
          const Text('Complete payment in your UPI app',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'After you finish, come back and tell us if the payment '
              'to ${widget.intent.displayName} went through.',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),
          if (saving)
            const CircularProgressIndicator(color: AppTheme.accent)
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmSuccess(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                    'Yes — log ${provider.currencySymbol}${_amount.toStringAsFixed(_amount == _amount.truncateToDouble() ? 0 : 2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmFailed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('No — discard'),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _retryLaunch,
              child: const Text('Open UPI app again',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayeeCard extends StatelessWidget {
  final UpiPaymentIntent intent;
  const _PayeeCard({required this.intent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_circle_rounded,
              color: AppTheme.accent, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intent.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(intent.vpa,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Icon(Icons.verified_outlined,
            color: AppTheme.success, size: 18),
      ]),
    );
  }
}
