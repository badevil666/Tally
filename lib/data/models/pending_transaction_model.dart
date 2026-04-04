import 'package:isar/isar.dart';

part 'pending_transaction_model.g.dart';

@collection
class PendingTransactionModel {
  Id id = Isar.autoIncrement;

  double amount = 0;
  String merchantName = 'Unknown Merchant';
  String rawBody = '';
  DateTime timestamp = DateTime.now();
  int notificationId = 0;
}
