import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/utils/streak_calculator.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';

void main() {
  group('StreakCalculator Tests', () {
    test('Empty entry list returns 0 streak', () {
      final streak = StreakCalculator.calculateStreak([]);
      expect(streak, 0);
    });

    test('Consecutive daily reflections ending today calculate streak correctly', () {
      final now = DateTime.now();
      final entries = [
        ReflectionEntryModel(
          id: '1',
          date: now,
          createdAt: now,
        ),
        ReflectionEntryModel(
          id: '2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ReflectionEntryModel(
          id: '3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, 3);
    });

    test('Active streak maintained when reflected yesterday but not yet today', () {
      final now = DateTime.now();
      final entries = [
        ReflectionEntryModel(
          id: '1',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        ReflectionEntryModel(
          id: '2',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, 2);
    });

    test('Broken streak older than yesterday returns 0', () {
      final now = DateTime.now();
      final entries = [
        ReflectionEntryModel(
          id: '1',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, 0);
    });

    test('Multiple entries on same day count as 1 streak day', () {
      final now = DateTime.now();
      final entries = [
        ReflectionEntryModel(
          id: '1',
          date: now,
          createdAt: now,
        ),
        ReflectionEntryModel(
          id: '2',
          date: now,
          createdAt: now,
        ),
      ];

      final streak = StreakCalculator.calculateStreak(entries);
      expect(streak, 1);
    });

    test('calculateCompletedDaysInMonth counts unique days in given month', () {
      final focusedMonth = DateTime(2026, 8, 1);
      final entries = [
        ReflectionEntryModel(
          id: '1',
          date: DateTime(2026, 8, 5),
          createdAt: DateTime(2026, 8, 5),
        ),
        ReflectionEntryModel(
          id: '2',
          date: DateTime(2026, 8, 5), // duplicate same day
          createdAt: DateTime(2026, 8, 5),
        ),
        ReflectionEntryModel(
          id: '3',
          date: DateTime(2026, 8, 12),
          createdAt: DateTime(2026, 8, 12),
        ),
        ReflectionEntryModel(
          id: '4',
          date: DateTime(2026, 7, 20), // different month
          createdAt: DateTime(2026, 7, 20),
        ),
      ];

      final count = StreakCalculator.calculateCompletedDaysInMonth(entries, focusedMonth);
      expect(count, 2);
    });
  });
}
