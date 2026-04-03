import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/storage_provider.dart';
import 'logic/providers/budget_provider.dart';
import 'services/notification_service.dart';
import 'services/sms_service.dart';

import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/budget_planner_screen.dart';
import 'ui/screens/review_screen.dart';
import 'ui/screens/inbox_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/widgets/quick_add_modal.dart';
import 'ui/widgets/quick_add_income_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initCallbacksOnly();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  BudgetProvider? _provider;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = StorageProvider();
    await storage.init();

    final budgetProvider = BudgetProvider(storage);

    NotificationService.onCategorize = (ptId, categoryId) =>
        budgetProvider.categorizePendingTransaction(ptId, categoryId);
    NotificationService.onNotificationTap = (ptId) =>
        budgetProvider.highlightPending(ptId);
    SmsService.onPendingAdded = (pt) => budgetProvider.notifyPendingAdded(pt);
    AppLifecycleListener(onResume: () => budgetProvider.reloadAfterBackground());

    setState(() => _provider = budgetProvider);

    await NotificationService.requestPermissions();
    await SmsService.init();
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _provider!)],
      child: const KeepApp(),
    );
  }
}

class KeepApp extends StatelessWidget {
  const KeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Budget',
      theme: AppTheme.darkTheme,
      home: const InitialRoute(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialRoute extends StatelessWidget {
  const InitialRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.budget == null) {
          return OnboardingScreen(onFinish: () {});
        }
        return const MainScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _screens = [
    DashboardScreen(),
    BudgetPlannerScreen(),
    ReviewScreen(),
    InboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Switch to Inbox tab when a notification body tap highlights a pending entry
    final highlightedId = context.watch<BudgetProvider>().highlightedPendingId;
    if (highlightedId != null && _selectedIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 3);
      });
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        backgroundColor: AppTheme.accent,
        elevation: 10,
        onPressed: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).padding.bottom + 24),
              decoration: const BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.error, child: Icon(Icons.remove, color: Colors.white)),
                    title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const QuickAddModal());
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.success, child: Icon(Icons.add, color: Colors.black)),
                    title: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const QuickAddIncomeModal());
                    },
                  )
                ],
              )
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ) : null,
      bottomNavigationBar: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
        child: GNav(
          backgroundColor: AppTheme.background,
          color: Colors.white,
          activeColor: Colors.black,
          tabBackgroundColor: AppTheme.accent,
          gap: 8,
          padding: const EdgeInsets.all(16),
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: [
            const GButton(icon: Icons.dashboard, text: 'Dashboard'),
            const GButton(icon: Icons.account_balance_wallet, text: 'Budgeting'),
            const GButton(icon: Icons.history, text: 'Review'),
            GButton(
              icon: Icons.inbox, 
              text: 'Inbox',
              leading: Provider.of<BudgetProvider>(context).pendingTransactions.isNotEmpty
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.inbox, color: _selectedIndex == 3 ? Colors.black : Colors.white),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text('${Provider.of<BudgetProvider>(context).pendingTransactions.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
