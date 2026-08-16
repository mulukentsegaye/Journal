import 'package:flutter/material.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_card.dart';
import '../widgets/reflection_prompt_card.dart';
import '../widgets/yesterday_summary_card.dart';
import '../../../core/theme/app_colors.dart';

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
                  // TODO: Navigate to Evening Reflection flow
                },
              ),
              const SizedBox(height: 24),

              // ── Yesterday's Summary ───────────────────────
              const YesterdaySummaryCard(
                summary:
                    'Felt a gentle transition today. Let go of a '
                    'work stress and walked around the gardens.',
                date: 'Oct 19',
                mood: 'Calm',
                moodEmoji: '🌿',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
