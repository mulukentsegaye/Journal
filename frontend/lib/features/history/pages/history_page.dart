import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/month_header.dart';
import '../widgets/day_detail_card.dart';
import '../widgets/streak_banner.dart';

/// The History page — calendar view showing past reflections.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  // Simulated data: days that have reflections
  final Map<DateTime, _ReflectionEntry> _reflectionData = {};

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDay = DateTime.now();
    _generateSampleData();
  }

  void _generateSampleData() {
    final now = DateTime.now();
    final moods = ['Calm', 'Grateful', 'Reflective', 'Peaceful', 'Energized'];
    final emojis = ['🌿', '🙏', '💭', '☁️', '⚡'];
    final summaries = [
      'Took a long walk and noticed the way light filtered through the trees. Small moments matter.',
      'Called an old friend today. Gratitude fills the spaces between words left unsaid.',
      'Journaled about a recurring dream. Sometimes the mind whispers what the heart already knows.',
      'Sat with silence for ten minutes. The world felt kinder after that pause.',
      'Finished a project I\'d been putting off. Momentum creates its own kind of joy.',
      'Watched the sunset from the balcony. Time moves differently when you\'re truly present.',
      'Cooked a meal from scratch. There\'s meditation in the rhythm of chopping and stirring.',
      'Read a chapter that shifted my perspective. Growth hides in unexpected pages.',
      'Let go of a small frustration that I\'d been carrying all week. Lighter now.',
      'Had a meaningful conversation about what it means to be content with enough.',
    ];

    // Populate the last 12 days with sample reflections (skip a couple for realism)
    for (int i = 1; i <= 14; i++) {
      if (i == 5 || i == 11) continue; // skip some days for realism
      final day = DateTime(now.year, now.month, now.day - i);
      final idx = i % moods.length;
      final sumIdx = i % summaries.length;
      _reflectionData[DateTime(day.year, day.month, day.day)] = _ReflectionEntry(
        mood: moods[idx],
        moodEmoji: emojis[idx],
        summary: summaries[sumIdx],
        questionsAnswered: 5 + (i % 3),
        minutesSpent: 4 + (i % 5),
      );
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
  }

  _ReflectionEntry? get _selectedEntry {
    if (_selectedDay == null) return null;
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    return _reflectionData[key];
  }

  int get _completedDaysThisMonth {
    return _reflectionData.keys
        .where((d) => d.year == _focusedMonth.year && d.month == _focusedMonth.month)
        .length;
  }

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
              // ── Page title ────────────────────────────────
              Text('Your Journey', style: AppTextStyles.greeting),
              const SizedBox(height: 4),
              Text(
                'Look back on the moments you\'ve captured.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),

              // ── Streak banner ─────────────────────────────
              StreakBanner(
                completedDays: _completedDaysThisMonth,
                totalDays: DateUtils.getDaysInMonth(
                  _focusedMonth.year,
                  _focusedMonth.month,
                ),
              ),
              const SizedBox(height: 24),

              // ── Calendar card ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    MonthHeader(
                      focusedMonth: _focusedMonth,
                      onPrevious: _goToPreviousMonth,
                      onNext: _goToNextMonth,
                    ),
                    const SizedBox(height: 16),
                    CalendarGrid(
                      focusedMonth: _focusedMonth,
                      selectedDay: _selectedDay,
                      reflectionDays: _reflectionData.keys.toSet(),
                      onDaySelected: _onDaySelected,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Selected day detail ───────────────────────
              if (_selectedDay != null)
                DayDetailCard(
                  day: _selectedDay!,
                  entry: _selectedEntry,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Holds simulated data for a single day's reflection.
class ReflectionEntry {
  final String mood;
  final String moodEmoji;
  final String summary;
  final int questionsAnswered;
  final int minutesSpent;

  const ReflectionEntry({
    required this.mood,
    required this.moodEmoji,
    required this.summary,
    required this.questionsAnswered,
    required this.minutesSpent,
  });
}

// Private alias used internally by this page's sample data generator.
typedef _ReflectionEntry = ReflectionEntry;
