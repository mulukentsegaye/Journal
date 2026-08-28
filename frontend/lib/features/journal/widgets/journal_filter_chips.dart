import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Horizontal list of filter chips for journal entries.
class JournalFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const JournalFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  static const List<Map<String, String>> filters = [
    {'id': 'all', 'label': 'All Entries', 'emoji': '✨'},
    {'id': 'bookmarked', 'label': 'Saved', 'emoji': '📌'},
    {'id': 'calm', 'label': 'Calm', 'emoji': '🌿'},
    {'id': 'grateful', 'label': 'Grateful', 'emoji': '🙏'},
    {'id': 'happy', 'label': 'Happy', 'emoji': '☀️'},
    {'id': 'reflective', 'label': 'Reflective', 'emoji': '💭'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
