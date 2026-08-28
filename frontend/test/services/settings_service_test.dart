import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService & Onboarding Tests', () {
    test('default onboarding state is false for first time user', () async {
      final settings = SettingsService();
      await settings.loadSettings();

      expect(settings.hasCompletedOnboarding, isFalse);
    });

    test('completeOnboarding sets flag and persists', () async {
      final settings = SettingsService();
      await settings.loadSettings();

      await settings.completeOnboarding();
      expect(settings.hasCompletedOnboarding, isTrue);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_has_completed_onboarding'), isTrue);
    });

    test('resetOnboarding allows replaying tour', () async {
      final settings = SettingsService();
      await settings.completeOnboarding();
      expect(settings.hasCompletedOnboarding, isTrue);

      await settings.resetOnboarding();
      expect(settings.hasCompletedOnboarding, isFalse);
    });

    test('theme mode toggle and persistence', () async {
      final settings = SettingsService();
      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, equals(ThemeMode.dark));
      expect(settings.isDarkMode, isTrue);

      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, equals(ThemeMode.light));
      expect(settings.isDarkMode, isFalse);
    });
  });
}
