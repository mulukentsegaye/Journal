import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../auth/services/auth_service.dart';
import '../../freeform/pages/freeform_page.dart';
import '../../journal/widgets/journal_card.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';
import '../../summary/pages/summary_page.dart';
import '../widgets/greeting_header.dart';

/// The main "Reflect" / Home screen of Daily Reflection.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});


  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  void _confirmDelete(BuildContext context, ReflectionService service, String id) {
    HapticFeedback.lightImpact();
    service.deleteReflection(id);
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
          onPressed: () => service.restoreReflection(id),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _editReflection(BuildContext context, ReflectionEntryModel model) {
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (_) => FreeformPage(
          id: model.id,
          date: model.date,
          initialTitle: model.freeformTitle,
          initialContent: model.freeformNote ??
              (model.answers.isNotEmpty ? model.answers.values.first : ''),
          initialMood: model.mood,
          initialPhotoUrls: model.photoUrls,
          initialTags: model.tags,
        ),
      ),
    );
  }

  void _viewSummary(BuildContext context, ReflectionEntryModel model) {
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (_) => SummaryPage(
          id: model.id,
          date: model.date,
          mood: model.mood,
          moodEmoji: model.moodEmoji,
          freeformTitle: model.freeformTitle ?? 'Journal Entry',
          freeformNote: model.freeformNote,
          answers: model.answers,
          photoUrls: model.photoUrls,
          tags: model.tags,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final reflectionService = ReflectionService();
    final authService = AuthService();
    final settingsService = SettingsService();

    return ListenableBuilder(
      listenable: Listenable.merge([settingsService, reflectionService, authService]),
      builder: (context, _) {
        final entries = reflectionService.entries;
        final now = DateTime.now();

        // Check if user has already reflected today
        final hasReflectedToday = entries.any((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day);

        // One recently saved entry (only one)
        final recentEntry = entries.isNotEmpty ? entries.first : null;

        // Entries with "saved" tag (and/or bookmarked)
        final savedTagEntries = entries.where((e) {
          final hasSavedTag = e.tags.any((t) {
            final clean = t.trim().toLowerCase().replaceAll('#', '');
            return clean == 'saved';
          });
          return hasSavedTag || e.isBookmarked;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting Header ──────────────────────────
                  const GreetingHeader(),
                  const SizedBox(height: 20),

                  // ── 1. CTA of write entry ("that tab card") ──
                  if (!hasReflectedToday)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (_) => const FreeformPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.edit_note_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.writeJournalPrompt,
                                        style: AppTextStyles.sectionTitle.copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Capture your thoughts for today',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppStrings.writeJournalSubtitle,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.create_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.writeButtonLabel,
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Quick banner if already reflected today
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (_) => const FreeformPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.edit_note_rounded,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Capture another thought',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Add to today\'s reflections',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_rounded,
                                  size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── 2. One Recently Saved Entry (Only One) ───
                  if (recentEntry != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT ENTRY',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.textHint,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AppShell.switchToTab(1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Journal',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    JournalCard(
                      key: ValueKey('recent_${recentEntry.id}'),
                      entry: recentEntry.toJournalEntry(),
                      onTap: () => _viewSummary(context, recentEntry),
                      onBookmarkToggle: () => reflectionService.toggleBookmark(
                        recentEntry.id,
                        recentEntry.isBookmarked,
                      ),
                      onDelete: () => _confirmDelete(
                          context, reflectionService, recentEntry.id),
                      onEdit: () => _editReflection(context, recentEntry),
                    ),
                    if (entries.length > 1) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => AppShell.switchToTab(1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history_edu_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entries.length - 1} earlier reflection${entries.length - 1 == 1 ? '' : 's'} in your Journal',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                'View all',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  // ── 3. Entries with "saved" tag ───────────────
                  if (entries.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SAVED ENTRIES',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.textHint,
                              ),
                            ),
                            if (savedTagEntries.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${savedTagEntries.length}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (savedTagEntries.isNotEmpty) ...[
                      for (final entry in savedTagEntries) ...[
                        JournalCard(
                          key: ValueKey('saved_${entry.id}'),
                          entry: entry.toJournalEntry(),
                          onTap: () => _viewSummary(context, entry),
                          onBookmarkToggle: () =>
                              reflectionService.toggleBookmark(
                            entry.id,
                            entry.isBookmarked,
                          ),
                          onDelete: () => _confirmDelete(
                              context, reflectionService, entry.id),
                          onEdit: () => _editReflection(context, entry),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ] else ...[
                      // Empty state when user hasn't tagged any entry as "saved"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bookmark_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No saved entries yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tag your important reflections with #saved or tap the bookmark icon on any card to keep them pinned here.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Empty state when no reflections exist in the app yet
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 32,
                            color: AppColors.textHint.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your reflections will appear here as you write them.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
