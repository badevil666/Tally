import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/inflow_model.dart';
import '../data/models/pending_transaction_model.dart';

/// Top-level handler for notification action taps when the app is in the background.
/// Runs in a separate isolate — cannot access static state from NotificationService.
/// Writes directly to Isar; BudgetProvider reloads when the app resumes.
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) async {
  final payload = response.payload;
  final actionId = response.actionId;
  if (payload == null || actionId == null || !actionId.startsWith('cat_')) return;

  final ptId = int.tryParse(payload);
  final categoryId = int.tryParse(actionId.replaceFirst('cat_', ''));
  if (ptId == null || categoryId == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final isar = Isar.getInstance() ?? await Isar.open(
    [BudgetModelSchema, CategoryModelSchema, TransactionModelSchema,
     InflowModelSchema, PendingTransactionModelSchema],
    directory: dir.path,
  );

  final pt = await isar.pendingTransactionModels.get(ptId);
  final cat = await isar.categoryModels.get(categoryId);
  if (pt == null || cat == null) return;

  final tx = TransactionModel()
    ..amount = pt.amount
    ..description = pt.merchantName.isEmpty ? 'SMS Transaction' : pt.merchantName
    ..date = pt.timestamp;
  tx.category.value = cat;

  await isar.writeTxn(() async {
    await isar.transactionModels.put(tx);
    await tx.category.save();
    await isar.pendingTransactionModels.delete(ptId);
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Set from main() after BudgetProvider is created.
  /// Used when the app is in the foreground — routes through BudgetProvider
  /// so the UI updates immediately.
  static Future<void> Function(int ptId, int categoryId)? onCategorize;

  /// Set from main(). Called when the user taps the notification body.
  /// Should navigate to Inbox and highlight the pending entry.
  static void Function(int ptId)? onNotificationTap;

  /// Set from main(). Called after app resumes from background so
  /// BudgetProvider can reload pending transactions categorized via
  /// the background notification handler.
  static Future<void> Function()? onResume;

  /// Registers response callbacks only. Safe to call before runApp — no dialogs.
  static Future<void> initCallbacksOnly() async {
    await _notificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null) return;
        final ptId = int.tryParse(payload);
        if (ptId == null) return;

        final actionId = response.actionId;
        if (actionId != null && actionId.startsWith('cat_')) {
          final categoryId = int.tryParse(actionId.replaceFirst('cat_', ''));
          if (categoryId != null) await onCategorize?.call(ptId, categoryId);
        } else {
          onNotificationTap?.call(ptId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );
  }

  /// Requests notification permission. Must be called after runApp so the dialog renders.
  static Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTransactionAlert({
    required int id,
    required String title,
    required String body,
    required int pendingTransactionId,
    required List<({int id, String name})> categories,
  }) async {
    final actions = categories.take(3).map((cat) =>
      AndroidNotificationAction('cat_${cat.id}', cat.name),
    ).toList();

    final androidDetails = AndroidNotificationDetails(
      'transaction_alerts',
      'Transaction Alerts',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: pendingTransactionId.toString(),
    );
  }

  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
