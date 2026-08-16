import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Month/year header with left/right navigation arrows.
class MonthHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthHeader({
    super.key,
    required this.focusedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return focusedMonth.year == now.year && focusedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left arrow
        _ArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),

        // Month + Year
        Column(
          children: [
            Text(
              _months[focusedMonth.month - 1],
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${focusedMonth.year}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),

        // Right arrow (disabled if current month)
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: _isCurrentMonth ? null : onNext,
          disabled: _isCurrentMonth,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _ArrowButton({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surface.withValues(alpha: 0.5)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: disabled ? AppColors.textHint : AppColors.textPrimary,
        ),
      ),
    );
  }
}
