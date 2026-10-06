import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/photo_save_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../models/journal_entry.dart';

/// Card component representing a single journal entry item.
class JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const JournalCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onBookmarkToggle,
    this.onEdit,
    this.onDelete,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }



  Widget _buildPhotoThumbnail(BuildContext context) {
    if (entry.photoUrl == null || entry.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isNetwork = entry.photoUrl!.startsWith('http://') || entry.photoUrl!.startsWith('https://');
    final imageProvider = isNetwork
        ? NetworkImage(entry.photoUrl!) as ImageProvider
        : FileImage(File(entry.photoUrl!));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: GestureDetector(
        onTap: () => PhotoViewerDialog.show(
          context,
          photoUrl: entry.photoUrl!,
          caption: entry.title,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Image(
                image: imageProvider,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Moment Photo Attached', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhotoToDevice(BuildContext context, String photoUrl, String title) async {
    HapticFeedback.lightImpact();
    try {
      final savedPath = await PhotoSaveService().savePhotoToDevice(
        photoUrl: photoUrl,
        customPrefix: title,
      );
      final filename = savedPath.split(Platform.pathSeparator).last;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo saved to device!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        filename,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(ErrorFormatter.format(e))),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Date & Mood Pill & Bookmark & Options ──────────
            Row(
              children: [
                // Date tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' • ${_formatTime(entry.date)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Mood pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.moodBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.moodEmoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        entry.mood,
                        style: AppTextStyles.tag.copyWith(
                          color: entry.moodTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo indicator badge
                if (entry.photoUrl != null && entry.photoUrl!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Photo',
                          style: AppTextStyles.tag.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Bookmark icon button
                GestureDetector(
                  onTap: onBookmarkToggle,
                  child: Icon(
                    entry.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 20,
                    color: entry.isBookmarked
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),

                // More Options Menu
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppColors.cardBackground,
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      } else if (value == 'save_photo' && entry.photoUrl != null) {
                        _savePhotoToDevice(context, entry.photoUrl!, entry.title);
                      }
                    },
                    itemBuilder: (context) => [
                      if (entry.photoUrl != null && entry.photoUrl!.isNotEmpty)
                        PopupMenuItem(
                          value: 'save_photo',
                          child: Row(
                            children: [
                              Icon(Icons.file_download_outlined,
                                  size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 10),
                              Text(
                                Platform.isWindows ? 'Save Photo to PC' : 'Save Photo',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 10),
                              const Text('Edit', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFE02424)),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFE02424),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ── Photo Thumbnail (if attached) ─────────────────
            _buildPhotoThumbnail(context),



            // ── Snippet ───────────────────────────────────────
            Text(
              entry.contentSnippet,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // ── Tag Chips (if present) ─────────────────────────
            if (entry.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.tags.map((tag) {
                  final display = tag.startsWith('#') ? tag : '#$tag';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      display,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 2),

            // ── Footer: Type / Questions answered + Arrow ────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Read entry →',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
