import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/streak_calculator.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_card.dart';
import '../widgets/journal_filter_chips.dart';
import '../../../core/services/settings_service.dart';
import '../../history/pages/history_page.dart';
import '../../history/widgets/calendar_grid.dart';
import '../../history/widgets/month_header.dart';
import '../../history/widgets/day_detail_card.dart';
import '../../history/widgets/streak_banner.dart';
import '../../summary/pages/summary_page.dart';
import '../../freeform/pages/freeform_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';
import '../../settings/widgets/pdf_export_dialog.dart';

enum JournalViewMode {
  timeline,
  calendar,
}

/// Unified Journal Screen — featuring seamless switching between Timeline Feed & Calendar Grid,
/// live search, mood filters, PDF keepsake export, and 1-tap Freeform writing.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  JournalViewMode _viewMode = JournalViewMode.timeline;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ReflectionService _reflectionService = ReflectionService();

  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _toggleBookmark(String id, bool currentVal) {
    _reflectionService.toggleBookmark(id, currentVal);
  }

  List<JournalEntry> _applyFilters(List<JournalEntry> entries) {
    return entries.where((e) {
      if (_selectedFilter == 'bookmarked' && !e.isBookmarked) return false;
      if (_selectedFilter != 'all' &&
          _selectedFilter != 'bookmarked' &&
          e.mood.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = e.title.toLowerCase().contains(q);
        final matchesSnippet = e.contentSnippet.toLowerCase().contains(q);
        final matchesMood = e.mood.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSnippet && !matchesMood) return false;
      }

      return true;
    }).toList();
  }

  void _confirmDelete(String id) {
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
          'This reflection will be permanently removed from your journal.',
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
              await _reflectionService.deleteReflection(id);
              if (mounted) {
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

  void _editReflection(ReflectionEntryModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreeformPage(
          id: model.id,
          date: model.date,
          initialTitle: model.freeformTitle,
          initialContent: model.freeformNote ??
              (model.answers.isNotEmpty ? model.answers.values.first : ''),
          initialMood: model.mood,
          initialPhotoUrl: model.photoUrl,
          reflectionAnswers: model.answers,
          isStandalone: true,
        ),
      ),
    );
  }

  void _viewSummary(ReflectionEntryModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryPage(
          id: model.id,
          mood: model.mood,
          moodEmoji: model.moodEmoji,
          freeformTitle: model.freeformTitle,
          freeformNote: model.freeformNote,
          photoUrl: model.photoUrl,
          answers: model.answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FreeformPage(isStandalone: true),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: Text(
          'New Entry',
          style: AppTextStyles.button.copyWith(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_reflectionService, SettingsService()]),
          builder: (context, _) {
            final models = _reflectionService.entries;
            final rawEntries = models.map((m) => m.toJournalEntry()).toList();
            final filtered = _applyFilters(rawEntries);

            // Calendar data maps
            final Map<DateTime, ReflectionEntry> reflectionData = {};
            final Map<DateTime, ReflectionEntryModel> modelByDate = {};
            for (final m in models) {
              final dateKey = DateTime(m.date.year, m.date.month, m.date.day);
              reflectionData[dateKey] = m.toHistoryEntry();
              modelByDate[dateKey] = m;
            }

            final completedDaysThisMonth =
                StreakCalculator.calculateCompletedDaysInMonth(
              models,
              _focusedMonth,
            );

            final selectedKey = _selectedDay != null
                ? DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day)
                : null;
            final selectedEntry =
                selectedKey != null ? reflectionData[selectedKey] : null;
            final selectedModel =
                selectedKey != null ? modelByDate[selectedKey] : null;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row (Title + PDF & Profile Drawer) ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Journal', style: AppTextStyles.greeting),
                          const SizedBox(height: 2),
                          Text(
                            'Past thoughts, reflections, and quiet moments.',
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // PDF Export shortcut
                          IconButton(
                            onPressed: () => PdfExportDialog.show(
                              context,
                              initialMonth: _focusedMonth,
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            tooltip: 'Export Keepsake PDF',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // 3-Line Menu Drawer Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              AppShell.openDrawer();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── View Mode Switcher Pill ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ViewModeTab(
                            label: 'Timeline Feed',
                            icon: Icons.list_alt_rounded,
                            isActive: _viewMode == JournalViewMode.timeline,
                            onTap: () => setState(
                                () => _viewMode = JournalViewMode.timeline),
                          ),
                        ),
                        Expanded(
                          child: _ViewModeTab(
                            label: 'Calendar Grid',
                            icon: Icons.calendar_month_rounded,
                            isActive: _viewMode == JournalViewMode.calendar,
                            onTap: () => setState(
                                () => _viewMode = JournalViewMode.calendar),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── VIEW 1: TIMELINE FEED ──────────────────────────
                  if (_viewMode == JournalViewMode.timeline) ...[
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.8),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search past thoughts or moods...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textHint.withValues(alpha: 0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textHint,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textHint,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips
                    JournalFilterChips(
                      selectedFilter: _selectedFilter,
                      onSelected: (id) =>
                          setState(() => _selectedFilter = id),
                    ),
                    const SizedBox(height: 18),

                    // Entries Feed List
                    if (_reflectionService.isLoading && rawEntries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.spa_outlined,
                                size: 48,
                                color: AppColors.textHint.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedFilter != 'all'
                                    ? 'No reflections match your filters'
                                    : 'Your journal is peaceful and waiting',
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedFilter != 'all'
                                    ? 'Try adjusting your search query or selected mood.'
                                    : 'Reflect tonight or tap New Entry to write freely.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final matchingModel = models.firstWhere(
                            (m) => m.id == entry.id,
                            orElse: () => ReflectionEntryModel(
                              id: entry.id,
                              date: entry.date,
                              mood: entry.mood,
                              moodEmoji: entry.moodEmoji,
                              freeformTitle: entry.title,
                              freeformNote: entry.contentSnippet,
                              answers: const {},
                              createdAt: entry.date,
                            ),
                          );

                          return JournalCard(
                            entry: entry,
                            onTap: () => _viewSummary(matchingModel),
                            onBookmarkToggle: () => _toggleBookmark(
                              entry.id,
                              entry.isBookmarked,
                            ),
                            onDelete: () => _confirmDelete(entry.id),
                            onEdit: () => _editReflection(matchingModel),
                          );
                        },
                      ),
                  ]

                  // ── VIEW 2: CALENDAR GRID ──────────────────────────
                  else ...[
                    // Streak banner
                    StreakBanner(
                      completedDays: completedDaysThisMonth,
                      totalDays: DateUtils.getDaysInMonth(
                        _focusedMonth.year,
                        _focusedMonth.month,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Calendar container
                    Container(
                      padding: const EdgeInsets.all(18),
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
                    const SizedBox(height: 18),

                    // Selected day card details
                    if (_selectedDay != null)
                      DayDetailCard(
                        day: _selectedDay!,
                        entry: selectedEntry,
                        onView: selectedModel != null
                            ? () => _viewSummary(selectedModel)
                            : null,
                        onEdit: selectedModel != null
                            ? () => _editReflection(selectedModel)
                            : null,
                        onDelete: selectedModel != null
                            ? () => _confirmDelete(selectedModel.id)
                            : null,
                      ),
                  ],

                  const SizedBox(height: 72),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ViewModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
