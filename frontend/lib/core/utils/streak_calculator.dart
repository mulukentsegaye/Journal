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
