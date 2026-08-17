import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/app.dart';
import 'package:daily_reflection/core/theme/app_theme.dart';
import 'package:daily_reflection/features/auth/pages/auth_page.dart';

void main() {
  testWidgets('AppShell renders all navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppShell(),
      ),
    );

    // Verify the greeting or streak is displayed
    expect(find.textContaining('Streak'), findsOneWidget);

    // Verify all 4 bottom nav tabs are displayed
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Space'), findsOneWidget);
  });

  testWidgets('AuthPage renders title, mode switch, and submit button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AuthPage(),
      ),
    );

    expect(find.text('Daily Reflection'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2)); // Tab and button
    expect(find.text('Create Account'), findsOneWidget);
  });
}
