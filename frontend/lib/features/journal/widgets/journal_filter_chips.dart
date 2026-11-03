import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Filter row for journal entries displaying "All Entries" and "Saved" (Bookmarked).
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

  static const List<Map<String, String>> filters = [
    {'id': 'all', 'label': 'All Entries', 'emoji': '✨'},
    {'id': 'saved', 'label': 'Saved', 'emoji': '📌'},
  ];

  @override
  Widget build(BuildContext context) {
    final isSavedActive = selectedFilter == 'saved' ||
        selectedFilter == 'bookmarked' ||
        selectedFilter == 'tag:saved';

    return Row(
      children: filters.map((f) {
        final id = f['id']!;
        final isSelected = id == 'all' ? !isSavedActive : isSavedActive;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              onSelected(id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Text(
                    f['emoji']!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f['label']!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
