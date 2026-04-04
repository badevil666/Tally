import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/inflow_model.dart';
import '../data/models/pending_transaction_model.dart';
import '../data/models/piggy_bank_model.dart';

// ── Shared helper — works in any isolate ────────────────────────────────────
Future<void> categorizeViaIsar(int ptId, int categoryId) async {
  print('[Notif] _categorizeViaIsar ptId=$ptId categoryId=$categoryId');
  final dir = await getApplicationDocumentsDirectory();
  final isar = Isar.getInstance() ?? await Isar.open(
    [BudgetModelSchema, CategoryModelSchema, TransactionModelSchema,
     InflowModelSchema, PendingTransactionModelSchema, PiggyBankEntryModelSchema],
    directory: dir.path,
  );
  print('[Notif] isar opened');

  final pt = await isar.pendingTransactionModels.get(ptId);
  print('[Notif] pt=$pt');
  if (pt == null) { print('[Notif] pt not found, aborting'); return; }

  final cat = await isar.categoryModels.get(categoryId)
      ?? await isar.categoryModels
          .filter()
          .isProtectedEqualTo(true)
          .typeEqualTo(CategoryType.variable)
          .findFirst();
  print('[Notif] cat=$cat');
  if (cat == null) { print('[Notif] cat not found, aborting'); return; }

  final tx = TransactionModel()
    ..amount = pt.amount
    ..description = pt.merchantName.isEmpty ? 'SMS Transaction' : pt.merchantName
    ..date = DateTime.now();
  tx.category.value = cat;

  await isar.writeTxn(() async {
    await isar.transactionModels.put(tx);
    await tx.category.save();
    await isar.pendingTransactionModels.delete(ptId);
  });

  // Cancel original notification + show confirmation
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    ),
  );
  if (pt.notificationId > 0 && pt.notificationId <= 2147483647) {
    await plugin.cancel(id: pt.notificationId);
  }
  final amtStr = pt.amount == pt.amount.truncateToDouble()
      ? '₹${pt.amount.toStringAsFixed(0)}'
      : '₹${pt.amount.toStringAsFixed(2)}';
  await plugin.show(
    id: ptId,
    title: 'Added to ${cat.name}',
    body: '$amtStr · ${pt.merchantName}',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'transaction_alerts', 'Transaction Alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      ),
    ),
  );
}

/// Background isolate handler
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) async {
  print('[Notif] background handler fired actionId=${response.actionId} payload=${response.payload}');
  final payload = response.payload;
  final actionId = response.actionId;
  if (payload == null || actionId == null || !actionId.startsWith('cat_')) return;

  final ptId = int.tryParse(payload);
  final categoryId = int.tryParse(actionId.replaceFirst('cat_', ''));
  if (ptId == null || categoryId == null) return;

  await categorizeViaIsar(ptId, categoryId);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initializeTimezones() {
    tz_data.initializeTimeZones();
  }

  /// Called after categorization so the UI updates immediately (optional).
  static Future<void> Function(int ptId, int categoryId)? onCategorizeDone;

  /// Called when the user taps the notification body (not an action button).
  static void Function(int ptId)? onNotificationTap;

  static Future<void> initCallbacksOnly() async {
    await _notificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('[Notif] foreground handler fired actionId=${response.actionId} payload=${response.payload}');
        final payload = response.payload;
        if (payload == null) return;
        final ptId = int.tryParse(payload);
        if (ptId == null) return;

        final actionId = response.actionId;
        if (actionId != null && actionId.startsWith('cat_')) {
          final categoryId = int.tryParse(actionId.replaceFirst('cat_', ''));
          if (categoryId == null) return;
          // Write directly to Isar — reliable regardless of provider state
          await categorizeViaIsar(ptId, categoryId);
          // Tell provider to refresh if it's running
          await onCategorizeDone?.call(ptId, categoryId);
        } else {
          onNotificationTap?.call(ptId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );
  }

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
      AndroidNotificationAction(
        'cat_${cat.id}',
        cat.name,
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ).toList();

    final androidDetails = AndroidNotificationDetails(
      'transaction_alerts',
      'Transaction Alerts',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: false,
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

  static const int _eveningReminderId = 9001;

  static Future<void> scheduleEveningReminder({
    required double surplus,
    required String currency,
  }) async {
    await _notificationsPlugin.cancel(id: _eveningReminderId);
    if (surplus <= 0) return;

    final now = DateTime.now();
    final eightPmTonight = DateTime(now.year, now.month, now.day, 20, 0);
    if (!eightPmTonight.isAfter(now)) return;

    final eightPmUtc = eightPmTonight.toUtc();
    final scheduledDate = tz.TZDateTime.from(eightPmUtc, tz.UTC);

    const androidDetails = AndroidNotificationDetails(
      'evening_reminder',
      'Evening Reminders',
      channelDescription: 'Nightly surplus banking reminder',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _notificationsPlugin.zonedSchedule(
      id: _eveningReminderId,
      title: '🐷 Piggy is waiting!',
      body: 'You have $currency${surplus.toStringAsFixed(0)} left today — bank it before midnight!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts', 'Budget Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
