import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/utils/streak_calculator.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';

void main() {
  group('StreakCalculator Longest Streak Tests', () {
    ReflectionEntryModel makeEntry(DateTime dt, String id) {
      return ReflectionEntryModel(
        id: id,
        date: dt,
        mood: 'Calm',
        moodEmoji: '🌿',
        answers: const {},
        createdAt: dt,
      );
    }

    test('returns 0 for empty entries list', () {
      expect(StreakCalculator.calculateLongestStreak([]), equals(0));
    });

    test('returns 1 for a single reflection entry', () {
      final entries = [
        makeEntry(DateTime(2026, 5, 10), '1'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(1));
    });

    test('returns 1 when multiple entries occur on the exact same day', () {
      final entries = [
        makeEntry(DateTime(2026, 5, 10, 8, 30), '1'),
        makeEntry(DateTime(2026, 5, 10, 14, 0), '2'),
        makeEntry(DateTime(2026, 5, 10, 21, 15), '3'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(1));
    });

    test('calculates longest streak accurately even when current streak is broken (0)', () {
      // 4 consecutive days in the past, but inactive currently
      final entries = [
        makeEntry(DateTime(2026, 1, 1), '1'),
        makeEntry(DateTime(2026, 1, 2), '2'),
        makeEntry(DateTime(2026, 1, 3), '3'),
        makeEntry(DateTime(2026, 1, 4), '4'),
      ];
      expect(StreakCalculator.calculateStreak(entries), equals(0));
      expect(StreakCalculator.calculateLongestStreak(entries), equals(4));
    });

    test('picks the maximum across multiple separated streaks', () {
      // Streak A: 3 days (March 1-3)
      // Gap: March 4-9
      // Streak B: 5 days (March 10-14)
      // Gap: March 15-19
      // Streak C: 2 days (March 20-21)
      final entries = [
        makeEntry(DateTime(2026, 3, 1), 'a1'),
        makeEntry(DateTime(2026, 3, 2), 'a2'),
        makeEntry(DateTime(2026, 3, 3), 'a3'),
        makeEntry(DateTime(2026, 3, 10), 'b1'),
        makeEntry(DateTime(2026, 3, 11), 'b2'),
        makeEntry(DateTime(2026, 3, 12), 'b3'),
        makeEntry(DateTime(2026, 3, 13), 'b4'),
        makeEntry(DateTime(2026, 3, 14), 'b5'),
        makeEntry(DateTime(2026, 3, 20), 'c1'),
        makeEntry(DateTime(2026, 3, 21), 'c2'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(5));
    });

    test('correctly handles month and year rollovers', () {
      // Dec 30, Dec 31, Jan 1, Jan 2
      final entries = [
        makeEntry(DateTime(2025, 12, 30), '1'),
        makeEntry(DateTime(2025, 12, 31), '2'),
        makeEntry(DateTime(2026, 1, 1), '3'),
        makeEntry(DateTime(2026, 1, 2), '4'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(4));
    });

    test('handles leap year transition (Feb 28 to Feb 29 to Mar 1)', () {
      final entries = [
        makeEntry(DateTime(2024, 2, 28), '1'),
        makeEntry(DateTime(2024, 2, 29), '2'),
        makeEntry(DateTime(2024, 3, 1), '3'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(3));
    });

    test('works regardless of entry sorting order in the input list', () {
      final entries = [
        makeEntry(DateTime(2026, 4, 3), '3'),
        makeEntry(DateTime(2026, 4, 1), '1'),
        makeEntry(DateTime(2026, 4, 4), '4'),
        makeEntry(DateTime(2026, 4, 2), '2'),
      ];
      expect(StreakCalculator.calculateLongestStreak(entries), equals(4));
    });
  });
}
