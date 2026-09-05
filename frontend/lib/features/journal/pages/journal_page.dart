import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/smooth_page_route.dart';
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
import '../../reflection/services/database_service.dart';
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
          'Move to Recycle Bin?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This reflection will be kept in your Recycle Bin. You can restore it anytime.',
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
                    content: const Text('Moved to Recycle Bin.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primary,
                      onPressed: () => _reflectionService.restoreReflection(id),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Move to Bin',
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
      SmoothPageRoute(
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
      SmoothPageRoute(
        builder: (_) => SummaryPage(
          id: model.id,
          date: model.date,
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

  Widget _buildSyncStatusChip() {
    final status = _reflectionService.syncStatus;
    IconData icon;
    String label;
    Color color;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        label = 'Synced';
        color = const Color(0xFF4CAF50);
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync_rounded;
        label = 'Syncing...';
        color = AppColors.primary;
        break;
      case SyncStatus.pendingChanges:
        icon = Icons.cloud_upload_rounded;
        label = 'Pending sync';
        color = const Color(0xFFFF9800);
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_rounded;
        label = 'Sync error';
        color = const Color(0xFFE53935);
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_rounded;
        label = 'Offline';
        color = AppColors.textHint;
        break;
      case SyncStatus.idle:
        icon = Icons.cloud_outlined;
        label = 'Cloud';
        color = AppColors.textHint;
        break;
    }

    return GestureDetector(
      onTap: () async {
        try {
          await _reflectionService.forceSyncNow();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Synced with cloud ✓'),
                  ],
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$e')),
                  ],
                ),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
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
            SmoothPageRoute(
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

            // Pre-index models into Map for fast O(1) lookups during lazy rendering
            final Map<String, ReflectionEntryModel> modelById = {
              for (final m in models) m.id: m,
            };

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

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              displacement: 36.0,
              edgeOffset: 0.0,
              onRefresh: () async {
                try {
                  await _reflectionService.forceSyncNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Synced with cloud ✓'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Sync failed: ${DatabaseService().formatSyncError(e)}')),
                          ],
                        ),
                        backgroundColor: const Color(0xFFD32F2F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  sliver: SliverToBoxAdapter(
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
                                const SizedBox(height: 6),
                                _buildSyncStatusChip(),
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
                      ],
                    ),
                  ),
                ),

                if (_viewMode == JournalViewMode.timeline) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.textHint,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
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
                        ],
                      ),
                    ),
                  ),

                  // Entries Feed List (Virtualized Lazy SliverList)
                  if (_reflectionService.isLoading && rawEntries.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 48, horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.spa_outlined,
                                size: 48,
                                color:
                                    AppColors.textHint.withValues(alpha: 0.4),
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
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final matchingModel = modelById[entry.id] ??
                              ReflectionEntryModel(
                                id: entry.id,
                                date: entry.date,
                                mood: entry.mood,
                                moodEmoji: entry.moodEmoji,
                                freeformTitle: entry.title,
                                freeformNote: entry.contentSnippet,
                                answers: const {},
                                createdAt: entry.date,
                              );

                          return JournalCard(
                            key: ValueKey(entry.id),
                            entry: entry,
                            onTap: () => _viewSummary(matchingModel),
                            onBookmarkToggle: () => _toggleBookmark(
                              entry.id,
                              entry.isBookmarked,
                            ),
                            onDelete: () => _confirmDelete(entry.id),
                            onEdit: () =>
                                _editReflection(matchingModel),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 88),
                  ),
                ] else ...[
                  // ── Calendar View Slivers ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 88),
                        ],
                      ),
                    ),
                  ),
                ],
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
