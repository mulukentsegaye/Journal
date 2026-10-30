import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/core/services/settings_service.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';
import 'package:daily_reflection/features/reflection/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
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

    test('exportAllReflectionsMarkdown filters out deleted entries and formats markdown', () async {
      final settings = SettingsService();
      final db = DatabaseService();

      final activeEntry = ReflectionEntryModel(
        id: 'active_md_1',
        date: DateTime(2026, 9, 1),
        mood: 'Joyful',
        moodEmoji: '✨',
        freeformTitle: 'Wonderful day',
        freeformNote: 'Had a productive coding session.',
        answers: const {1: 'Great coffee'},
        isBookmarked: true,
        createdAt: DateTime(2026, 9, 1),
      );

      final deletedEntry = ReflectionEntryModel(
        id: 'deleted_md_1',
        date: DateTime(2026, 8, 30),
        mood: 'Tired',
        moodEmoji: '😴',
        freeformTitle: 'Rough night',
        freeformNote: 'Did not sleep well.',
        tags: const ['gratitude', '#peace'],
        isDeleted: true,
        deletedAt: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 8, 30),
      );

      final activeWithTags = activeEntry.copyWith(tags: const ['gratitude', 'mindset']);

      await db.saveReflection(activeWithTags);
      await db.saveReflection(deletedEntry);

      final markdown = await settings.exportAllReflectionsMarkdown();

      // Should include active entry & tags
      expect(markdown, contains('Total Reflections: 1'));
      expect(markdown, contains('Wonderful day'));
      expect(markdown, contains('Had a productive coding session.'));
      expect(markdown, contains('Joyful ✨'));
      expect(markdown, contains('Great coffee'));
      expect(markdown, contains('**Tags**: #gratitude #mindset'));

      // Should NOT include deleted entry
      expect(markdown, isNot(contains('Rough night')));
      expect(markdown, isNot(contains('Did not sleep well.')));
    });

    test('exportAllReflectionsJson outputs valid JSON backup without deleted entries', () async {
      final settings = SettingsService();
      final db = DatabaseService();

      final activeEntry = ReflectionEntryModel(
        id: 'json_active_1',
        date: DateTime(2026, 9, 2),
        mood: 'Peaceful',
        moodEmoji: '🌿',
        freeformTitle: 'Json Export Test',
        freeformNote: 'Testing JSON backup serialization.',
        tags: const ['backup', 'export'],
        createdAt: DateTime(2026, 9, 2),
      );

      final deletedEntry = ReflectionEntryModel(
        id: 'json_deleted_1',
        date: DateTime(2026, 9, 1),
        mood: 'Stressed',
        isDeleted: true,
        createdAt: DateTime(2026, 9, 1),
      );

      await db.saveReflection(activeEntry);
      await db.saveReflection(deletedEntry);

      final jsonString = await settings.exportAllReflectionsJson();
      expect(jsonString, isNotEmpty);

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['app'], equals('Journal'));
      expect(decoded['total_entries'], equals(1));
      expect(decoded['entries'], isA<List>());
      final entriesList = decoded['entries'] as List;
      expect(entriesList.length, equals(1));
      expect(entriesList.first['id'], equals('json_active_1'));
      expect(entriesList.first['freeformTitle'], equals('Json Export Test'));
      expect(entriesList.first['tags'], containsAll(['backup', 'export']));
    });
  });
}
