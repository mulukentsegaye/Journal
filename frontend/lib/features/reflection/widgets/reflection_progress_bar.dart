import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Animated progress bar showing "Progress  X of Y" with a
/// smooth fill animation on each step change.
class ReflectionProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const ReflectionProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label row ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$current of $total',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Bar ───────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                  ),
                ),
                // Fill
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// FractionallySizedBox with animated width transitions.
class AnimatedFractionallySizedBox extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    required this.curve,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: duration,
      curve: curve,
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor.clamp(0.0, 1.0),
      child: child,
    );
  }
}
