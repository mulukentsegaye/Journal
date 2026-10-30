import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';

/// Screen displaying soft-deleted reflections that can be restored or permanently removed.
class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  void _confirmEmptyTrash(BuildContext context, ReflectionService service) {
    final isDark = SettingsService().isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE02424), size: 22),
            const SizedBox(width: 8),
            Text(
              'Empty Recycle Bin?',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'All ${service.deletedCount} items in the Recycle Bin will be permanently wiped from your device and cloud storage.',
          style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.emptyTrash();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Recycle Bin emptied.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF2C5E43),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE02424),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Empty All'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, ReflectionService service, String docId) {
    final isDark = SettingsService().isDarkMode;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Permanently?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        content: Text(
          'This entry will be permanently erased. You will not be able to recover it.',
          style: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.permanentlyDeleteReflection(docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Entry permanently deleted.',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFFE02424),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE02424),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _restoreItem(BuildContext context, ReflectionService service, String docId) async {
    HapticFeedback.lightImpact();
    await service.restoreReflection(docId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.restore_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Entry restored.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2C5E43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ReflectionService();
    final isDark = SettingsService().isDarkMode;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final trashedItems = service.deletedEntries;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recycle Bin',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${trashedItems.length} ${trashedItems.length == 1 ? 'item' : 'items'} resting safely',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              if (trashedItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () => _confirmEmptyTrash(context, service),
                    icon: const Icon(Icons.delete_sweep_outlined,
                        size: 18, color: Color(0xFFE02424)),
                    label: const Text(
                      'Empty',
                      style: TextStyle(
                        color: Color(0xFFE02424),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: trashedItems.isEmpty
              ? _buildEmptyState(textPrimary, textSecondary, primary)
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: trashedItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = trashedItems[index];
                    return _TrashedReflectionCard(
                      entry: item,
                      isDark: isDark,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      divider: divider,
                      primary: primary,
                      onRestore: () => _restoreItem(context, service, item.id),
                      onDeletePermanent: () =>
                          _confirmPermanentDelete(context, service, item.id),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recycle Bin is Empty',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any reflections you remove will be kept here safely before permanent deletion.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashedReflectionCard extends StatelessWidget {
  final ReflectionEntryModel entry;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color primary;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanent;

  const _TrashedReflectionCard({
    required this.entry,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.primary,
    required this.onRestore,
    required this.onDeletePermanent,
  });

  @override
  Widget build(BuildContext context) {
    final entryDateStr = DateFormat('MMMM d, yyyy').format(entry.date);
    final deletedDateStr = entry.deletedAt != null
        ? DateFormat('MMM d, h:mm a').format(entry.deletedAt!)
        : 'Recently';

    String snippet = entry.freeformNote ?? '';
    if (snippet.isEmpty && entry.answers.isNotEmpty) {
      snippet = entry.answers.values.first;
    }
    if (snippet.isEmpty) {
      snippet = 'Mindful reflection entry';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mood Tag, Original Date & Deleted Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.moodEmoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          entry.mood,
                          style: GoogleFonts.inter(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entryDateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 13, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    deletedDateStr,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Note Snippet
          if (entry.freeformTitle?.isNotEmpty == true) ...[
            Text(
              entry.freeformTitle!,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            snippet,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Attached photo preview if present
          if (entry.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (entry.photoUrls.length == 1)
              GestureDetector(
                onTap: () => PhotoViewerDialog.show(
                  context,
                  photos: entry.photoUrls,
                  initialIndex: 0,
                  caption: entry.freeformTitle ?? entry.mood,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: entry.photoUrls.first.startsWith('http://') ||
                          entry.photoUrls.first.startsWith('https://')
                      ? Image.network(
                          entry.photoUrls.first,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        )
                      : Image.file(
                          File(entry.photoUrls.first),
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                ),
              )
            else
              SizedBox(
                height: 60,
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
                        caption: entry.freeformTitle ?? entry.mood,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url.startsWith('http://') ||
                                url.startsWith('https://')
                            ? Image.network(
                                url,
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              )
                            : Image.file(
                                File(url),
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, color: divider),
          const SizedBox(height: 10),

          // Action Buttons: Restore & Delete Permanently
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDeletePermanent,
                icon: const Icon(Icons.delete_forever_rounded,
                    size: 16, color: Color(0xFFE02424)),
                label: const Text(
                  'Delete Forever',
                  style: TextStyle(
                    color: Color(0xFFE02424),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Restore',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
