import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/photo_save_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';
import '../../freeform/pages/freeform_page.dart';
import '../widgets/summary_header_card.dart';
import '../widgets/response_item_card.dart';
import '../widgets/freeform_summary_card.dart';

/// Summary Page / Reflection Complete screen — displays all saved
/// answers, freeform note, mood tag, moment photo, and share options.
class SummaryPage extends StatefulWidget {
  final String? id;
  final DateTime? date;
  final String mood;
  final String moodEmoji;
  final String? freeformTitle;
  final String? freeformNote;
  final String? photoUrl;
  final Map<int, String>? answers;

  const SummaryPage({
    super.key,
    this.id,
    this.date,
    this.mood = 'Calm',
    this.moodEmoji = '🌿',
    this.freeformTitle,
    this.freeformNote,
    this.photoUrl,
    this.answers,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isExpanded = false;
  late final String _docId;

  static const Map<int, String> _questionPrompts = AppStrings.questionPrompts;

  @override
  void initState() {
    super.initState();
    _docId = widget.id ?? '${DateTime.now().millisecondsSinceEpoch}';
    _saveToFirestore();
  }

  void _saveToFirestore() {
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
      photoUrl: widget.photoUrl,
      createdAt: entryDate,
    );

    ReflectionService().saveReflection(entry);
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
                        'Daily Reflection',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.calmTagBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.moodEmoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            widget.mood,
                            style: AppTextStyles.tag.copyWith(
                              color: AppColors.calmTagText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            '🌿 Daily Reflection ($dateStr)\nMood: ${widget.mood} ${widget.moodEmoji}\n\n"$snippet"';
                        await Clipboard.setData(ClipboardData(text: cardText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.textPrimary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: const Text('Reflection card copied!'),
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
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final buffer = StringBuffer();
    buffer.writeln('Daily Reflection — $dateStr');
    buffer.writeln('Mood: ${widget.mood} ${widget.moodEmoji}\n');

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
      snippet = 'Captured a quiet moment of evening peace.';
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
              'Share Your Reflection',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export your peaceful anchor or copy as text.',
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
                          backgroundColor: AppColors.textPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content:
                              const Text('Reflection copied to clipboard!'),
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
          'Delete reflection?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This reflection will be permanently removed.',
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
              await ReflectionService().deleteReflection(_docId);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.textPrimary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: const Text('Reflection deleted.'),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
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
      MaterialPageRoute(
        builder: (_) => FreeformPage(
          id: _docId,
          date: widget.date,
          initialTitle: widget.freeformTitle,
          initialContent: widget.freeformNote ??
              (widget.answers != null && widget.answers!.isNotEmpty
                  ? widget.answers!.values.first
                  : ''),
          initialMood: widget.mood,
          initialPhotoUrl: widget.photoUrl,
          reflectionAnswers: widget.answers,
          isStandalone: true,
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
                    DateFormat('MMMM d, yyyy').format(DateTime.now()),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
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
                                const Text('Edit Reflection',
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
                                  'Delete Reflection',
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
                    // Header card with mood badge
                    SummaryHeaderCard(
                      mood: widget.mood,
                      moodEmoji: widget.moodEmoji,
                    ),
                    const SizedBox(height: 20),

                    // ── Attached Daily Moment Photo ──────────────────
                    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => PhotoViewerDialog.show(
                          context,
                          photoUrl: widget.photoUrl!,
                          caption: widget.freeformTitle ?? 'Daily Moment Photo',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Top Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.photo_camera_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Captured Moment Photo',
                                            style: GoogleFonts.lora(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.5,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Tap anywhere on the photo to expand & zoom',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Save Button
                                    GestureDetector(
                                      onTap: () => _savePhoto(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.file_download_outlined, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              Platform.isWindows ? 'Save to PC' : 'Save',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),

                              // Image Container
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  widget.photoUrl!.startsWith('http://') ||
                                          widget.photoUrl!.startsWith('https://')
                                      ? Image.network(
                                          widget.photoUrl!,
                                          height: 240,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => _buildPhotoFallback(),
                                        )
                                      : Image.file(
                                          File(widget.photoUrl!),
                                          height: 240,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => _buildPhotoFallback(),
                                        ),
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.zoom_in_rounded,
                                            color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Pinch to Zoom',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section Title & Answer items (if user answered questions)
                    if (userResponses.isNotEmpty) ...[
                      Text(
                        'RESPONSE SUMMARY',
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
                          child: ResponseItemCard(
                            index: item.number,
                            question: item.question,
                            answer: item.answer,
                          ),
                        );
                      }),

                      // Expand / Collapse "+ X more reflective responses"
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
                                      '+ $remainingCount more reflective responses',
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

                    // Additional Freeform Note Card
                    if (widget.freeformNote != null &&
                        widget.freeformNote!.trim().isNotEmpty)
                      FreeformSummaryCard(
                        title: widget.freeformTitle,
                        note: widget.freeformNote!.trim(),
                      ),

                    // Empty state if neither guided responses nor freeform note
                    if (userResponses.isEmpty &&
                        (widget.freeformNote == null ||
                            widget.freeformNote!.trim().isEmpty))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 10),
                            Text(
                              'Quiet Check-in Recorded',
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your mood and peaceful presence have been captured for tonight.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
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
                    'Done for Tonight  ✓',
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

  Future<void> _savePhoto(BuildContext context) async {
    if (widget.photoUrl == null || widget.photoUrl!.isEmpty) return;
    HapticFeedback.lightImpact();

    try {
      final savedPath = await PhotoSaveService().savePhotoToDevice(
        photoUrl: widget.photoUrl!,
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
                Expanded(child: Text('Could not save photo: $e')),
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
