import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Card showing the user's freeform note written during reflection.
class FreeformSummaryCard extends StatelessWidget {
  final String? title;
  final String note;

  const FreeformSummaryCard({
    super.key,
    this.title,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Tag / Header
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Freeform Note',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (title != null && title!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              title!,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            note,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
