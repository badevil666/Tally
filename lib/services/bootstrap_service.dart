import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../data/models/category_model.dart';
import '../data/providers/storage_provider.dart';

class CategoryBootstrap {
  static const String _firstRunKey = 'is_first_run_categories';

  static Future<List<CategoryModel>> initialize(StorageProvider storage) async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool(_firstRunKey) ?? true;
    final isar = storage.isar;

    if (isFirstRun) {
      final rawData = [
        {'name': 'Food & Dining', 'icon': 'fastfood', 'isFixed': false, 'colorHex': '#FFD3B6'},
        {'name': 'Travel', 'icon': 'flight_takeoff', 'isFixed': false, 'colorHex': '#A1C4FD'},
        {'name': 'Dress & Style', 'icon': 'checkroom', 'isFixed': false, 'colorHex': '#D4AF37'},
        {'name': 'General', 'icon': 'payments', 'isFixed': false, 'colorHex': '#E2E2E2'},
        {'name': 'Rent/Home', 'icon': 'home_work', 'isFixed': true, 'colorHex': '#8B94FF'},
        {'name': 'Electricity', 'icon': 'bolt', 'isFixed': true, 'colorHex': '#FFEFBA'},
        {'name': 'Water', 'icon': 'water_drop', 'isFixed': true, 'colorHex': '#7EF9FF'},
        {'name': 'Internet', 'icon': 'router', 'isFixed': true, 'colorHex': '#B9FBC0'},
        {'name': 'Mobile', 'icon': 'smartphone', 'isFixed': true, 'colorHex': '#FFCFD2'},
      ];

      final categories = rawData.map((data) => CategoryModel()
        ..name = data['name'] as String
        ..icon = data['icon'] as String
        ..colorHex = data['colorHex'] as String
        ..type = (data['isFixed'] as bool) ? CategoryType.fixed : CategoryType.variable
        ..limit = 0.0
      ).toList();

      await isar.writeTxn(() async {
        await isar.categoryModels.putAll(categories);
      });

      await prefs.setBool(_firstRunKey, false);
    }
    
    // Real-time sorting: Variable first (Alphabetical), Fixed bills at the bottom.
    final allCats = await isar.categoryModels.where().findAll();
    allCats.sort((a, b) {
      if (a.type != b.type) {
        return a.type == CategoryType.variable ? -1 : 1; 
      }
      return a.name.compareTo(b.name);
    });
    
    return allCats;
  }
}
