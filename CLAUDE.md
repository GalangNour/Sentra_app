# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or emulator
flutter run

# Build APK
flutter build apk

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

**State management**: No external state management library. A plain Dart singleton — `AppState.instance` (`lib/core/services/app_state.dart`) — owns all runtime data and persists it through three Hive boxes opened at startup (`transactions`, `customCategories`, `settings`). Screens call `AppState.instance` directly and call `setState(() {})` after any mutating operation.

**Data flow**: `main()` → `AppState.instance.init()` (opens Hive, loads all data into in-memory lists) → `HomeScreen`. Navigation is imperative (`Navigator.push`); each screen receives an `AppState.instance` reference directly, not via `InheritedWidget` or `Provider`.

**Key files**:
- `lib/core/utils/app_utils.dart` — all models (`Transaction`, `BudgetItem`, `CustomCategory`), enums (`TransactionType`, `TransactionCategory`), `CategoryMeta` static lookup, and the `Fmt` formatting utility. Everything data-related lives here.
- `lib/core/services/app_state.dart` — singleton: Hive I/O, in-memory lists, computed getters (`balance`, `totalIncome`, `totalExpense`), category resolution helpers (`categoryLabel/Icon/Color`), and `suggestTitles()` autocomplete.
- `lib/core/services/ocr_service.dart` — Google ML Kit wrapper. Stateless; `processReceipt(imagePath)` returns `ParsedReceiptData` (merchant, total, category, rawText). Category is guessed via keyword heuristics against Indonesian store/brand names.
- `lib/core/theme/app_theme.dart` — single dark theme only. All colors as `AppColors` constants; use these, not hardcoded hex.

**OCR scan flow**: `CameraScreen` → captures photo → `OcrService.processReceipt()` → constructs `ScanPrefill` → pushes `AddTransactionScreen(scanData: ...)`. `AddTransactionScreen` handles three modes: new transaction, edit existing (`editTransaction`), and scan prefill (`scanData`).

**Category system**: Two-tier. Built-in categories are `TransactionCategory` enum values resolved via `CategoryMeta`. Custom categories are `CustomCategory` objects stored in Hive and referenced by UUID (`customCategoryId` on `Transaction`). When `customCategoryId` is non-null, it takes precedence. Always use `AppState.categoryLabel/Icon/Color(tx)` to resolve — never inspect the enum directly in UI code.

**Amount formatting**: `ThousandsSeparatorFormatter` uses dots as thousand separators (Indonesian convention: `8.500.000`). `Fmt.compact()` produces short form (`Rp 8,5jt`); `Fmt.full()` produces the full dotted form. Currency symbol and position are set globally via `Fmt.setCurrency()` when the user changes currency.

**`BudgetItem`** is defined in `app_utils.dart` but not yet wired to any screen — it is scaffolding for a future budget feature.

**UI conventions**: Dark theme only. All text labels are in Indonesian. Haptic feedback (`HapticFeedback.mediumImpact()` / `.selectionClick()`) is expected on interactive taps. Animated transitions use `TweenAnimationBuilder` inline rather than named `AnimationController` subclasses where possible.
