import 'package:isar/isar.dart';
import 'category_model.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  final category = IsarLink<CategoryModel>();

  double amount = 0;
  DateTime date = DateTime.now();
  String description = '';
}
