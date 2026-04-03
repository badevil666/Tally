# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Regenerate Isar model code (run after modifying any @collection model)
dart run build_runner build

# Regenerate launcher icons
flutter pub run flutter_launcher_icons
```

## Architecture

**Keep** is a Flutter personal finance app (budget tracking, expense categorization, SMS-based transaction detection).

### Layer Structure

```
lib/
├── core/           # Theme (AppTheme) and utilities
├── data/
│   ├── models/     # Isar @collection models (auto-generates .g.dart files)
│   └── providers/  # StorageProvider — Isar DB initialization
├── logic/
│   └── providers/  # BudgetProvider (ChangeNotifier) — all business logic
├── services/       # SmsService, NotificationService, BootstrapService
├── ui/
│   ├── screens/    # Full-page screens
│   └── widgets/    # Reusable components
└── main.dart       # Entry point — initializes services, MultiProvider, then app
```

### State Management

Single `BudgetProvider` (ChangeNotifier via `provider` package) holds all app state. It is the sole interface between UI and the Isar database.

### Database

Isar embedded database. Models live in `lib/data/models/` and are annotated with `@collection`. After modifying any model, run `dart run build_runner build` to regenerate the `.g.dart` companion files. Never edit `.g.dart` files manually.

### Data Models

- **BudgetModel** — income and savings goal for the period
- **CategoryModel** — expense categories; distinguishes fixed bills vs. variable
- **TransactionModel** — expense entries linked to a category
- **InflowModel** — income/inflow sources
- **PendingTransactionModel** — SMS-detected transactions awaiting user confirmation

### App Navigation

`InitialRoute` renders conditionally: no budget → `OnboardingScreen`; budget exists → `MainScreen` (4-tab bottom nav: Dashboard, Budget Planner, Review, Inbox).

### SMS Service

`SmsService` listens for incoming SMS, uses regex to extract amounts (RS/INR/$), and creates `PendingTransactionModel` entries that appear in the Inbox tab for the user to confirm or dismiss.

## Key Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management (ChangeNotifier) |
| `isar` + `isar_flutter_libs` | Embedded local database |
| `telephony` | SMS reading/listening |
| `flutter_local_notifications` | Push notifications |
| `fl_chart` | Charts on Dashboard/Review |
| `flutter_animate` | UI animations |
| `shared_preferences` | Simple key-value persistence (non-financial prefs) |
