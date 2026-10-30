import '../../features/reflection/models/reflection_entry_model.dart';

/// Centralized utility for computing user reflection streaks and stats.
class StreakCalculator {
  StreakCalculator._();

  /// Calculates consecutive reflection streak days from a list of entries.
  /// A streak is active if the user reflected today or yesterday.
  static int calculateStreak(List<ReflectionEntryModel> entries) {
    if (entries.isEmpty) return 0;

    final Set<DateTime> uniqueDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate;
    if (uniqueDates.contains(today)) {
      checkDate = today;
    } else if (uniqueDates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (uniqueDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates the longest consecutive reflection streak achieved across all time.
  static int calculateLongestStreak(List<ReflectionEntryModel> entries) {
    if (entries.isEmpty) return 0;

    final Set<DateTime> uniqueDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();

    if (uniqueDates.isEmpty) return 0;

    final sortedDates = uniqueDates.toList()..sort();

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = sortedDates[i - 1];
      final curr = sortedDates[i];
      final nextDayOfPrev = DateTime(prev.year, prev.month, prev.day + 1);

      if (curr.year == nextDayOfPrev.year &&
          curr.month == nextDayOfPrev.month &&
          curr.day == nextDayOfPrev.day) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Calculates the number of unique days the user reflected during the specified month.
  static int calculateCompletedDaysInMonth(
    List<ReflectionEntryModel> entries,
    DateTime focusedMonth,
  ) {
    final Set<DateTime> uniqueDates = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();

    return uniqueDates
        .where((d) =>
            d.year == focusedMonth.year && d.month == focusedMonth.month)
        .length;
  }
}
