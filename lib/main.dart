import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/core/repositories/budget_repository.dart';
import 'package:sentra_app/core/repositories/custom_category_repository.dart';
import 'package:sentra_app/core/repositories/installment_plan_repository.dart';
import 'package:sentra_app/core/repositories/recap_repository.dart';
import 'package:sentra_app/core/repositories/settings_repository.dart';
import 'package:sentra_app/core/repositories/transaction_repository.dart';
import 'package:sentra_app/core/services/app_storage.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/features/budgets/cubit/budgets_cubit.dart';
import 'package:sentra_app/features/categories/cubit/categories_cubit.dart';
import 'package:sentra_app/features/installments/cubit/installments_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/features/settings/cubit/settings_state.dart';
import 'package:sentra_app/features/transactions/cubit/transactions_cubit.dart';
import 'package:sentra_app/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(SentraApp(storage: storage));
}

class SentraApp extends StatelessWidget {
  const SentraApp({super.key, required this.storage});

  final AppStorage storage;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => TransactionRepository(storage.transactionsBox),
        ),
        RepositoryProvider(
          create: (_) => CustomCategoryRepository(storage.customCategoriesBox),
        ),
        RepositoryProvider(
          create: (_) => InstallmentPlanRepository(storage.installmentPlansBox),
        ),
        RepositoryProvider(
          create: (_) => SettingsRepository(storage.settingsBox),
        ),
        RepositoryProvider(
          create: (_) => BudgetRepository(storage.budgetsBox),
        ),
        RepositoryProvider(
          create: (_) => RecapRepository(storage.prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                SettingsCubit(context.read<SettingsRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                TransactionsCubit(context.read<TransactionRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                CategoriesCubit(context.read<CustomCategoryRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                InstallmentsCubit(context.read<InstallmentPlanRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                BudgetsCubit(context.read<BudgetRepository>()),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            SystemChrome.setSystemUIOverlayStyle(
              AppTheme.overlayStyle(settingsState.themePreset),
            );
            return MaterialApp(
              title: 'Sentra',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(
                preset: settingsState.themePreset,
                accent: settingsState.accent,
                font: settingsState.fontPreset,
              ),
              home: const MainScreen(),
            );
          },
        ),
      ),
    );
  }
}
