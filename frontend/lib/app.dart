import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/today/pages/today_page.dart';

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
      home: const TodayPage(),
    );
  }
}
