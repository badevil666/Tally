import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/inflow_model.dart';
import '../data/models/pending_transaction_model.dart';
import '../data/models/piggy_bank_model.dart';
import 'notification_service.dart';

/// Top-level entry point called by the telephony package when an SMS arrives
/// and the app is not in the foreground. Runs in a background isolate.
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  SmsService.onMessage(message);
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static void Function(PendingTransactionModel pt)? onPendingAdded;

  // ── Amount ───────────────────────────────────────────────────────────────────
  // Matches: Rs 466.00 · Rs.466 · INR 466.00 · ₹466 · ₹ 466.00 · Rs466
  static final _amountPattern = RegExp(
    r'(?:rs\.?\s*|inr\s*|₹\s*)(\d[\d,]*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // ── Debit detection ──────────────────────────────────────────────────────────
  // Returns true only if the SMS is clearly a spend/debit, not a credit/refund.
  static bool _isDebitSms(String lower) {
    // Explicit credit signals → not a spend
    if (RegExp(
      r'\b(credited|credit to account|refund(ed)?|cashback|received from|'
      r'deposited|added to wallet|money added)\b',
    ).hasMatch(lower)) {
      return false;
    }

    // Debit / payment signals — covers all major Indian bank patterns
    return RegExp(
      r'\b('
      // Standard bank debit
      r'debited|debit|'
      // UPI payments (Federal Bank, IndusInd, IDFC, etc.)
      r'sent via upi|sent to|'
      // HDFC / Axis / Yes / Kotak credit-card or debit-card
      r'paid to|you.{0,4}paid|'
      r'payment (of|made|done|successful)|'
      // ATM
      r'withdrawn|withdrawal|'
      // POS / card swipe
      r'purchase|pos (txn|debit|transaction)|'
      r'charged|'
      // Paytm / wallet
      r'spent|transferred to|'
      // NEFT / IMPS outward
      r'transfer (of|to)\b'
      r')\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  // ── Merchant extraction ──────────────────────────────────────────────────────
  // Stop-lookahead: stop grabbing merchant chars at these tokens / punctuation.
  static const _stop =
      r'(?:\s+on\b|\s+ref\b|\s+avl\b|\s+bal\b|\s+a\/c\b|\s+rrn\b'
      r'|\s+via\b|\s+from\b|\s+for\b'
      r'|[.\-,](?:\s|$)|[.\-,][A-Z]'  // period/dash followed by space or upper = boundary
      r'|\bref[:\s]|\brrn[:\s]'
      r'|$)';

  // Merchant character class
  static const _mc = r"[A-Za-z0-9][\w\s\-&.']*?";

  static String _extractMerchant(String body) {
    // 1. VPA — "VPA merchant@bank" or "UPI:merchant@bank"
    for (final pat in [
      RegExp(r'\bVPA\s+([\w.\-]+)@', caseSensitive: false),
      RegExp(r'\bUPI[:\s]+([\w.\-]+)@', caseSensitive: false),
    ]) {
      final m = pat.firstMatch(body);
      if (m != null) {
        final prefix = m.group(1) ?? '';
        if (prefix.isNotEmpty) return _toTitleCase(prefix.replaceAll(RegExp(r'[.\-_]'), ' '));
      }
    }

    // NOTE: patterns below use normal strings (not r'...') so $_mc and $_stop
    // are properly interpolated into the regex.

    // 2. "trf to <Merchant>" — SBI style
    final trfMatch = RegExp('\\btrf\\s+to\\s+($_mc)$_stop', caseSensitive: false).firstMatch(body);
    if (trfMatch != null) {
      final m = trfMatch.group(1)?.trim() ?? '';
      if (m.isNotEmpty) return _toTitleCase(m);
    }

    // 3. "to <Merchant>" — Federal Bank, HDFC, Axis, Kotak, most UPI banks
    //    Negative lookahead skips "to your account / to a/c" (internal transfers)
    final toMatch = RegExp(
      '\\bto\\s+(?!your\\b|a\\/c\\b|account\\b)($_mc)$_stop',
      caseSensitive: false,
    ).firstMatch(body);
    if (toMatch != null) {
      final m = toMatch.group(1)?.trim() ?? '';
      if (m.isNotEmpty) return _toTitleCase(m);
    }

    // 4. "at <Merchant>" — POS / card swipe
    final atMatch = RegExp('\\bat\\s+($_mc)$_stop', caseSensitive: false).firstMatch(body);
    if (atMatch != null) {
      final m = atMatch.group(1)?.trim() ?? '';
      if (m.isNotEmpty) return _toTitleCase(m);
    }

    // 5. "for <Merchant>"
    final forMatch = RegExp('\\bfor\\s+($_mc)$_stop', caseSensitive: false).firstMatch(body);
    if (forMatch != null) {
      final m = forMatch.group(1)?.trim() ?? '';
      if (m.isNotEmpty) return _toTitleCase(m);
    }

    // 6. Fallback
    final lower = body.toLowerCase();
    if (lower.contains('upi')) return 'UPI Payment';
    if (lower.contains('neft')) return 'NEFT Transfer';
    if (lower.contains('imps')) return 'IMPS Transfer';
    if (lower.contains('atm') || lower.contains('withdrawn')) return 'ATM Withdrawal';
    return 'Unknown Merchant';
  }

  static String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  // ── Main handler ─────────────────────────────────────────────────────────────
  static void onMessage(SmsMessage message) async {
    final body = message.body ?? '';
    final lower = body.toLowerCase();

    if (!_isDebitSms(lower)) return;

    final match = _amountPattern.firstMatch(body);
    if (match == null) return;

    final amountStr = match.group(1) ?? '';
    final amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    final merchant = _extractMerchant(body);

    final isar = await _openIsar();
    final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF;
    final pt = await _savePending(isar, body, amount, merchant, notifId);
    onPendingAdded?.call(pt);
    final categories = await _loadCategories(isar);

    NotificationService.showTransactionAlert(
      id: notifId,
      title: 'New Transaction Detected',
      body: '${_formatAmount(amount)} at $merchant — add to Keep?',
      pendingTransactionId: pt.id,
      categories: categories,
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) return '₹${amount.toStringAsFixed(0)}';
    return '₹${amount.toStringAsFixed(2)}';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.getInstance() ?? await Isar.open(
      [
        BudgetModelSchema, CategoryModelSchema, TransactionModelSchema,
        InflowModelSchema, PendingTransactionModelSchema, PiggyBankEntryModelSchema,
      ],
      directory: dir.path,
    );
  }

  static Future<PendingTransactionModel> _savePending(
      Isar isar, String body, double amount, String merchant, int notifId) async {
    final pt = PendingTransactionModel()
      ..amount = amount
      ..merchantName = merchant
      ..rawBody = body
      ..timestamp = DateTime.now()
      ..notificationId = notifId;

    await isar.writeTxn(() async {
      await isar.pendingTransactionModels.put(pt);
    });
    return pt;
  }

  static Future<List<({int id, String name})>> _loadCategories(Isar isar) async {
    final cats = await isar.categoryModels.where().findAll();
    // Variable (lifestyle) categories first — more likely to be relevant for
    // UPI/debit SMS. Within each group, higher-limit categories come first.
    cats.sort((a, b) {
      if (a.type != b.type) {
        return a.type == CategoryType.variable ? -1 : 1;
      }
      return b.limit.compareTo(a.limit);
    });
    return cats.map((c) => (id: c.id, name: c.name)).toList();
  }

  static Future<void> init() async {
    final permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    debugPrint('[SmsService] permissions granted: $permissionsGranted');
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: onMessage,
        onBackgroundMessage: backgroundMessageHandler,
      );
      debugPrint('[SmsService] listening for incoming SMS');
    }
  }
}
