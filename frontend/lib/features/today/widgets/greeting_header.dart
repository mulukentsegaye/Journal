import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Top section of the Today page:
///   "Good evening, Alex"  🔥 12 Day Streak
///   "Welcome back to your quiet space."
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting row ───────────────────────────────────────
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_greetingText()}, Alex',
              style: AppTextStyles.greeting,
            ),
            // Streak badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.streakBadgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '12 Day Streak',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.streakBadgeText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Subtitle ──────────────────────────────────────────
        Text(
          'Welcome back to your quiet space.',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}
