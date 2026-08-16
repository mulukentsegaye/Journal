import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../pages/history_page.dart';

/// Detail card shown below the calendar when a day is selected.
///
/// If the selected day has a reflection, it shows the mood, summary,
/// and stats. Otherwise it shows an encouraging empty-state message.
class DayDetailCard extends StatelessWidget {
  final DateTime day;
  final ReflectionEntry? entry;

  const DayDetailCard({
    super.key,
    required this.day,
    this.entry,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String get _formattedDate =>
      '${_weekdays[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}';

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${day.year}-${day.month}-${day.day}'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: entry != null ? _buildFilledState() : _buildEmptyState(),
      ),
    );
  }

  Widget _buildFilledState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Date header ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _isToday ? 'Today' : _formattedDate,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Mood pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.calmTagBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry!.mood} ${entry!.moodEmoji}',
                style: AppTextStyles.tag.copyWith(color: AppColors.calmTagText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Summary text ─────────────────────────────────
        Text(
          '"${entry!.summary}"',
          style: AppTextStyles.summaryQuote,
        ),
        const SizedBox(height: 18),

        // ── Stats row ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.chat_bubble_outline_rounded,
                value: '${entry!.questionsAnswered}',
                label: 'Questions',
              ),
              Container(width: 1, height: 28, color: AppColors.divider),
              _StatItem(
                icon: Icons.timer_outlined,
                value: '${entry!.minutesSpent} min',
                label: 'Duration',
              ),
              Container(width: 1, height: 28, color: AppColors.divider),
              _StatItem(
                icon: Icons.auto_awesome_rounded,
                value: entry!.mood,
                label: 'Mood',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _isToday ? '✨' : '—',
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          _isToday
              ? 'Your reflection awaits tonight.'
              : 'No reflection recorded this day.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textHint,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isToday) ...[
          const SizedBox(height: 4),
          Text(
            'Every quiet moment counts.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.badge.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
