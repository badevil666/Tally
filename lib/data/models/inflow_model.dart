import 'package:isar_community/isar.dart';

part 'inflow_model.g.dart';

@collection
class InflowModel {
  Id id = Isar.autoIncrement;

  String title = '';
  double amount = 0;
  DateTime date = DateTime.now();
  String sourceCategory = 'Other';
}
