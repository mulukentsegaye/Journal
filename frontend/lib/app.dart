import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'features/today/pages/today_page.dart';
import 'features/history/pages/history_page.dart';
import 'features/journal/pages/journal_page.dart';
import 'features/freeform/pages/freeform_page.dart';
import 'shared/widgets/bottom_nav_bar.dart';

/// Root widget that configures MaterialApp with the
/// Daily Reflection theme and initial route.
class DailyReflectionApp extends StatelessWidget {
  const DailyReflectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Daily Reflection',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsService().themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Top-level shell that manages the bottom navigation
/// and swaps between feature pages.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // The pages managed by bottom navigation.
  // Indices 2 & 3 are placeholders until those features are built.
  static const _pages = <Widget>[
    TodayPage(),       // 0 — Today
    HistoryPage(),     // 1 — Journey
    JournalPage(),     // 2 — Journal
    FreeformPage(isStandalone: false), // 3 — Space
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
