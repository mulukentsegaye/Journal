import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Horizontal list of filter chips for journal entries (moods and tags).
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
    {'id': 'bookmarked', 'label': 'Saved', 'emoji': '📌'},
    {'id': 'calm', 'label': 'Calm', 'emoji': '🌿'},
    {'id': 'grateful', 'label': 'Grateful', 'emoji': '🙏'},
    {'id': 'happy', 'label': 'Happy', 'emoji': '☀️'},
    {'id': 'anxious', 'label': 'Anxious', 'emoji': '😰'},
    {'id': 'tired', 'label': 'Tired', 'emoji': '😫'},
  ];

  @override
  Widget build(BuildContext context) {
    // Generate combined list of mood filters + dynamic tag filters
    final tagFilters = availableTags.map((tag) {
      final clean = tag.replaceAll('#', '').trim();
      return {
        'id': 'tag:${clean.toLowerCase()}',
        'label': '#$clean',
        'emoji': '🏷️',
      };
    }).toList();

    final allItems = [...filters, ...tagFilters];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: allItems.map((f) {
          final isSelected = selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (isSelected && f['id'] != 'all') {
                  onSelected('all');
                } else {
                  onSelected(f['id']!);
                }
              },
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
