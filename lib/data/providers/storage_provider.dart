import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/inflow_model.dart';
import '../models/pending_transaction_model.dart';

class StorageProvider {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [BudgetModelSchema, CategoryModelSchema, TransactionModelSchema, InflowModelSchema, PendingTransactionModelSchema],
      directory: dir.path,
    );
  }
}
