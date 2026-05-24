import 'package:isar_community/isar.dart';

part 'category_model.g.dart';

enum CategoryType {
  fixed,
  variable
}

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  String name = '';
  
  @enumerated
  CategoryType type = CategoryType.variable;
  
  double limit = 0;

  String icon = '';
  String colorHex = '';
  bool isProtected = false;
}
