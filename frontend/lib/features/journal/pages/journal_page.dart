import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_card.dart';
import '../widgets/journal_filter_chips.dart';
import '../../summary/pages/summary_page.dart';
import '../../freeform/pages/freeform_page.dart';
import '../../reflection/models/reflection_entry_model.dart';
import '../../reflection/services/reflection_service.dart';

/// Journal Page — searchable, filterable archive of past reflections and notes.
/// Connected to live Cloud Firestore data.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ReflectionService _reflectionService = ReflectionService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleBookmark(String id, bool currentVal) {
    _reflectionService.toggleBookmark(id, currentVal);
  }

  List<JournalEntry> _applyFilters(List<JournalEntry> entries) {
    return entries.where((e) {
      // Filter by mood / bookmark
      if (_selectedFilter == 'bookmarked' && !e.isBookmarked) return false;
      if (_selectedFilter != 'all' &&
          _selectedFilter != 'bookmarked' &&
          e.mood.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }

      // Filter by search query
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
          reflectionAnswers: model.answers,
          isStandalone: true,
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
          listenable: _reflectionService,
          builder: (context, _) {
            final models = _reflectionService.entries;
            final rawEntries = models.map((m) => m.toJournalEntry()).toList();
            final filtered = _applyFilters(rawEntries);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Subtitle ─────────────────────────────
                  Text('Your Journal', style: AppTextStyles.greeting),
                  const SizedBox(height: 4),
                  Text(
                    'Past thoughts, reflections, and quiet moments.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 20),

                  // ── Search Bar ───────────────────────────────────
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
                  const SizedBox(height: 16),

                  // ── Filter Chips ─────────────────────────────────
                  JournalFilterChips(
                    selectedFilter: _selectedFilter,
                    onSelected: (id) => setState(() => _selectedFilter = id),
                  ),
                  const SizedBox(height: 22),

                  // ── Entries List or Empty State ──────────────────
                  if (_reflectionService.isLoading && rawEntries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    _buildEmptyState(isInitial: rawEntries.isEmpty)
                  else
                    ...filtered.map((entry) {
                      // Find original model to pass full answers if available
                      final originalModel = models.firstWhere(
                        (m) => m.id == entry.id,
                        orElse: () => ReflectionEntryModel(
                          id: entry.id,
                          date: entry.date,
                          mood: entry.mood,
                          moodEmoji: entry.moodEmoji,
                          freeformTitle: entry.title,
                          freeformNote: entry.contentSnippet,
                          createdAt: entry.date,
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: JournalCard(
                          entry: entry,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SummaryPage(
                                  id: originalModel.id,
                                  mood: originalModel.mood,
                                  moodEmoji: originalModel.moodEmoji,
                                  freeformTitle: originalModel.freeformTitle,
                                  freeformNote: originalModel.freeformNote,
                                  answers: originalModel.answers,
                                ),
                              ),
                            );
                          },
                          onBookmarkToggle: () => _toggleBookmark(
                            entry.id,
                            entry.isBookmarked,
                          ),
                          onEdit: () => _editReflection(originalModel),
                          onDelete: () => _confirmDelete(entry.id),
                        ),
                      );
                    }),

                  const SizedBox(height: 60), // Extra space for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isInitial = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(isInitial ? '✨' : '🍃', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            isInitial
                ? 'Your quiet space awaits'
                : 'No matching reflections found',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isInitial
                ? 'Complete your first reflection or write a thought to see it synced here.'
                : 'Try clearing your search or selecting a different filter.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
