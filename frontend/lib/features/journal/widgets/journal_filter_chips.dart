import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Filter row for journal entries displaying only the Saved filter.
class JournalFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSelected;
  final List<String> availableTags;

  const JournalFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
    this.availableTags = const [],
  });

  bool get _isSavedSelected =>
      selectedFilter == 'saved' ||
      selectedFilter == 'bookmarked' ||
      selectedFilter == 'tag:saved';

  @override
  Widget build(BuildContext context) {
    final isSelected = _isSavedSelected;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (isSelected) {
              onSelected('all');
            } else {
              onSelected('saved');
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.divider.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📌',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saved',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
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
