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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dot + title ────────────────────────────────────
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.reflectionDot,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text("Today's Reflection", style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),

          // ── Description ────────────────────────────────────
          Text(
            'Ground your thoughts. Taking just 5 minutes tonight '
            'will help clear your mind for rest.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 20),

          // ── Primary button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text("Start Today's Reflection  →",
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
              Flexible(
                child: Text(
                  'Your evening reflection typically opens at 6:00 PM.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
