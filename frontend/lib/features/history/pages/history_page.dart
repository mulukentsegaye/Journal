import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/month_header.dart';
import '../widgets/day_detail_card.dart';
import '../widgets/streak_banner.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/firestore_service.dart';

/// The Journey page — calendar view showing past reflections.
/// Dynamically connected to live Cloud Firestore entries.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDay = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<ReflectionEntryModel>>(
          stream: _firestoreService.streamReflections(),
          builder: (context, snapshot) {
            final models = snapshot.data ?? [];
            final Map<DateTime, ReflectionEntry> reflectionData = {};

            for (final m in models) {
              final dateKey = DateTime(m.date.year, m.date.month, m.date.day);
              reflectionData[dateKey] = m.toHistoryEntry();
            }

            final completedDaysThisMonth = reflectionData.keys
                .where((d) =>
                    d.year == _focusedMonth.year &&
                    d.month == _focusedMonth.month)
                .length;

            final selectedKey = _selectedDay != null
                ? DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day)
                : null;
            final selectedEntry =
                selectedKey != null ? reflectionData[selectedKey] : null;

            return SingleChildScrollView(
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
                    completedDays: completedDaysThisMonth,
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
                          reflectionDays: reflectionData.keys.toSet(),
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
                      entry: selectedEntry,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Holds data for a single day's reflection.
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
