import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/inflow_model.dart';
import '../data/models/pending_transaction_model.dart';
import 'notification_service.dart';

/// Top-level entry point called by the telephony package when an SMS arrives
/// and the app is not in the foreground. Runs in a background isolate.
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  SmsService.onMessage(message);
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  /// Called immediately after a pending transaction is saved, so the UI can
  /// update in real time without a reload.
  static void Function(PendingTransactionModel pt)? onPendingAdded;

  // Regex stop-lookahead: stop capturing at these noise keywords or punctuation.
  // Must be a normal string (not raw) so it can be interpolated into patterns below.
  static const _stop = r'(?:\s+on\b|\s+ref\b|\s+avl\b|\s+bal\b|\s+a/c\b|\s+rrn\b|[.,]|$)';

  // Merchant character class: alphanumeric, spaces, hyphens, &, ., apostrophes.
  static const _mc = r"[A-Za-z0-9][\w\s\-&.']*?";

  static String _extractMerchant(String text) {
    // 1. VPA: "VPA merchant@bank" — take the prefix before @
    final vpaMatch = RegExp(r'\bVPA\s+([\w.\-]+)@', caseSensitive: false).firstMatch(text);
    if (vpaMatch != null) {
      final vpaPrefix = vpaMatch.group(1) ?? '';
      if (vpaPrefix.isNotEmpty) {
        return _toTitleCase(vpaPrefix.replaceAll(RegExp(r'[.\-_]'), ' '));
      }
    }

    // 2. "trf to <Merchant>" — SBI style
    final trfMatch = RegExp('\\btrf\\s+to\\s+($_mc)$_stop', caseSensitive: false).firstMatch(text);
    if (trfMatch != null) {
      final m = trfMatch.group(1)?.trim() ?? '';
      if (m.isNotEmpty) return _toTitleCase(m);
    }

    // 3. "at / to / for <Merchant>"
    final patterns = [
      RegExp('\\bat\\s+($_mc)$_stop', caseSensitive: false),
      RegExp('\\bto\\s+($_mc)$_stop', caseSensitive: false),
      RegExp('\\bfor\\s+($_mc)$_stop', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final m = match.group(1)?.trim() ?? '';
        if (m.isNotEmpty) return _toTitleCase(m);
      }
    }

    // 4. Fallback by transaction type
    final lower = text.toLowerCase();
    if (lower.contains('upi')) return 'UPI Payment';
    if (lower.contains('neft') || lower.contains('imps')) return 'Bank Transfer';
    return 'Unknown Merchant';
  }

  static String _toTitleCase(String s) {
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  static void onMessage(SmsMessage message) async {
    final text = message.body?.toLowerCase() ?? '';
    if (text.contains('debit') || text.contains('spent') || text.contains('transaction') || text.contains('withdrawn')) {
      final exp = RegExp(r'(?:rs\.?|inr|\$)\s?(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
      final match = exp.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1) ?? '';
        final amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0;
        final merchant = _extractMerchant(message.body ?? '');

        final isar = await _openIsar();
        final pt = await _savePending(isar, text, amount, merchant);
        onPendingAdded?.call(pt);
        final categories = await _loadCategories(isar);

        NotificationService.showTransactionAlert(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Pending Transaction Detected',
          body: 'Did you just spend $amountStr at $merchant?',
          pendingTransactionId: pt.id,
          categories: categories,
        );
      }
    }
  }

  static Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.getInstance() ?? await Isar.open(
      [BudgetModelSchema, CategoryModelSchema, TransactionModelSchema, InflowModelSchema, PendingTransactionModelSchema],
      directory: dir.path,
    );
  }

  static Future<PendingTransactionModel> _savePending(Isar isar, String text, double amount, String merchant) async {
    final pt = PendingTransactionModel()
      ..amount = amount
      ..merchantName = merchant
      ..rawBody = text
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.pendingTransactionModels.put(pt);
    });
    return pt;
  }

  static Future<List<({int id, String name})>> _loadCategories(Isar isar) async {
    final cats = await isar.categoryModels.where().findAll();
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
