import 'dart:math';
import 'package:isar/isar.dart';
import '../data/models/transaction_model.dart';
import '../data/models/piggy_bank_model.dart';
import '../data/models/inflow_model.dart';
import '../data/models/category_model.dart';
import '../data/models/budget_model.dart';
import '../logic/providers/budget_provider.dart';

class SeedService {
  static final _rng = Random(42);

  static Future<void> seedAll(BudgetProvider provider) async {
    // 1. Ensure budget is set
    await provider.setBudget(
      20000,
      5000,
      country: 'India',
      currencySymbol: '₹',
    );

    // 2. Set category limits
    final catLimits = {
      'Food & Dining': 2000.0,
      'Groceries': 3000.0,
      'Transport': 1500.0,
      'Shopping': 1500.0,
      'Entertainment': 1000.0,
      'Health & Fitness': 800.0,
      'Personal Care': 500.0,
      'Eating Out': 1200.0,
      'Rent / Home': 6000.0,
      'Electricity': 800.0,
      'Mobile / Phone': 300.0,
      'Internet': 600.0,
      'Streaming': 500.0,
    };

    for (final cat in provider.categories) {
      final limit = catLimits[cat.name];
      if (limit != null && cat.limit == 0) {
        await provider.updateCategoryLimit(cat.id, limit);
      }
    }

    // 3. Seed 3 months of realistic transactions
    final now = DateTime.now();
    final isar = provider.isar;

    final txData = <Map<String, dynamic>>[];

    for (int monthOffset = 2; monthOffset >= 0; monthOffset--) {
      final month = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final lastDay = (monthOffset == 0) ? now.day : daysInMonth;

      for (int day = 1; day <= lastDay; day++) {
        final date = DateTime(month.year, month.month, day);
        final isWeekend = date.weekday == 6 || date.weekday == 7;

        // Food & Dining: almost daily, small amounts
        if (_rng.nextDouble() > 0.25) {
          txData.add({'cat': 'Food & Dining', 'amount': _rand(40, 180), 'desc': _pick(['Swiggy Order', 'Zomato', 'Canteen', 'Tea & Snacks', 'Lunch']), 'date': _dateAt(date, _rng.nextInt(14) + 8)});
        }

        // Groceries: 2-3 times a week
        if (_rng.nextDouble() > 0.65) {
          txData.add({'cat': 'Groceries', 'amount': _rand(200, 800), 'desc': _pick(['DMart', 'Big Bazaar', 'Reliance Fresh', 'More Supermarket', 'Local Kirana']), 'date': _dateAt(date, _rng.nextInt(6) + 10)});
        }

        // Transport: weekdays mostly
        if (!isWeekend && _rng.nextDouble() > 0.35) {
          txData.add({'cat': 'Transport', 'amount': _rand(20, 200), 'desc': _pick(['Ola', 'Uber', 'Auto Rickshaw', 'Bus Pass', 'Petrol']), 'date': _dateAt(date, _rng.nextInt(4) + 8)});
        }

        // Eating Out: weekends and occasionally weekdays
        if (isWeekend || _rng.nextDouble() > 0.8) {
          txData.add({'cat': 'Eating Out', 'amount': _rand(250, 900), 'desc': _pick(['Restaurant', 'Café Coffee Day', 'McDonald\'s', 'Haldirams', 'Barbeque Nation']), 'date': _dateAt(date, _rng.nextInt(5) + 13)});
        }

        // Shopping: 1-2 times a month, big spends
        if (day % 12 == 0 || (isWeekend && _rng.nextDouble() > 0.85)) {
          txData.add({'cat': 'Shopping', 'amount': _rand(500, 2500), 'desc': _pick(['Amazon', 'Flipkart', 'Myntra', 'Ajio', 'H&M', 'Westside']), 'date': _dateAt(date, _rng.nextInt(8) + 11)});
        }

        // Entertainment: weekends
        if (isWeekend && _rng.nextDouble() > 0.6) {
          txData.add({'cat': 'Entertainment', 'amount': _rand(150, 600), 'desc': _pick(['PVR Cinemas', 'INOX', 'Bowling', 'Theme Park', 'Live Event']), 'date': _dateAt(date, _rng.nextInt(5) + 14)});
        }

        // Health: once or twice a month
        if (day % 10 == 0 && _rng.nextDouble() > 0.5) {
          txData.add({'cat': 'Health & Fitness', 'amount': _rand(200, 800), 'desc': _pick(['Gym Membership', 'Pharmacy', 'Doctor Visit', 'Lab Test', 'Protein Powder']), 'date': _dateAt(date, _rng.nextInt(4) + 9)});
        }

        // Personal Care
        if (day % 14 == 0) {
          txData.add({'cat': 'Personal Care', 'amount': _rand(100, 400), 'desc': _pick(['Salon', 'Spa', 'Nykaa', 'Barbershop', 'Skincare']), 'date': _dateAt(date, _rng.nextInt(3) + 10)});
        }

        // Fixed bills on specific days of month
        if (day == 1) {
          txData.add({'cat': 'Rent / Home', 'amount': 6000.0, 'desc': 'Monthly Rent', 'date': _dateAt(date, 10)});
        }
        if (day == 5) {
          txData.add({'cat': 'Electricity', 'amount': _rand(600, 900), 'desc': 'KSEB Bill', 'date': _dateAt(date, 11)});
          txData.add({'cat': 'Internet', 'amount': 599.0, 'desc': 'ACT Fibernet', 'date': _dateAt(date, 11)});
        }
        if (day == 3) {
          txData.add({'cat': 'Mobile / Phone', 'amount': 299.0, 'desc': 'Jio Recharge', 'date': _dateAt(date, 9)});
          txData.add({'cat': 'Streaming', 'amount': 149.0, 'desc': 'Netflix', 'date': _dateAt(date, 10)});
        }
      }

      // Piggy bank entries: a few per month
      final piggyEntries = [
        {'amount': _rand(200, 500), 'note': 'Daily surplus ${_monthName(month.month)}', 'day': 7},
        {'amount': _rand(300, 700), 'note': 'Daily surplus ${_monthName(month.month)}', 'day': 14},
        {'amount': _rand(150, 400), 'note': 'Daily surplus ${_monthName(month.month)}', 'day': 21},
      ];
      if (monthOffset == 0 && now.day >= 5) {
        piggyEntries.add({'amount': _rand(200, 600), 'note': 'Daily surplus ${_monthName(month.month)}', 'day': min(5, now.day)});
      }

      for (final p in piggyEntries) {
        final piggyDay = p['day'] as int;
        if (monthOffset > 0 || piggyDay <= now.day) {
          final entry = PiggyBankEntryModel()
            ..amount = (p['amount'] as double)
            ..note = p['note'] as String
            ..date = DateTime(month.year, month.month, piggyDay, 21, 0);
          await isar.writeTxn(() => isar.piggyBankEntryModels.put(entry));
        }
      }

      // Income inflow at start of month
      if (monthOffset > 0) {
        final inflow = InflowModel()
          ..amount = 20000
          ..title = 'Monthly Salary'
          ..sourceCategory = 'Salary'
          ..date = DateTime(month.year, month.month, 1, 9, 0);
        await isar.writeTxn(() => isar.inflowModels.put(inflow));
      }
    }

    // Write all transactions
    final allCats = await isar.categoryModels.where().findAll();
    final catMap = {for (final c in allCats) c.name: c};

    final txModels = <TransactionModel>[];
    for (final d in txData) {
      final cat = catMap[d['cat'] as String];
      if (cat == null) continue;
      final tx = TransactionModel()
        ..amount = d['amount'] as double
        ..description = d['desc'] as String
        ..date = d['date'] as DateTime;
      tx.category.value = cat;
      txModels.add(tx);
    }

    await isar.writeTxn(() async {
      await isar.transactionModels.putAll(txModels);
      for (final tx in txModels) {
        await tx.category.save();
      }
    });

    await provider.reloadAfterBackground();
  }

  static double _rand(double min, double max) =>
      (min + _rng.nextDouble() * (max - min)).roundToDouble();

  static String _pick(List<String> options) => options[_rng.nextInt(options.length)];

  static DateTime _dateAt(DateTime date, int hour) =>
      DateTime(date.year, date.month, date.day, hour, _rng.nextInt(59));

  static String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }
}
