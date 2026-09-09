import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A 7-column calendar grid for the given month.
///
/// Days with reflections show a soft tinted background with a dot.
/// The selected day gets a filled salmon circle.
/// Today gets a subtle ring outline.
class CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Set<DateTime> reflectionDays;
  final Map<DateTime, int>? entryCounts;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.reflectionDays,
    this.entryCounts,
    required this.onDaySelected,
  });

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final firstWeekday =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    return Column(
      children: [
        // ── Day-of-week labels ─────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels
                .map((label) => SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          label,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

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
          cells.add(const SizedBox(width: 38, height: 46));
        } else {
          final day =
              DateTime(focusedMonth.year, focusedMonth.month, dayCounter);
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected = selectedDay != null &&
              day.year == selectedDay!.year &&
              day.month == selectedDay!.month &&
              day.day == selectedDay!.day;
          final dayDate = DateTime(day.year, day.month, day.day);
          final hasReflection = reflectionDays.contains(dayDate);
          final entryCount = entryCounts?[dayDate] ?? (hasReflection ? 1 : 0);
          final isFuture = day.isAfter(today);

          cells.add(
            _DayCell(
              day: dayCounter,
              isToday: isToday,
              isSelected: isSelected,
              hasReflection: hasReflection,
              entryCount: entryCount,
              isFuture: isFuture,
              onTap: isFuture ? null : () => onDaySelected(day),
            ),
          );
          dayCounter++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
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
  final int entryCount;
  final bool isFuture;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasReflection,
    this.entryCount = 0,
    required this.isFuture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;
    BoxBorder? border;

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isToday) {
      border = Border.all(
          color: AppColors.primary.withValues(alpha: 0.5), width: 1.5);
    } else if (hasReflection) {
      // Soft tinted background so reflected days are clearly visible
      bgColor = AppColors.calmTagBg.withValues(alpha: 0.7);
    }

    if (isFuture) {
      textColor = AppColors.textHint.withValues(alpha: 0.35);
    }

    final dotColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.calmTagText;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: border,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isToday || isSelected || hasReflection
                          ? FontWeight.w600
                          : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Reflection indicator dots
            if (hasReflection)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (entryCount > 1) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  if (entryCount > 2) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              )
            else
              const SizedBox(height: 3.5),
          ],
        ),
      ),
    );
  }
}
