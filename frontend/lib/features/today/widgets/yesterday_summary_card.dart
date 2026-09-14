import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows a summary of yesterday's reflection with mood tag and accent bar.
class YesterdaySummaryCard extends StatelessWidget {
  final String summary;
  final String date;
  final String mood;
  final String moodEmoji;
  final String? photoUrl;
  final String title;
  final VoidCallback? onTap;

  const YesterdaySummaryCard({
    super.key,
    required this.summary,
    required this.date,
    required this.mood,
    required this.moodEmoji,
    this.photoUrl,
    this.title = 'Recent Entry',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
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
            const SizedBox(height: 12),

            // ── Summary text ───────────────────────────────────
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

                // ── Mood tag & Photo tag ───────────────────────────
                Row(
                  children: [
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
                    if (hasPhoto) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Photo',
                              style: AppTextStyles.tag.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
      ),
    );
  }
}
