import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_card.dart';
import '../widgets/yesterday_summary_card.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
import '../../freeform/pages/freeform_page.dart';
import '../../summary/pages/summary_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/settings_service.dart';

/// The main "Today" screen — the home page of Daily Reflection.
/// Dynamically connected to Firestore for past summary cards.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reflectionService = ReflectionService();
    final authService = AuthService();
    final settingsService = SettingsService();

    return ListenableBuilder(
      listenable: Listenable.merge([settingsService, reflectionService, authService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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

                  // ── Write Today's Journal CTA ─────────────────
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
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.14),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
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
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
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
                                      style: AppTextStyles.greeting.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Capture your thoughts anytime 24/7',
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
                          const SizedBox(height: 16),
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
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.create_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.writeButtonLabel,
                                  style: AppTextStyles.button.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
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
                              : 'A quiet moment captured.');

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
                            title: 'Recent Thought',
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
                                        'Journal Entry',
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
