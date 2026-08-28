import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_card.dart';
import '../widgets/reflection_prompt_card.dart';
import '../widgets/yesterday_summary_card.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../freeform/pages/freeform_page.dart';
import '../../reflection/pages/reflection_page.dart';
import '../../summary/pages/summary_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';
import '../../../core/services/settings_service.dart';

/// The main "Today" screen — the home page of Daily Reflection.
/// Dynamically connected to Firestore for past summary cards.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reflectionService = ReflectionService();

    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────
                  const GreetingHeader(),
                  const SizedBox(height: 28),

                  // ── Inspirational quote ───────────────────────
                  QuoteCard(
                    quote: AppStrings.quoteOfTheDay['quote']!,
                    author: AppStrings.quoteOfTheDay['author']!,
                  ),
                  const SizedBox(height: 28),

                  // ── Today's Reflection CTA ────────────────────
                  ReflectionPromptCard(
                    onStart: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          builder: (_) => const ReflectionPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Freeform Space Card ─────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          builder: (_) => const FreeformPage(isStandalone: true),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_note_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Freeform Space',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Have thoughts on your mind? Write freely anytime.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Past Summary (From ReflectionService) ─────
                  FutureBuilder<ReflectionEntryModel?>(
                    future: reflectionService.getYesterdayOrLatestReflection(),
                    builder: (context, snapshot) {
                      final entry = snapshot.data;
                      if (entry == null) {
                        return const SizedBox.shrink();
                      }

                      final summaryText = entry.freeformNote?.isNotEmpty == true
                          ? entry.freeformNote!
                          : (entry.answers.isNotEmpty == true
                              ? entry.answers.values.first
                              : 'Daily reflection captured.');

                      final dateText = DateFormat('MMM d').format(entry.date);
                      final mood = entry.mood;
                      final moodEmoji = entry.moodEmoji;

                      return Column(
                        children: [
                          YesterdaySummaryCard(
                            summary: summaryText,
                            date: dateText,
                            mood: mood,
                            moodEmoji: moodEmoji,
                            photoUrl: entry.photoUrl,
                            onTap: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  builder: (_) => SummaryPage(
                                    id: entry.id,
                                    date: entry.date,
                                    mood: mood,
                                    moodEmoji: moodEmoji,
                                    freeformTitle: entry.freeformTitle ??
                                        'Daily Reflection',
                                    freeformNote: entry.freeformNote,
                                    answers: entry.answers,
                                    photoUrl: entry.photoUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
