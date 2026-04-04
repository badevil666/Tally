import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/inflow_model.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../data/models/piggy_bank_model.dart';
import '../../data/models/daily_snapshot.dart';
import '../../data/providers/storage_provider.dart';
import '../../services/bootstrap_service.dart';
import '../../services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  final StorageProvider _storage;

  BudgetModel? _budget;
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<InflowModel> _inflows = [];
  List<PendingTransactionModel> _pendingTransactions = [];
  List<PiggyBankEntryModel> _piggyEntries = [];
  int? _highlightedPendingId;

  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';

  BudgetProvider(this._storage) {
    _loadData();
  }

  Isar get isar => _storage.isar;
  BudgetModel? get budget => _budget;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<InflowModel> get inflows => _inflows;
  List<PendingTransactionModel> get pendingTransactions => _pendingTransactions;
  int? get highlightedPendingId => _highlightedPendingId;

  List<PiggyBankEntryModel> get piggyEntries => _piggyEntries;
  double get piggyBankBalance => _piggyEntries.fold(0.0, (s, e) => s + e.amount);

  double get totalPending => _pendingTransactions.fold(0.0, (s, pt) => s + pt.amount);

  DateTime get selectedMonth => _selectedMonth;
  String get searchQuery => _searchQuery;

  void setMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  List<TransactionModel> get monthlyTransactions {
    final list = _transactions.where((t) => t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return list.where((t) =>
        (t.category.value?.name.toLowerCase().contains(q) ?? false) ||
        t.description.toLowerCase().contains(q) ||
        t.amount.toStringAsFixed(0).contains(q) ||
        t.amount.toStringAsFixed(2).contains(q),
      ).toList();
    }
    return list;
  }

  List<InflowModel> get monthlyInflows {
    final list = _inflows.where((i) => i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return list.where((i) =>
        i.title.toLowerCase().contains(q) ||
        i.sourceCategory.toLowerCase().contains(q) ||
        i.amount.toStringAsFixed(0).contains(q) ||
        i.amount.toStringAsFixed(2).contains(q),
      ).toList();
    }
    return list;
  }

  double get monthlyInflowTotal => monthlyInflows.fold(0.0, (s, i) => s + i.amount) + totalIncome;
  double get monthlyExpenseTotal => monthlyTransactions.fold(0.0, (s, tx) => s + tx.amount);
  double get monthlyNet => monthlyInflowTotal - monthlyExpenseTotal;

  double get totalIncome => _budget?.totalIncome ?? 0;
  double get savingsGoal => _budget?.savingsGoal ?? 0;
  String get currencySymbol => _budget?.currencySymbol ?? '\$';
  
  double get sumOfFixedBills {
    return _categories.where((c) => c.type == CategoryType.fixed).fold(0.0, (sum, cat) => sum + cat.limit);
  }

  double get totalExtraInflow => _inflows.fold(0.0, (sum, i) => sum + i.amount);
  double get totalMonthlyPool => totalIncome + totalExtraInflow;

  double get totalExpenses => _transactions.fold(0.0, (sum, tx) => sum + tx.amount);

  int get daysLeftInMonth {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int left = (daysInMonth - now.day) + 1; // +1 to include today
    return left > 0 ? left : 1;
  }

  double get remainingToSpend => totalMonthlyPool - savingsGoal - sumOfFixedBills - totalLifestyleSpent - piggyBankBalance;

  double get dailySpendingAllowance => remainingToSpend > 0 ? (remainingToSpend / daysLeftInMonth) : 0;
  
  double get safeToSpend => dailySpendingAllowance;

  double get unallocated => totalMonthlyPool - savingsGoal - totalAllocated;

  double get totalAllocated {
    return _categories.fold(0.0, (sum, cat) => sum + cat.limit);
  }

  double get totalLifestyleSpent {
    return _transactions.where((t) => t.category.value?.type == CategoryType.variable).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get todayExpenseTotal {
    final today = DateTime.now();
    return _transactions
        .where((t) => t.date.year == today.year && t.date.month == today.month && t.date.day == today.day)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Loads the category link for every transaction in [_transactions].
  /// IsarLink.value is null after findAll() — this makes category name
  /// available for filtering, display, and calculations.
  void _loadTransactionLinks() {
    for (final tx in _transactions) {
      tx.category.loadSync();
    }
  }

  /// Reloads pending transactions and recent transactions from Isar.
  /// Called when the app resumes so the background notification handler's
  /// Isar writes are reflected in the UI.
  Future<void> reloadAfterBackground() async {
    final isar = _storage.isar;
    _pendingTransactions = await isar.pendingTransactionModels.where().sortByTimestampDesc().findAll();
    _transactions = await isar.transactionModels.where().sortByDateDesc().findAll();
    _loadTransactionLinks();
    _piggyEntries = await isar.piggyBankEntryModels.where().sortByDateDesc().findAll();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final isar = _storage.isar;
    _budget = await isar.budgetModels.where().findFirst();
    _categories = await CategoryBootstrap.initialize(_storage);
    _transactions = await isar.transactionModels.where().sortByDateDesc().findAll();
    _loadTransactionLinks();
    _inflows = await isar.inflowModels.where().sortByDateDesc().findAll();
    _pendingTransactions = await isar.pendingTransactionModels.where().sortByTimestampDesc().findAll();
    _piggyEntries = await isar.piggyBankEntryModels.where().sortByDateDesc().findAll();
    notifyListeners();
    _refreshEveningReminder();
    await applyEndOfDayAutoActions();
  }

  void _refreshEveningReminder() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    // Subtract any surplus already banked today so the reminder
    // doesn't fire "you have $X left" after the user already banked it.
    final bankedToday = _piggyEntries
        .where((e) => e.amount > 0 && !e.date.isBefore(todayStart))
        .fold(0.0, (s, e) => s + e.amount);
    final surplus = dailyLimitFor(today) - dailySpentFor(today) - bankedToday;
    NotificationService.scheduleEveningReminder(
      surplus: surplus,
      currency: currencySymbol,
    );
  }

  Future<void> setBudget(double totalIncome, double savingsGoal, {String country = 'United States', String currencySymbol = '\$'}) async {
    final isar = _storage.isar;
    final newBudget = BudgetModel()
      ..id = _budget?.id ?? Isar.autoIncrement
      ..totalIncome = totalIncome
      ..savingsGoal = savingsGoal
      ..country = country
      ..currencySymbol = currencySymbol;

    await isar.writeTxn(() async {
      await isar.budgetModels.put(newBudget);
    });
    
    _budget = newBudget;
    notifyListeners();
  }

  Future<void> addCategory(String name, double limit, CategoryType type,
      {String icon = 'payments', String colorHex = '#E2E2E2'}) async {
    final isar = _storage.isar;
    final cat = CategoryModel()
      ..name = name
      ..limit = limit
      ..type = type
      ..icon = icon
      ..colorHex = colorHex;

    await isar.writeTxn(() async {
      await isar.categoryModels.put(cat);
    });

    _categories.add(cat);
    notifyListeners();
  }

  Future<void> updateCategoryLimit(Id id, double newLimit) async {
    final isar = _storage.isar;
    final cat = _categories.firstWhere((c) => c.id == id);
    cat.limit = newLimit;

    await isar.writeTxn(() async {
      await isar.categoryModels.put(cat);
    });
    notifyListeners();
  }

  Future<void> updateCategory(Id id, {double? limit, String? icon, String? colorHex, String? name}) async {
    final isar = _storage.isar;
    final cat = _categories.firstWhere((c) => c.id == id);
    if (limit != null) cat.limit = limit;
    if (icon != null) cat.icon = icon;
    if (colorHex != null) cat.colorHex = colorHex;
    if (name != null && name.isNotEmpty) cat.name = name;

    await isar.writeTxn(() async {
      await isar.categoryModels.put(cat);
    });
    notifyListeners();
  }

  Future<void> deleteCategory(Id categoryId) async {
    final isar = _storage.isar;
    final cat = _categories.firstWhere((c) => c.id == categoryId);
    if (cat.isProtected) return;

    // Reassign all transactions to the protected "Other" of the same type.
    final otherCat = _categories.firstWhere(
      (c) => c.isProtected && c.type == cat.type,
    );
    final txsToReassign = _transactions.where((t) => t.category.value?.id == categoryId).toList();
    for (final tx in txsToReassign) {
      tx.category.value = otherCat;
    }

    await isar.writeTxn(() async {
      for (final tx in txsToReassign) {
        await tx.category.save();
      }
      await isar.categoryModels.delete(categoryId);
    });

    _categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
  }

  Future<void> addTransaction(Id categoryId, double amount, String description,
      {String? attachmentSourcePath}) async {
    final isar = _storage.isar;
    // Fall back to the protected "Other (variable)" category if the requested
    // category can't be found (e.g. it was deleted after the notification fired).
    final cat = await isar.categoryModels.get(categoryId)
        ?? await isar.categoryModels
            .filter()
            .isProtectedEqualTo(true)
            .typeEqualTo(CategoryType.variable)
            .findFirst();

    if (cat != null) {
      final tx = TransactionModel()
        ..amount = amount
        ..description = description
        ..date = DateTime.now();

      if (attachmentSourcePath != null && attachmentSourcePath.isNotEmpty) {
        tx.attachmentPath = await _copyAttachment(attachmentSourcePath);
      }

      tx.category.value = cat;

      await isar.writeTxn(() async {
        await isar.transactionModels.put(tx);
        await tx.category.save();
      });

      _transactions.insert(0, tx);
      notifyListeners();
      await _autoDeductOverspendFromPiggy();
      _refreshEveningReminder();
    }
  }

  /// Copies a picked file into the app's private attachments directory and
  /// returns the absolute destination path.
  Future<String> _copyAttachment(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${docsDir.path}/attachments');
    if (!attachDir.existsSync()) attachDir.createSync(recursive: true);

    final ext = sourcePath.split('.').last.toLowerCase();
    final dest = '${attachDir.path}/${const Uuid().v4()}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> updateTransaction(Id id, double amount, Id categoryId) async {
    final isar = _storage.isar;
    final tx = _transactions.firstWhere((t) => t.id == id);
    final cat = await isar.categoryModels.get(categoryId);
    if (cat == null) return;

    tx.amount = amount;
    tx.category.value = cat;

    await isar.writeTxn(() async {
      await isar.transactionModels.put(tx);
      await tx.category.save();
    });
    notifyListeners();
  }

  Future<void> deleteTransaction(Id id) async {
    final isar = _storage.isar;
    await isar.writeTxn(() async {
      await isar.transactionModels.delete(id);
    });
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> addInflow(double amount, String title, String sourceCategory) async {
    final isar = _storage.isar;
    final inflow = InflowModel()
      ..title = title
      ..amount = amount
      ..sourceCategory = sourceCategory
      ..date = DateTime.now();
      
    await isar.writeTxn(() async {
      await isar.inflowModels.put(inflow);
    });
    
    _inflows.insert(0, inflow);
    notifyListeners();
  }

  Future<void> deleteInflow(Id id) async {
    final isar = _storage.isar;
    await isar.writeTxn(() async {
      await isar.inflowModels.delete(id);
    });
    _inflows.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  double spentInCategory(Id categoryId) {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.category.value?.id == categoryId && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> addPendingTransaction(double amount, String merchantName, String rawBody) async {
    final isar = _storage.isar;
    final pt = PendingTransactionModel()
      ..amount = amount
      ..merchantName = merchantName
      ..rawBody = rawBody
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.pendingTransactionModels.put(pt);
    });

    _pendingTransactions.insert(0, pt);
    notifyListeners();
  }

  /// Called by SmsService after it has already persisted the pending transaction.
  /// Only updates in-memory state so the UI reflects the new entry immediately.
  void notifyPendingAdded(PendingTransactionModel pt) {
    _pendingTransactions.insert(0, pt);
    notifyListeners();
  }

  Future<void> removePendingTransaction(Id id) async {
    final isar = _storage.isar;
    final pt = _pendingTransactions.where((p) => p.id == id).firstOrNull
        ?? await isar.pendingTransactionModels.get(id);
    const _maxInt32 = 2147483647;
    if (pt != null && pt.notificationId > 0 && pt.notificationId <= _maxInt32) {
      await NotificationService.cancel(pt.notificationId);
    }
    await isar.writeTxn(() async {
      await isar.pendingTransactionModels.delete(id);
    });
    _pendingTransactions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> categorizePendingTransaction(Id ptId, Id categoryId) async {
    // Try in-memory list first; fall back to Isar in case of cold start.
    final pt = _pendingTransactions.where((p) => p.id == ptId).firstOrNull
        ?? await _storage.isar.pendingTransactionModels.get(ptId);
    if (pt == null) return;
    await addTransaction(categoryId, pt.amount, pt.merchantName.isEmpty ? 'SMS Transaction' : pt.merchantName);
    await removePendingTransaction(ptId);
    clearHighlight();
  }

  void highlightPending(int ptId) {
    _highlightedPendingId = ptId;
    notifyListeners();
  }

  void clearHighlight() {
    if (_highlightedPendingId == null) return;
    _highlightedPendingId = null;
    notifyListeners();
  }

  Future<void> addToPiggyBank(double amount, {String note = ''}) async {
    if (amount <= 0) return;
    await _writePiggyEntry(amount, note: note);
  }

  /// Moves money FROM piggy bank back into the spendable monthly pool.
  Future<void> withdrawFromPiggy(double amount) async {
    final actual = amount.clamp(0.0, piggyBankBalance);
    if (actual <= 0) return;
    await _writePiggyEntry(-actual, note: 'withdrawal:${_dateKey(DateTime.now())}');
    _refreshEveningReminder();
  }

  /// On app open: if yesterday had unhandled surplus AND the user has set a
  /// default end-of-day behavior, apply it automatically.
  Future<void> applyEndOfDayAutoActions() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultBehavior = prefs.getString('eod_default'); // 'piggy' | 'pool' | null
    if (defaultBehavior == null) return; // user hasn't chosen a default

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = 'eod_handled_${_dateKey(yesterday)}';
    if (prefs.getBool(key) == true) return; // already handled

    await prefs.setBool(key, true); // mark handled regardless

    if (defaultBehavior == 'piggy') {
      final surplus = dailyLimitFor(yesterday) - dailySpentFor(yesterday);
      if (surplus > 0) {
        await addToPiggyBank(surplus,
            note: 'Auto daily surplus ${DateFormat('MMM d').format(yesterday)}');
      }
    }
    // 'pool' means no action — surplus redistributes automatically
  }

  /// Internal: writes a piggy entry with any sign (positive = deposit, negative = withdrawal).
  Future<void> _writePiggyEntry(double amount, {String note = ''}) async {
    final isar = _storage.isar;
    final entry = PiggyBankEntryModel()
      ..amount = amount
      ..date = DateTime.now()
      ..note = note;

    await isar.writeTxn(() => isar.piggyBankEntryModels.put(entry));
    _piggyEntries.insert(0, entry);
    notifyListeners();
  }

  /// When today's spending exceeds the effective daily budget, automatically
  /// pull the overage from the piggy bank first, then let the rest spill into
  /// the monthly pool (reducing future days' limits).
  ///
  /// Effective limit = dailyLimitFor(today) − amountDepositedTodayIntoPiggy.
  /// Example: limit = 100, spent = 50, banked = 50 → effective remaining = 0.
  ///   Next transaction → all of it hits piggy before touching the month pool.
  Future<void> _autoDeductOverspendFromPiggy() async {
    if (piggyBankBalance <= 0) return;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Amount the user voluntarily deposited into piggy today.
    final bankedToday = _piggyEntries
        .where((e) => e.amount > 0 && !e.date.isBefore(todayStart))
        .fold(0.0, (s, e) => s + e.amount);

    final effectiveLimit = dailyLimitFor(today) - bankedToday;
    final todaySpent = dailySpentFor(today);
    if (todaySpent <= effectiveLimit) return;

    final overspend = todaySpent - effectiveLimit;

    // How much has already been auto-deducted for today?
    final todayStr = _dateKey(today);
    final alreadyDeducted = _piggyEntries
        .where((e) => e.amount < 0 && e.note == 'overspend:$todayStr')
        .fold(0.0, (s, e) => s + e.amount.abs());

    final needed = (overspend - alreadyDeducted).clamp(0.0, piggyBankBalance);
    if (needed <= 0) return;

    await _writePiggyEntry(-needed, note: 'overspend:$todayStr');
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns the calculated daily spending limit for a given calendar date.
  /// Computed as: (spendable pool - cumulative lifestyle spend before that day) / days remaining.
  double dailyLimitFor(DateTime date) {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final daysLeft = daysInMonth - date.day + 1;
    final pool = totalMonthlyPool - savingsGoal - sumOfFixedBills;
    if (daysLeft <= 0 || pool <= 0) return 0;
    return pool / daysLeft;
  }

  /// Returns total lifestyle spending on a specific calendar date.
  double dailySpentFor(DateTime date) {
    return _transactions
        .where((t) =>
            t.category.value?.type == CategoryType.variable &&
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Daily breakdown for the selected month (most recent day first, up to today).
  List<DailySnapshot> get monthDailyBreakdown {
    final now = DateTime.now();
    final month = _selectedMonth;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lastDay = (month.year == now.year && month.month == now.month)
        ? now.day
        : daysInMonth;

    return List.generate(lastDay, (i) {
      final date = DateTime(month.year, month.month, i + 1);
      return DailySnapshot(
        date: date,
        limit: dailyLimitFor(date),
        spent: dailySpentFor(date),
      );
    }).reversed.toList();
  }
}
