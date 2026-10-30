import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
import '../widgets/yesterday_summary_card.dart';

/// The main "Today" screen — the home page of Journal.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

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
    final reflectionService = ReflectionService();
    final authService = AuthService();
    final settingsService = SettingsService();

    return ListenableBuilder(
      listenable: Listenable.merge([settingsService, reflectionService, authService]),
      builder: (context, _) {
        final entries = reflectionService.entries;
        final now = DateTime.now();

        // Saved entries for today
        final todayEntries = entries.where((e) {
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        }).toList();

        // Saved entries from earlier days
        final pastEntries = entries.where((e) {
          return !(e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day);
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

                  // ── Today's Saved Entries (or Write CTA if empty) ──
                  if (todayEntries.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Today's Entries",
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${todayEntries.length}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                builder: (_) => const FreeformPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('New Entry'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of today's saved journal cards
                    for (final entry in todayEntries) ...[
                      JournalCard(
                        key: ValueKey(entry.id),
                        entry: entry.toJournalEntry(),
                        onTap: () => _viewSummary(context, entry),
                        onBookmarkToggle: () => reflectionService.toggleBookmark(
                          entry.id,
                          entry.isBookmarked,
                        ),
                        onDelete: () =>
                            _confirmDelete(context, reflectionService, entry.id),
                        onEdit: () => _editReflection(context, entry),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Quick button to add another thought for today
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
                            vertical: 13, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Write another thought for today',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Empty state: Write Today's Journal CTA card
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
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Past Summary / Reflections Section ───────
                  if (pastEntries.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Past Reflections',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Builder(
                      builder: (context) {
                        final latestPast = pastEntries.first;
                        final summaryText = latestPast.freeformNote?.trim().isNotEmpty == true
                            ? latestPast.freeformNote!.trim()
                            : (latestPast.answers.isNotEmpty == true
                                ? latestPast.answers.values.first
                                : (latestPast.photoUrls.isNotEmpty
                                    ? 'Photo entry'
                                    : 'Journal entry'));

                        final dateText =
                            DateFormat('MMM d').format(latestPast.date);
                        final yesterday = now.subtract(const Duration(days: 1));
                        final isYesterday = latestPast.date.year == yesterday.year &&
                            latestPast.date.month == yesterday.month &&
                            latestPast.date.day == yesterday.day;

                        return YesterdaySummaryCard(
                          summary: summaryText,
                          date: dateText,
                          mood: latestPast.mood,
                          moodEmoji: latestPast.moodEmoji,
                          photoUrl: latestPast.photoUrl,
                          title: latestPast.freeformTitle?.trim().isNotEmpty == true
                              ? latestPast.freeformTitle!.trim()
                              : (isYesterday
                                  ? "Yesterday's Reflection"
                                  : 'Recent Entry'),
                          onTap: () => _viewSummary(context, latestPast),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
