import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentra_app/features/settings/cubit/settings_cubit.dart';
import 'package:sentra_app/screens/activity_screen.dart';
import 'package:sentra_app/screens/home_screen.dart';
import 'package:sentra_app/screens/settings_screen.dart';
import 'package:sentra_app/screens/statistik_screen.dart';
import 'package:sentra_app/widgets/ai_modal_sheet.dart';
import 'package:sentra_app/widgets/main_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // null = belum pernah dibuka; dibuat sekali saat user pertama kali ke tab statistik
  Widget? _statistikScreen;

  void _onNavTap(int index) {
    if (index == 2) {
      AiModalSheet.show(context);
      return;
    }
    setState(() {
      if (index == 3 && _statistikScreen == null) {
        _statistikScreen = const StatistikScreen();
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsCubit>();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ActivityScreen(),
          const SizedBox.shrink(),
          _statistikScreen ?? const SizedBox.shrink(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        modalContext: context,
      ),
    );
  }
}
