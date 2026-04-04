import 'package:isar/isar.dart';

part 'piggy_bank_model.g.dart';

@collection
class PiggyBankEntryModel {
  Id id = Isar.autoIncrement;
  double amount = 0;
  DateTime date = DateTime.now();
  String note = '';
}
