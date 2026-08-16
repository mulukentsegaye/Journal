import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/today/pages/today_page.dart';
import 'features/history/pages/history_page.dart';
import 'shared/widgets/bottom_nav_bar.dart';
import 'core/theme/app_colors.dart';

/// Root widget that configures MaterialApp with the
/// Daily Reflection theme and initial route.
class DailyReflectionApp extends StatelessWidget {
  const DailyReflectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Reflection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
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
    _PlaceholderPage(title: 'Journal', icon: Icons.edit_note_rounded),  // 2
    _PlaceholderPage(title: 'Space', icon: Icons.person_outline_rounded), // 3
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

/// Temporary placeholder for pages not yet built.
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
