import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows a summary of yesterday's reflection with mood tag and accent bar.
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.calmTagText.withValues(alpha: 0.5),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Yesterday's Summary",
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.calmTagBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$mood $moodEmoji',
                  style:
                      AppTextStyles.tag.copyWith(color: AppColors.calmTagText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
