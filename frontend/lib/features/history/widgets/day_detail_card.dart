import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../reflection/models/reflection_entry_model.dart';

/// Detail card shown below the calendar when a day is selected.
///
/// If the selected day has one or more entries, it lists them with their
/// timestamp, mood badge, title, photo, snippet, and actions.
/// Otherwise it shows an encouraging empty-state message.
class DayDetailCard extends StatelessWidget {
  final DateTime day;
  final List<ReflectionEntryModel> entries;
  final ReflectionEntry? entry;
  final ValueChanged<ReflectionEntryModel>? onEdit;
  final ValueChanged<ReflectionEntryModel>? onDelete;
  final ValueChanged<ReflectionEntryModel>? onView;

  const DayDetailCard({
    super.key,
    required this.day,
    this.entries = const [],
    this.entry,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String get _formattedDate =>
      '${_weekdays[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}';

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  List<ReflectionEntryModel> get _effectiveEntries {
    if (entries.isNotEmpty) return entries;
    if (entry != null) {
      return [
        ReflectionEntryModel(
          id: entry!.id,
          date: day,
          mood: entry!.mood,
          moodEmoji: entry!.moodEmoji,
          freeformNote: entry!.summary,
          answers: const {},
          photoUrl: entry!.photoUrl,
          createdAt: day,
        )
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final list = _effectiveEntries;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${day.year}-${day.month}-${day.day}-${list.length}'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: list.isNotEmpty
            ? _buildFilledState(context, list)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildFilledState(
    BuildContext context,
    List<ReflectionEntryModel> list,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Date header & count badge ──────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isToday ? 'Today' : _formattedDate,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    list.length == 1
                        ? '1 thought recorded'
                        : '${list.length} thoughts recorded',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${list.length} ${list.length == 1 ? "entry" : "entries"}',
                style: AppTextStyles.tag.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Entries list ───────────────────────────────────
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              color: AppColors.divider.withValues(alpha: 0.6),
              height: 1,
            ),
          ),
          itemBuilder: (context, index) {
            final item = list[index];
            return _EntryItem(
              entry: item,
              onView: onView != null ? () => onView!(item) : null,
              onEdit: onEdit != null ? () => onEdit!(item) : null,
              onDelete: onDelete != null ? () => onDelete!(item) : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _isToday ? '✨' : '—',
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          _isToday
              ? 'No entries recorded today yet.'
              : 'No entries recorded for this day.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isToday) ...[
          const SizedBox(height: 4),
          Text(
            'Write an entry to record your thoughts.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EntryItem extends StatelessWidget {
  final ReflectionEntryModel entry;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EntryItem({
    required this.entry,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  String get _snippet {
    if (entry.freeformNote != null && entry.freeformNote!.trim().isNotEmpty) {
      return entry.freeformNote!.trim();
    }
    if (entry.answers.isNotEmpty) {
      return entry.answers.values.join(' ').trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = entry.createdAt;
    final snippet = _snippet;
    final hasTitle = entry.freeformTitle != null &&
        entry.freeformTitle!.trim().isNotEmpty;
    final hasPhoto = entry.photoUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time & Mood row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(timestamp),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Mood pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.calmTagBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${entry.mood} ${entry.moodEmoji}',
                style: AppTextStyles.tag.copyWith(
                  color: AppColors.calmTagText,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Title if present
        if (hasTitle) ...[
          Text(
            entry.freeformTitle!.trim(),
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Photo Attachment (if present)
        if (hasPhoto) ...[
          if (entry.photoUrls.length == 1)
            GestureDetector(
              onTap: () => PhotoViewerDialog.show(
                context,
                photos: entry.photoUrls,
                initialIndex: 0,
                caption: hasTitle ? entry.freeformTitle : snippet,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    entry.photoUrls.first.startsWith('http://') ||
                            entry.photoUrls.first.startsWith('https://')
                        ? Image.network(
                            entry.photoUrls.first,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          )
                        : Image.file(
                            File(entry.photoUrls.first),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Moment',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entry.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = entry.photoUrls[index];
                  return GestureDetector(
                    onTap: () => PhotoViewerDialog.show(
                      context,
                      photos: entry.photoUrls,
                      initialIndex: index,
                      caption: hasTitle ? entry.freeformTitle : snippet,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          url.startsWith('http://') || url.startsWith('https://')
                              ? Image.network(
                                  url,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                )
                              : Image.file(
                                  File(url),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${index + 1}/${entry.photoUrls.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],

        // Content snippet
        if (snippet.isNotEmpty) ...[
          Text(
            '"$snippet"',
            style: AppTextStyles.summaryQuote,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
        ],

        // Actions row
        Row(
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFE02424),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Move to Recycle Bin',
                onPressed: onDelete,
              ),
            if (onEdit != null) ...[
              const SizedBox(width: 14),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit entry',
                onPressed: onEdit,
              ),
            ],
            const Spacer(),
            if (onView != null)
              TextButton.icon(
                onPressed: onView,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.auto_stories_outlined,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: Text(
                  'View Summary →',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Holds data for a single day's reflection in calendar view.
class ReflectionEntry {
  final String id;
  final String mood;
  final String moodEmoji;
  final String summary;
  final int questionsAnswered;
  final int minutesSpent;
  final String? photoUrl;

  const ReflectionEntry({
    required this.id,
    required this.mood,
    required this.moodEmoji,
    required this.summary,
    required this.questionsAnswered,
    required this.minutesSpent,
    this.photoUrl,
  });
}
