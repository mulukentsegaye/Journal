import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Previous / Next navigation buttons at the bottom of the
/// reflection flow.
///
/// "Previous" is a subtle outlined button.
/// "Next Question →" is a filled salmon button.
/// On the last question, the next button says "Finish Reflection ✓".
class ReflectionNavButtons extends StatelessWidget {
  final bool showPrevious;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ReflectionNavButtons({
    super.key,
    required this.showPrevious,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Previous button ────────────────────────────────
        if (showPrevious)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.divider,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

        if (showPrevious) const SizedBox(width: 12),

        // ── Next / Finish button ───────────────────────────
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                isLast ? 'Finish Reflection  ✓' : 'Next Question  →',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
