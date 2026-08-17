import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_card.dart';
import '../widgets/journal_filter_chips.dart';
import '../../summary/pages/summary_page.dart';
import '../../freeform/pages/freeform_page.dart';

/// Journal Page — searchable, filterable archive of past reflections and notes.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<JournalEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _generateSampleEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JournalEntry> _generateSampleEntries() {
    final now = DateTime.now();
    return [
      JournalEntry(
        id: '1',
        date: now,
        title: "Title of tonight's thought",
        contentSnippet:
            'Walked around the gardens after the wind died down. Let my breathing follow the rhythmic sway of the bamboo branch. Simple evening rest is more than enough.',
        mood: 'Calm',
        moodEmoji: '🌿',
        moodBgColor: AppColors.calmTagBg,
        moodTextColor: AppColors.calmTagText,
        questionsCount: 7,
        isBookmarked: true,
      ),
      JournalEntry(
        id: '2',
        date: now.subtract(const Duration(days: 1)),
        title: 'Gentle transitions & quiet walks',
        contentSnippet:
            'Felt a gentle transition today. Let go of work stress and walked around the gardens. Noticed how the late afternoon sun warmed the stone paths.',
        mood: 'Calm',
        moodEmoji: '🌿',
        moodBgColor: AppColors.calmTagBg,
        moodTextColor: AppColors.calmTagText,
        questionsCount: 5,
        isBookmarked: false,
      ),
      JournalEntry(
        id: '3',
        date: now.subtract(const Duration(days: 2)),
        title: 'Gratitude for unexpected laughter',
        contentSnippet:
            'Called an old friend today. Gratitude fills the spaces between words left unsaid. We laughed about the simplest memories from years ago.',
        mood: 'Grateful',
        moodEmoji: '🙏',
        moodBgColor: const Color(0xFFF4EDFA),
        moodTextColor: const Color(0xFF8B6BA8),
        questionsCount: 6,
        isBookmarked: true,
      ),
      JournalEntry(
        id: '4',
        date: now.subtract(const Duration(days: 4)),
        title: 'Momentum and letting go of perfection',
        contentSnippet:
            'Finished a project I had been putting off. Momentum creates its own kind of joy. Realized that done with care is better than forever chasing perfection.',
        mood: 'Happy',
        moodEmoji: '☀️',
        moodBgColor: const Color(0xFFFEF4DC),
        moodTextColor: const Color(0xFFC78B2A),
        questionsCount: 7,
        isBookmarked: false,
      ),
      JournalEntry(
        id: '5',
        date: now.subtract(const Duration(days: 6)),
        title: 'Sitting with the quiet evening',
        contentSnippet:
            'Sat with silence for ten minutes. The world felt kinder after that pause. Let go of a small frustration that I had been carrying all week.',
        mood: 'Reflective',
        moodEmoji: '💭',
        moodBgColor: const Color(0xFFF0EBE5),
        moodTextColor: const Color(0xFF8A7A6E),
        questionsCount: 5,
        isBookmarked: false,
      ),
    ];
  }

  void _toggleBookmark(String id) {
    setState(() {
      _entries = _entries.map((e) {
        if (e.id == id) {
          return e.copyWith(isBookmarked: !e.isBookmarked);
        }
        return e;
      }).toList();
    });
  }

  List<JournalEntry> get _filteredEntries {
    return _entries.where((e) {
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

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
        child: SingleChildScrollView(
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
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                    prefixIcon: const Icon(
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
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
              if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: JournalCard(
                      entry: entry,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SummaryPage(
                              mood: entry.mood,
                              moodEmoji: entry.moodEmoji,
                              freeformTitle: entry.title,
                              freeformNote: entry.contentSnippet,
                            ),
                          ),
                        );
                      },
                      onBookmarkToggle: () => _toggleBookmark(entry.id),
                    ),
                  );
                }),

              const SizedBox(height: 60), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text('🍃', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'No matching reflections found',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing your search or selecting a different filter.',
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
