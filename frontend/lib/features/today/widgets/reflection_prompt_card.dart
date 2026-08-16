import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// CTA card for starting today's reflection.
///
/// Shows a colored dot, title, description, the primary button,
/// and a muted note about when the reflection typically opens.
class ReflectionPromptCard extends StatelessWidget {
  final VoidCallback? onStart;

  const ReflectionPromptCard({super.key, this.onStart});

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
          // ── Dot + title ────────────────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.reflectionDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text("Today's Reflection", style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 10),

          // ── Description ────────────────────────────────────
          Text(
            'Ground your thoughts. Taking just 5 minutes tonight '
            'will help clear your mind for rest.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),

          // ── Primary button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text("Start Today's Reflection →",
                  style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 14),

          // ── Note ───────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 5),
              Text(
                'Your evening reflection typically opens at 6:00 PM.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
