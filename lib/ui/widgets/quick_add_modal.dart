import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../../logic/providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import 'package:isar/isar.dart';

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Id? _selectedCategoryId;
  String? _attachmentPath; // local path of picked file (before saving)

  Future<void> _pickAttachment() async {
    // file_picker uses Android's SAF — the system handles permissions internally.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _attachmentPath = result.files.single.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final categories = provider.categories.where((c) => c.type == CategoryType.variable).toList();
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Add', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accent),
            decoration: InputDecoration(
              prefixText: '${provider.currencySymbol} ',
              prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              border: InputBorder.none,
              hintText: '0',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                bool isSelected = _selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'What was this for?',
              filled: true,
              fillColor: AppTheme.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // ── Attachment picker ───────────────────────────────────────────
          _attachmentPath == null
              ? GestureDetector(
                  onTap: _pickAttachment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.attach_file, color: AppTheme.textMuted, size: 20),
                      SizedBox(width: 10),
                      Text('Attach bill or receipt',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                    ]),
                  ),
                )
              : _AttachmentPreview(
                  path: _attachmentPath!,
                  onRemove: () => setState(() => _attachmentPath = null),
                ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_amountCtrl.text.isNotEmpty && _selectedCategoryId != null) {
                HapticFeedback.heavyImpact();
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                if (amount <= 0) return;

                // Capture piggy balance before — addTransaction auto-deducts if overspent
                final piggyBefore = provider.piggyBankBalance;
                await provider.addTransaction(
                  _selectedCategoryId!, amount, _noteCtrl.text,
                  attachmentSourcePath: _attachmentPath,
                );
                final piggyAfter = provider.piggyBankBalance;
                final deducted = (piggyBefore - piggyAfter).clamp(0.0, double.infinity);

                if (deducted > 0 && context.mounted) {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  final newDailyLimit = provider.dailyLimitFor(tomorrow);
                  final remainingMonthly = provider.remainingToSpend;
                  Navigator.pop(context); // close modal first
                  if (context.mounted) {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _PiggyRaidSheet(
                        deducted: deducted,
                        piggyBefore: piggyBefore,
                        piggyAfter: piggyAfter,
                        newDailyLimit: newDailyLimit,
                        remainingMonthly: remainingMonthly,
                        currency: provider.currencySymbol,
                      ),
                    );
                  }
                  return;
                }

                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Save Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Piggy Raid Bottom Sheet ───────────────────────────────────────────────────

// ── Attachment Preview (inside modal) ────────────────────────────────────────

class _AttachmentPreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _AttachmentPreview({required this.path, required this.onRemove});

  bool get _isPdf => path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        // Thumbnail or PDF icon
        GestureDetector(
          onTap: () => AttachmentViewer.open(context, path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isPdf
                ? Container(
                    width: 52, height: 52,
                    color: Colors.red.withValues(alpha: 0.15),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                  )
                : Image.file(File(path), width: 52, height: 52, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => AttachmentViewer.open(context, path),
              child: const Text('Tap to preview',
                  style: TextStyle(color: AppTheme.accent, fontSize: 11)),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ── Attachment Viewer ─────────────────────────────────────────────────────────

class AttachmentViewer {
  static bool _isPdf(String path) => path.toLowerCase().endsWith('.pdf');

  static Future<void> open(BuildContext context, String path) async {
    if (_isPdf(path)) {
      await OpenFilex.open(path);
    } else {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 16, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ),
      );
    }
  }
}

class _PiggyRaidSheet extends StatelessWidget {
  final double deducted;
  final double piggyBefore;
  final double piggyAfter;
  final double newDailyLimit;
  final double remainingMonthly;
  final String currency;

  const _PiggyRaidSheet({
    required this.deducted,
    required this.piggyBefore,
    required this.piggyAfter,
    required this.newDailyLimit,
    required this.remainingMonthly,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final pct = piggyBefore > 0 ? deducted / piggyBefore : 1.0;
    final piggyWiped = piggyAfter <= 0;

    final String emoji;
    final String headline;
    final String quip;
    final Color moodColor;

    if (piggyWiped) {
      emoji = '💀';
      headline = 'Piggy Bank Wiped Out!';
      quip = 'You demolished every last coin. Piggy has nothing left and is absolutely devastated. Start saving again — piggy is watching.';
      moodColor = AppTheme.error;
    } else if (pct >= 0.75) {
      emoji = '🤬';
      headline = 'Piggy is FURIOUS!!';
      quip = 'You raided ${(pct * 100).toStringAsFixed(0)}% of the savings! Piggy is shaking with rage. Every coin counts — be careful next time!';
      moodColor = AppTheme.error;
    } else if (pct >= 0.4) {
      emoji = '😤';
      headline = 'Piggy is Angry!';
      quip = 'A massive chunk of savings just vanished. Piggy worked hard for that. You\'ve got some explaining to do!';
      moodColor = Colors.orange;
    } else if (pct >= 0.1) {
      emoji = '😢';
      headline = 'Piggy is Sad…';
      quip = 'That was saved money. Piggy is heartbroken and quietly crying in the corner. Try to make it up tomorrow!';
      moodColor = Colors.amber;
    } else {
      emoji = '😕';
      headline = 'Oops, Piggy Felt That';
      quip = 'Just a tiny nibble from the savings — but piggy definitely noticed. Be careful!';
      moodColor = AppTheme.textMuted;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // Animated emoji
          Text(emoji, style: const TextStyle(fontSize: 72))
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 400.ms, curve: Curves.elasticOut)
              .then()
              .shake(hz: 3, duration: 400.ms),

          const SizedBox(height: 12),

          Text(headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: moodColor))
              .animate().fade(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 8),

          Text(quip,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5))
              .animate().fade(delay: 300.ms),

          const SizedBox(height: 24),

          // ── Stats row ──────────────────────────────────────────────────
          Row(children: [
            _StatTile(
              label: 'Taken from 🐷',
              value: '-$currency${fmt.format(deducted)}',
              valueColor: AppTheme.error,
              delay: 350,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Piggy left',
              value: piggyWiped ? 'Empty 😭' : '$currency${fmt.format(piggyAfter)}',
              valueColor: piggyWiped ? AppTheme.error : AppTheme.accent,
              delay: 420,
            ),
          ]).animate().fade(delay: 350.ms).slideY(begin: 0.15),

          const SizedBox(height: 12),

          // ── Piggy progress bar ─────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Piggy Bank', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text(
                  piggyBefore > 0
                      ? '${((piggyAfter / piggyBefore) * 100).clamp(0, 100).toStringAsFixed(0)}% remaining'
                      : 'empty',
                  style: TextStyle(color: moodColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: piggyBefore > 0 ? (piggyAfter / piggyBefore).clamp(0, 1) : 0),
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => LinearProgressIndicator(
                    value: v,
                    backgroundColor: AppTheme.error.withValues(alpha: 0.25),
                    color: piggyWiped ? AppTheme.error : AppTheme.accent,
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ).animate().fade(delay: 450.ms),

          const SizedBox(height: 12),

          // ── New daily limit card ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(children: [
              const Text('📅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('New daily limit from tomorrow',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    newDailyLimit > 0
                        ? '$currency${NumberFormat('#,##0.##').format(newDailyLimit)} / day'
                        : 'Budget exhausted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: newDailyLimit <= 0 ? AppTheme.error : AppTheme.textLight,
                    ),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Monthly left', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text(
                  '$currency${fmt.format(remainingMonthly)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                ),
              ]),
            ]),
          ).animate().fade(delay: 520.ms).slideY(begin: 0.15),

          const SizedBox(height: 24),

          // ── Button ─────────────────────────────────────────────────────
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: moodColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              piggyWiped ? 'I\'ll do better, I promise 🙏' : 'I\'m sorry, Piggy 🐷',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final int delay;

  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: valueColor)),
        ]),
      ),
    );
  }
}
