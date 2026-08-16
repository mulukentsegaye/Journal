import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows a summary of yesterday's reflection, including mood tag.
class YesterdaySummaryCard extends StatelessWidget {
  final String summary;
  final String date;
  final String mood;
  final String moodEmoji;

  const YesterdaySummaryCard({
    super.key,
    required this.summary,
    required this.date,
    required this.mood,
    required this.moodEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Yesterday's Summary", style: AppTextStyles.sectionTitle),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.streakBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(date, style: AppTextStyles.dateTag),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Summary text ───────────────────────────────────
          Text(
            '"$summary"',
            style: AppTextStyles.summaryQuote,
          ),
          const SizedBox(height: 14),

          // ── Mood tag ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.calmTagBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$mood $moodEmoji',
              style: AppTextStyles.tag.copyWith(color: AppColors.calmTagText),
            ),
          ),
        ],
      ),
    );
  }
}
