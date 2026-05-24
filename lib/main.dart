import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/storage_provider.dart';
import 'logic/providers/budget_provider.dart';
import 'services/notification_service.dart';
import 'services/sms_service.dart';
import 'services/ad_service.dart';
import 'services/consent_manager.dart';

import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/budget_planner_screen.dart';
import 'ui/screens/review_screen.dart';
import 'ui/screens/inbox_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/scan_pay_screen.dart';
import 'ui/widgets/quick_add_modal.dart';
import 'ui/widgets/quick_add_income_modal.dart';

void main() {
  // Keep the native splash on screen until the provider is ready — no
  // Flutter splash, no animation, no extra widgets. Real app appears the
  // moment storage finishes loading.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  NotificationService.initializeTimezones();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  BudgetProvider? _provider;
  AppLifecycleListener? _lifecycleListener;
  String? _errorMessage; // Added to catch and display boot errors

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _provider?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Storage + provider first — needed before any UI can render. Heavy
      // optional services (consent, ads, notifications, SMS) run in the
      // background AFTER the provider is ready, so they don't block boot.
      debugPrint("Boot: 1. Storage...");
      final storage = StorageProvider();
      await storage.init();

      debugPrint("Boot: 2. Provider...");
      final budgetProvider = BudgetProvider(storage);

      NotificationService.onCategorizeDone = (ptId, categoryId) async {
        await budgetProvider.reloadAfterBackground();
      };
      NotificationService.onNotificationTap = (ptId) =>
          budgetProvider.highlightPending(ptId);
      SmsService.onPendingAdded = (pt) => budgetProvider.notifyPendingAdded(pt);
      _lifecycleListener = AppLifecycleListener(
        onResume: () => budgetProvider.reloadAfterBackground(),
      );

      // Wait until the provider has actually pulled budget/categories from
      // Isar — otherwise InitialRoute briefly sees `budget == null` and
      // flashes Onboarding for users who already have a budget.
      await budgetProvider.initialLoad;

      if (mounted) {
        setState(() => _provider = budgetProvider);
      }
      // Remove the native splash now that the real UI can render with
      // the correct data — no flash of the wrong first screen.
      FlutterNativeSplash.remove();

      // Fire-and-forget: these run while the user uses the first screen.
      // None of them block the UI.
      unawaited(_deferredInit(budgetProvider));

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

  /// Runs after the provider is ready — does not block UI. Splash animation
  /// will play (and probably finish) while these complete in the background.
  Future<void> _deferredInit(BudgetProvider budgetProvider) async {
    try {
      await NotificationService.initCallbacksOnly();
      // Consent + ads can take >1s; let the splash hide their latency
      await ConsentManager.gatherConsent();
      await AdService.init();
      await NotificationService.requestPermissions();
      // Never prompts — Play Store policy requires an in-app disclosure
      // before requesting SMS permission. Triggered from OnboardingScreen.
      await SmsService.attachIfPermitted();
    } catch (e) {
      debugPrint('Deferred init error (non-fatal): $e');
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

    // While provider is loading the native splash is preserved on top
    // (set up by FlutterNativeSplash.preserve in main). Return a bare
    // black scaffold so there's no visual flicker — the native splash
    // stays above this until we explicitly remove it.
    if (_provider == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Colors.black),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MultiProvider(
        providers: [ChangeNotifierProvider.value(value: _provider!)],
        child: const KeepApp(),
      ),
    );
  }
}

/// Root widget for the real app — no MaterialApp here, the outer one
/// in [_AppBootstrapState.build] already provides theme + routing scaffold.
class KeepApp extends StatelessWidget {
  const KeepApp({super.key});

  @override
  Widget build(BuildContext context) => const InitialRoute();
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
                  ),
                  // UPI is India-only. Gate the tile on the user's country so
                  // non-Indian users don't see a feature they can't use.
                  if (context.read<BudgetProvider>().budget?.country == 'India') ...[
                    const Divider(color: Colors.white24, height: 32),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppTheme.accentBlue, child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white)),
                      title: const Text('Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text('Scan QR, pay, auto-log',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPayScreen()),
                        );
                      },
                    ),
                  ]
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