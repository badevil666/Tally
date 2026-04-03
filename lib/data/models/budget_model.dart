import 'package:isar/isar.dart';

part 'budget_model.g.dart';

@collection
class BudgetModel {
  Id id = Isar.autoIncrement;

  double totalIncome = 0;
  double savingsGoal = 0;

  String country = 'United States';
  String currencySymbol = '\$';
}
