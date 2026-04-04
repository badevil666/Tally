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
  NotificationService.initializeTimezones();
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
  String? _errorMessage; // Added to catch and display boot errors

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint("Boot Sequence: 1. Starting Storage...");
      final storage = StorageProvider();
      await storage.init();

      debugPrint("Boot Sequence: 2. Setting up Provider...");
      final budgetProvider = BudgetProvider(storage);

      NotificationService.onCategorizeDone = (ptId, categoryId) async {
        await budgetProvider.reloadAfterBackground();
      };
      NotificationService.onNotificationTap = (ptId) =>
          budgetProvider.highlightPending(ptId);
      SmsService.onPendingAdded = (pt) => budgetProvider.notifyPendingAdded(pt);
      AppLifecycleListener(onResume: () => budgetProvider.reloadAfterBackground());

      debugPrint("Boot Sequence: 3. Requesting Notification Permissions...");
      await NotificationService.requestPermissions();

      debugPrint("Boot Sequence: 4. Initializing SMS Service...");
      await SmsService.init();

      debugPrint("Boot Sequence: 5. All done! Updating UI...");
      if (mounted) {
        setState(() => _provider = budgetProvider);
      }

      // Handle notification that launched the app from terminated state.
      // Action taps and body taps are delivered here, not via the callback.
      final launchDetails = await NotificationService.getLaunchDetails();
      if (launchDetails != null) {
        final response = launchDetails.notificationResponse;
        final payload = response?.payload;
        final actionId = response?.actionId;
        final ptId = payload != null ? int.tryParse(payload) : null;
        if (ptId != null) {
          if (actionId != null && actionId.startsWith('cat_')) {
            final categoryId = int.tryParse(actionId.replaceFirst('cat_', ''));
            if (categoryId != null) {
              await categorizeViaIsar(ptId, categoryId);
              await budgetProvider.reloadAfterBackground();
            }
          } else {
            // Body tap — go to inbox and highlight
            budgetProvider.highlightPending(ptId);
          }
        }
      }
    } catch (e, stacktrace) {
      debugPrint("🚨 CRITICAL ERROR DURING BOOT: $e");
      debugPrint(stacktrace.toString());
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If an error occurred during boot, show it on screen
    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text('Boot Failed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Still loading
    if (_provider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Boot successful, load the main app
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
      extendBody: true,
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        backgroundColor: AppTheme.accent,
        elevation: 10,
        onPressed: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (bottomSheetContext) => Container( // Renamed to avoid shadowing MainScreen context
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(bottomSheetContext).padding.bottom + 24),
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
                      Navigator.pop(bottomSheetContext);
                      showModalBottomSheet(
                        context: context, // Uses the safe MainScreen context
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (context) => const QuickAddModal()
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.success, child: Icon(Icons.add, color: Colors.black)),
                    title: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      showModalBottomSheet(
                        context: context, // Uses the safe MainScreen context
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (context) => const QuickAddIncomeModal()
                      );
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
        color: Colors.transparent,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 2,
        ),
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: GNav(
                backgroundColor: Colors.transparent,
                color: Colors.white54,
                activeColor: Colors.black,
                tabBackgroundColor: AppTheme.accent,
                gap: 6,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                tabs: [
                  const GButton(icon: Icons.dashboard_rounded, text: 'Home'),
                  const GButton(icon: Icons.account_balance_wallet_rounded, text: 'Budget'),
                  const GButton(icon: Icons.history_rounded, text: 'Review'),
                  GButton(
                    icon: Icons.inbox_rounded,
                    text: 'Inbox',
                    leading: Provider.of<BudgetProvider>(context).pendingTransactions.isNotEmpty
                        ? SizedBox(
                            width: 26,
                            height: 26,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(Icons.inbox_rounded, color: _selectedIndex == 3 ? Colors.black : Colors.white54),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${Provider.of<BudgetProvider>(context).pendingTransactions.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}