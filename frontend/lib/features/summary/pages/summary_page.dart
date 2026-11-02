import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/photo_save_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/database_service.dart';
import '../../reflection/services/reflection_service.dart';
import '../../freeform/pages/freeform_page.dart';
import '../widgets/freeform_summary_card.dart';

/// Entry Detail screen — displays saved entry details,
/// thoughts, mood tag, moment photos, and share options.
class SummaryPage extends StatefulWidget {
  final String? id;
  final DateTime? date;
  final String mood;
  final String moodEmoji;
  final String? freeformTitle;
  final String? freeformNote;
  final List<String> photoUrls;
  final Map<int, String>? answers;
  final List<String> tags;

  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  SummaryPage({
    super.key,
    this.id,
    this.date,
    this.mood = 'Calm',
    this.moodEmoji = '🌿',
    this.freeformTitle,
    this.freeformNote,
    String? photoUrl,
    List<String>? photoUrls,
    this.answers,
    this.tags = const [],
  }) : photoUrls = photoUrls ?? (photoUrl != null && photoUrl.isNotEmpty ? [photoUrl] : const []);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isExpanded = false;
  late final String _docId;
  bool _isBookmarked = false;
  int _activePhotoIndex = 0;
  final ReflectionService _reflectionService = ReflectionService();

  static const Map<int, String> _questionPrompts = AppStrings.questionPrompts;

  @override
  void initState() {
    super.initState();
    _docId = widget.id ?? DatabaseService.generateUniqueId();
    _initEntryState();
  }

  void _initEntryState() {
    final active = _reflectionService.entries;
    final existing = active.where((e) => e.id == _docId).firstOrNull;
    if (existing != null) {
      _isBookmarked = existing.isBookmarked;
    } else if (widget.id == null) {
      // Only save if it's a completely unsaved brand-new entry
      _saveNewEntry();
    }
  }

  void _saveNewEntry() {
    final entryDate = widget.date ?? DateTime.now();
    final entry = ReflectionEntryModel(
      id: _docId,
      date: entryDate,
      mood: widget.mood,
      moodEmoji: widget.moodEmoji,
      answers: widget.answers ?? {},
      freeformTitle: widget.freeformTitle?.trim().isNotEmpty == true
          ? widget.freeformTitle!.trim()
          : null,
      freeformNote: widget.freeformNote?.trim().isNotEmpty == true
          ? widget.freeformNote!.trim()
          : null,
      photoUrls: widget.photoUrls,
      tags: widget.tags,
      createdAt: entryDate,
    );

    _reflectionService.saveReflection(entry);
  }

  void _toggleBookmark() {
    HapticFeedback.selectionClick();
    final oldVal = _isBookmarked;
    setState(() => _isBookmarked = !oldVal);
    _reflectionService.toggleBookmark(_docId, oldVal);
  }

  void _showCardPreviewDialog(
      BuildContext context, String dateStr, String snippet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        'Journal',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quote Card Body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      '"$snippet"',
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final cardText =
                            '🌿 Journal ($dateStr)\n\n"$snippet"';
                        await Clipboard.setData(ClipboardData(text: cardText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.snackBarBackground,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: const Text(
                                'Card copied.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareReflection() {
    final effectiveDate = widget.date ?? DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(effectiveDate);
    final buffer = StringBuffer();
    buffer.writeln('Journal — $dateStr');

    String snippet = widget.freeformNote?.trim() ?? '';
    if (widget.answers != null && widget.answers!.isNotEmpty) {
      final sortedKeys = widget.answers!.keys.toList()..sort();
      for (final key in sortedKeys) {
        final answer = widget.answers![key]?.trim();
        if (answer != null && answer.isNotEmpty) {
          final prompt = _questionPrompts[key] ?? 'Question $key';
          buffer.writeln('$key. $prompt');
          buffer.writeln('"$answer"\n');
          if (snippet.isEmpty) {
            snippet = answer;
          }
        }
      }
    }

    if (widget.freeformTitle != null &&
        widget.freeformTitle!.trim().isNotEmpty) {
      buffer.writeln(widget.freeformTitle!.trim());
    }
    if (widget.freeformNote != null &&
        widget.freeformNote!.trim().isNotEmpty) {
      buffer.writeln(widget.freeformNote!.trim());
    }

    if (snippet.isEmpty) {
      snippet = widget.photoUrls.isNotEmpty
          ? 'Photo entry'
          : 'Journal entry';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Share Entry',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export or copy your entry as text.',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Text',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Clipboard.setData(
                      ClipboardData(text: buffer.toString().trim()),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.snackBarBackground,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: const Text(
                            'Entry copied.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _ShareOption(
                  icon: Icons.image_outlined,
                  label: 'Export Card',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCardPreviewDialog(context, dateStr, snippet);
                  },
                ),
                _ShareOption(
                  icon: Icons.lock_outline_rounded,
                  label: 'Keep Private',
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _finishAndReturnHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Move to Recycle Bin?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This entry will be kept in your Recycle Bin. You can restore it anytime.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedId = _docId;
              await _reflectionService.deleteReflection(deletedId);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.snackBarBackground,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: const Text(
                      'Moved to Recycle Bin.',
                      style: TextStyle(color: Colors.white),
                    ),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primaryLight,
                      onPressed: () =>
                          _reflectionService.restoreReflection(deletedId),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Move to Bin',
              style: TextStyle(
                color: Color(0xFFE02424),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editReflection() {
    Navigator.pushReplacement(
      context,
      SmoothPageRoute(
        builder: (_) => FreeformPage(
          id: _docId,
          date: widget.date,
          initialTitle: widget.freeformTitle,
          initialContent: widget.freeformNote ??
              (widget.answers != null && widget.answers!.isNotEmpty
                  ? widget.answers!.values.first
                  : ''),
          initialMood: widget.mood,
          initialPhotoUrls: widget.photoUrls,
          initialTags: widget.tags,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_SummaryItem> userResponses = [];
    if (widget.answers != null && widget.answers!.isNotEmpty) {
      final sortedKeys = widget.answers!.keys.toList()..sort();
      for (final key in sortedKeys) {
        final answer = widget.answers![key]?.trim();
        if (answer != null && answer.isNotEmpty) {
          final question = _questionPrompts[key] ?? 'Question $key';
          userResponses.add(
            _SummaryItem(
              number: key,
              question: question,
              answer: answer,
            ),
          );
        }
      }
    }

    final visibleResponses =
        _isExpanded ? userResponses : userResponses.take(4).toList();
    final remainingCount = userResponses.length - 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _finishAndReturnHome,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMMM d, yyyy').format(widget.date ?? DateTime.now()),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      // Bookmark toggle button
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            size: 20,
                            color: _isBookmarked
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _shareReflection,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.ios_share_rounded,
                            size: 19,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: AppColors.cardBackground,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editReflection();
                          } else if (value == 'delete') {
                            _confirmDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.textPrimary),
                                const SizedBox(width: 10),
                                const Text('Edit Entry',
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Color(0xFFE02424)),
                                SizedBox(width: 10),
                                Text(
                                  'Delete Entry',
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
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Entry Metadata: Time ─────────────────────────
                    if (widget.date != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              DateFormat('h:mm a').format(widget.date!),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Attached Moment Photo(s) ──────────────────
                    if (widget.photoUrls.isNotEmpty) ...[
                      _buildPhotoSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Section Title & Answer items (if user answered questions)
                    // Primary Journal Note Card
                    if ((widget.freeformNote != null &&
                            widget.freeformNote!.trim().isNotEmpty) ||
                        (widget.freeformTitle != null &&
                            widget.freeformTitle!.trim().isNotEmpty)) ...[
                      FreeformSummaryCard(
                        title: widget.freeformTitle,
                        note: widget.freeformNote?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Tags Section (if present) ────────────────────────
                    if (widget.tags.any((t) => t.replaceAll('#', '').trim().toLowerCase() == 'saved')) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.label_outline_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: widget.tags
                                    .where((t) => t.replaceAll('#', '').trim().toLowerCase() == 'saved')
                                    .map((tag) {
                                  final display =
                                      tag.startsWith('#') ? tag : '#$tag';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      display,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section for historical guided responses (if any exist from earlier entries)
                    if (userResponses.isNotEmpty) ...[
                      Text(
                        'SAVED RESPONSES',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 14),

                      ...visibleResponses.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.divider.withValues(alpha: 0.7),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.number}. ${item.question}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '"${item.answer}"',
                                  style: GoogleFonts.lora(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Expand / Collapse "+ X more responses"
                      if (!_isExpanded && remainingCount > 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _isExpanded = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+ $remainingCount more responses',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                    ],


                  ],
                ),
              ),
            ),

            // ── Bottom Return Home Button ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finishAndReturnHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Back to Journal',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    if (widget.photoUrls.isEmpty) return const SizedBox.shrink();

    if (widget.photoUrls.length == 1) {
      final photo = widget.photoUrls.first;
      return GestureDetector(
        onTap: () => PhotoViewerDialog.show(
          context,
          photos: widget.photoUrls,
          initialIndex: 0,
          caption: widget.freeformTitle ?? 'Moment Photo',
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              _buildPhotoWidget(photo),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => _savePhoto(context, photo),
                  child: _buildSaveButton(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Multiple photos PageView
    final safeIndex = _activePhotoIndex.clamp(0, widget.photoUrls.length - 1);
    final currentPhoto = widget.photoUrls[safeIndex];

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          PageView.builder(
            itemCount: widget.photoUrls.length,
            onPageChanged: (idx) {
              setState(() {
                _activePhotoIndex = idx;
              });
            },
            itemBuilder: (context, idx) {
              final photo = widget.photoUrls[idx];
              return GestureDetector(
                onTap: () => PhotoViewerDialog.show(
                  context,
                  photos: widget.photoUrls,
                  initialIndex: idx,
                  caption: widget.freeformTitle ?? 'Moment Photo',
                ),
                child: _buildPhotoWidget(photo),
              );
            },
          ),
          // Photo Counter on Top Left
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    '${safeIndex + 1} / ${widget.photoUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Save Photo Button on Top Right
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _savePhoto(context, currentPhoto),
              child: _buildSaveButton(),
            ),
          ),
          // Dot Indicators at bottom
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photoUrls.length,
                (idx) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: safeIndex == idx ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: safeIndex == idx
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String photo) {
    return photo.startsWith('http://') || photo.startsWith('https://')
        ? Image.network(
            photo,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _buildPhotoFallback(),
          )
        : Image.file(
            File(photo),
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _buildPhotoFallback(),
          );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_download_outlined, size: 15, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            Platform.isWindows ? 'Save to PC' : 'Save',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhoto(BuildContext context, [String? targetUrl]) async {
    final photo = targetUrl ??
        (_activePhotoIndex < widget.photoUrls.length
            ? widget.photoUrls[_activePhotoIndex]
            : widget.photoUrl);
    if (photo == null || photo.isEmpty) return;
    HapticFeedback.lightImpact();

    try {
      final savedPath = await PhotoSaveService().savePhotoToDevice(
        photoUrl: photo,
        customPrefix: widget.freeformTitle ?? 'DailyReflection',
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
                        'Photo saved.',
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

  Widget _buildPhotoFallback() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'Moment Photo Attached',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Original photo captured on your mobile device',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final int number;
  final String question;
  final String answer;

  const _SummaryItem({
    required this.number,
    required this.question,
    required this.answer,
  });
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
