import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A 7-column calendar grid for the given month.
///
/// Days with reflections show a colored dot indicator.
/// The selected day gets a filled salmon circle.
/// Today gets a subtle ring outline.
class CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Set<DateTime> reflectionDays;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.reflectionDays,
    required this.onDaySelected,
  });

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final firstWeekday = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    return Column(
      children: [
        // ── Day-of-week labels ─────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _dayLabels
              .map((label) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // ── Day cells ──────────────────────────────────────
        ..._buildWeeks(daysInMonth, firstWeekday, today),
      ],
    );
  }

  List<Widget> _buildWeeks(int daysInMonth, int firstWeekday, DateTime today) {
    final weeks = <Widget>[];
    int dayCounter = 1;

    for (int week = 0; dayCounter <= daysInMonth; week++) {
      final cells = <Widget>[];

      for (int col = 0; col < 7; col++) {
        if ((week == 0 && col < firstWeekday) || dayCounter > daysInMonth) {
          cells.add(const SizedBox(width: 36, height: 42));
        } else {
          final day = DateTime(focusedMonth.year, focusedMonth.month, dayCounter);
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected = selectedDay != null &&
              day.year == selectedDay!.year &&
              day.month == selectedDay!.month &&
              day.day == selectedDay!.day;
          final hasReflection = reflectionDays.contains(
            DateTime(day.year, day.month, day.day),
          );
          final isFuture = day.isAfter(today);

          cells.add(
            _DayCell(
              day: dayCounter,
              isToday: isToday,
              isSelected: isSelected,
              hasReflection: hasReflection,
              isFuture: isFuture,
              onTap: isFuture ? null : () => onDaySelected(day),
            ),
          );
          dayCounter++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: cells,
          ),
        ),
      );
    }

    return weeks;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasReflection;
  final bool isFuture;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasReflection,
    required this.isFuture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;
    Border? border;

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isToday) {
      border = Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5);
    }

    if (isFuture) {
      textColor = AppColors.textHint.withValues(alpha: 0.4);
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Reflection indicator dot
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasReflection
                    ? (isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.calmTagText)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
