import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_card.dart';
import '../widgets/reflection_prompt_card.dart';
import '../widgets/yesterday_summary_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../reflection/pages/reflection_page.dart';
import '../../summary/pages/summary_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/firestore_service.dart';

/// The main "Today" screen — the home page of Daily Reflection.
/// Dynamically connected to Firestore for past summary cards.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

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
              const QuoteCard(
                quote: 'Quiet the mind and the soul will speak.',
                author: 'Ma Jaya Sati Bhagavati',
              ),
              const SizedBox(height: 28),

              // ── Today's Reflection CTA ────────────────────
              ReflectionPromptCard(
                onStart: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReflectionPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Past Summary (From Firestore) ─────────────
              FutureBuilder<ReflectionEntryModel?>(
                future: firestoreService.getYesterdayOrLatestReflection(),
                builder: (context, snapshot) {
                  final entry = snapshot.data;
                  final summaryText = entry?.freeformNote?.isNotEmpty == true
                      ? entry!.freeformNote!
                      : (entry?.answers.isNotEmpty == true
                          ? entry!.answers.values.first
                          : 'Felt a gentle transition today. Let go of work stress and walked around the gardens.');

                  final dateText = entry != null
                      ? DateFormat('MMM d').format(entry.date)
                      : 'Oct 19';
                  final mood = entry?.mood ?? 'Calm';
                  final moodEmoji = entry?.moodEmoji ?? '🌿';

                  return YesterdaySummaryCard(
                    summary: summaryText,
                    date: dateText,
                    mood: mood,
                    moodEmoji: moodEmoji,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SummaryPage(
                            mood: mood,
                            moodEmoji: moodEmoji,
                            freeformTitle: entry?.freeformTitle ??
                                'Gentle transition today',
                            freeformNote: summaryText,
                            answers: entry?.answers,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
