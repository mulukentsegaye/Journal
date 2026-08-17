import 'package:flutter/material.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_card.dart';
import '../widgets/reflection_prompt_card.dart';
import '../widgets/yesterday_summary_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../reflection/pages/reflection_page.dart';
import '../../summary/pages/summary_page.dart';

/// The main "Today" screen — the home page of Daily Reflection.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                quote:
                    'Quiet the mind and the soul will speak.',
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

              // ── Yesterday's Summary ───────────────────────
              YesterdaySummaryCard(
                summary:
                    'Felt a gentle transition today. Let go of a '
                    'work stress and walked around the gardens.',
                date: 'Oct 19',
                mood: 'Calm',
                moodEmoji: '🌿',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SummaryPage(
                        mood: 'Calm',
                        moodEmoji: '🌿',
                        freeformTitle: 'Gentle transition today',
                        freeformNote:
                            'Felt a gentle transition today. Let go of work stress and walked around the gardens.',
                      ),
                    ),
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
