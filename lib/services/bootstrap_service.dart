import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
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
        // ── Lifestyle ──
        {'name': 'Food & Dining',   'icon': 'fastfood',        'isFixed': false, 'colorHex': '#FFD3B6'},
        {'name': 'Groceries',       'icon': 'grocery',         'isFixed': false, 'colorHex': '#90EE90'},
        {'name': 'Transport',       'icon': 'directions_car',  'isFixed': false, 'colorHex': '#A1C4FD'},
        {'name': 'Shopping',        'icon': 'shopping_bag',    'isFixed': false, 'colorHex': '#D4AF37'},
        {'name': 'Entertainment',   'icon': 'movie',           'isFixed': false, 'colorHex': '#C3B1E1'},
        {'name': 'Health & Fitness','icon': 'fitness_center',  'isFixed': false, 'colorHex': '#FF8C69'},
        {'name': 'Personal Care',   'icon': 'spa',             'isFixed': false, 'colorHex': '#FFCFD2'},
        {'name': 'Eating Out',      'icon': 'restaurant',      'isFixed': false, 'colorHex': '#FFB347'},
        {'name': 'Education',       'icon': 'school',          'isFixed': false, 'colorHex': '#87CEEB'},
        {'name': 'Travel',          'icon': 'flight_takeoff',  'isFixed': false, 'colorHex': '#7EF9FF'},
        {'name': 'Clothing',        'icon': 'checkroom',       'isFixed': false, 'colorHex': '#B9FBC0'},
        {'name': 'General',         'icon': 'payments',        'isFixed': false, 'colorHex': '#E2E2E2'},
        // ── Fixed Bills ──
        {'name': 'Rent / Home',     'icon': 'home_work',       'isFixed': true,  'colorHex': '#8B94FF'},
        {'name': 'Electricity',     'icon': 'bolt',            'isFixed': true,  'colorHex': '#FFEFBA'},
        {'name': 'Water',           'icon': 'water_drop',      'isFixed': true,  'colorHex': '#7EF9FF'},
        {'name': 'Internet',        'icon': 'router',          'isFixed': true,  'colorHex': '#B9FBC0'},
        {'name': 'Mobile / Phone',  'icon': 'smartphone',      'isFixed': true,  'colorHex': '#FFCFD2'},
        {'name': 'Car Loan / EMI',  'icon': 'directions_car',  'isFixed': true,  'colorHex': '#A1C4FD'},
        {'name': 'Insurance',       'icon': 'health_safety',   'isFixed': true,  'colorHex': '#90EE90'},
        {'name': 'Streaming',       'icon': 'subscriptions',   'isFixed': true,  'colorHex': '#C3B1E1'},
        {'name': 'Gas / LPG',       'icon': 'gas_meter',       'isFixed': true,  'colorHex': '#FFB347'},
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
    
    // Ensure protected "Other" categories exist for each type (migration-safe).
    final allCats = await isar.categoryModels.where().findAll();
    final hasOtherVariable = allCats.any((c) => c.isProtected && c.type == CategoryType.variable);
    final hasOtherFixed = allCats.any((c) => c.isProtected && c.type == CategoryType.fixed);
    if (!hasOtherVariable || !hasOtherFixed) {
      final toCreate = <CategoryModel>[];
      if (!hasOtherVariable) {
        toCreate.add(CategoryModel()
          ..name = 'Other'
          ..icon = 'category'
          ..colorHex = '#E2E2E2'
          ..type = CategoryType.variable
          ..limit = 0
          ..isProtected = true);
      }
      if (!hasOtherFixed) {
        toCreate.add(CategoryModel()
          ..name = 'Other'
          ..icon = 'category'
          ..colorHex = '#E2E2E2'
          ..type = CategoryType.fixed
          ..limit = 0
          ..isProtected = true);
      }
      await isar.writeTxn(() => isar.categoryModels.putAll(toCreate));
      allCats.addAll(toCreate);
    }

    // Sorting: Variable first (by limit desc), Fixed bills at the bottom (by limit desc).
    allCats.sort((a, b) {
      if (a.type != b.type) return a.type == CategoryType.variable ? -1 : 1;
      return b.limit.compareTo(a.limit);
    });

    return allCats;
  }
}
