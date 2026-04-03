import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/inflow_model.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../services/bootstrap_service.dart';

class BudgetProvider extends ChangeNotifier {
  final StorageProvider _storage;

  BudgetModel? _budget;
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<InflowModel> _inflows = [];
  List<PendingTransactionModel> _pendingTransactions = [];
  int? _highlightedPendingId;

  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';

  BudgetProvider(this._storage) {
    _loadData();
  }

  BudgetModel? get budget => _budget;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<InflowModel> get inflows => _inflows;
  List<PendingTransactionModel> get pendingTransactions => _pendingTransactions;
  int? get highlightedPendingId => _highlightedPendingId;

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
      return list.where((t) => (t.category.value?.name.toLowerCase().contains(q) ?? false) || t.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<InflowModel> get monthlyInflows {
    final list = _inflows.where((i) => i.date.year == _selectedMonth.year && i.date.month == _selectedMonth.month).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return list.where((i) => i.title.toLowerCase().contains(q) || i.sourceCategory.toLowerCase().contains(q)).toList();
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

  double get remainingToSpend => totalMonthlyPool - savingsGoal - sumOfFixedBills - totalLifestyleSpent;

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

  /// Reloads pending transactions and recent transactions from Isar.
  /// Called when the app resumes so the background notification handler's
  /// Isar writes are reflected in the UI.
  Future<void> reloadAfterBackground() async {
    final isar = _storage.isar;
    _pendingTransactions = await isar.pendingTransactionModels.where().sortByTimestampDesc().findAll();
    _transactions = await isar.transactionModels.where().sortByDateDesc().findAll();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final isar = _storage.isar;
    _budget = await isar.budgetModels.where().findFirst();
    _categories = await CategoryBootstrap.initialize(_storage);
    _transactions = await isar.transactionModels.where().sortByDateDesc().findAll();
    _inflows = await isar.inflowModels.where().sortByDateDesc().findAll();
    _pendingTransactions = await isar.pendingTransactionModels.where().sortByTimestampDesc().findAll();
    notifyListeners();
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

  Future<void> addCategory(String name, double limit, CategoryType type) async {
    final isar = _storage.isar;
    final cat = CategoryModel()
      ..name = name
      ..limit = limit
      ..type = type;

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

  Future<void> addTransaction(Id categoryId, double amount, String description) async {
    final isar = _storage.isar;
    final cat = await isar.categoryModels.get(categoryId);
    
    if (cat != null) {
      final tx = TransactionModel()
        ..amount = amount
        ..description = description
        ..date = DateTime.now();
        
      tx.category.value = cat;

      await isar.writeTxn(() async {
        await isar.transactionModels.put(tx);
        await tx.category.save();
      });
      
      _transactions.insert(0, tx);
      notifyListeners();
    }
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
    return _transactions.where((t) => t.category.value?.id == categoryId).fold(0.0, (sum, tx) => sum + tx.amount);
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
}
