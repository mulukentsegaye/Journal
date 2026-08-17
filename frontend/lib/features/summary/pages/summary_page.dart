import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/summary_header_card.dart';
import '../widgets/response_item_card.dart';
import '../widgets/freeform_summary_card.dart';

/// Summary Page / Reflection Complete screen — displays all saved
/// answers, freeform note, mood tag, and share options.
class SummaryPage extends StatefulWidget {
  final String mood;
  final String moodEmoji;
  final String? freeformTitle;
  final String? freeformNote;
  final Map<int, String>? answers;

  const SummaryPage({
    super.key,
    this.mood = 'Calm',
    this.moodEmoji = '🌿',
    this.freeformTitle = "Title of tonight's thought",
    this.freeformNote =
        'Walked around the gardens after the wind died down. Let my breathing follow the rhythmic sway of the bamboo branch. Simple evening rest is more than enough.',
    this.answers,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isExpanded = false;

  static const List<_SummaryItem> _defaultResponses = [
    _SummaryItem(
      number: 1,
      question: 'What made you smile today?',
      answer: 'A warm cup of coffee by the window during a calm morning pause.',
    ),
    _SummaryItem(
      number: 2,
      question: 'Who or what are you most grateful for?',
      answer: 'My sister\'s voice note. She has this gift of bringing laughter to tiny things.',
    ),
    _SummaryItem(
      number: 3,
      question: 'What was a slight friction or lesson?',
      answer: 'I caught myself over-explaining in that afternoon sync. Trusting my silence more.',
    ),
    _SummaryItem(
      number: 4,
      question: 'Where did you feel tension in your body?',
      answer: 'My neck and shoulders, mostly right after the design review.',
    ),
    _SummaryItem(
      number: 5,
      question: 'What meaningful interaction did you have?',
      answer: 'A quiet conversation with a neighbor about their garden flowers.',
    ),
    _SummaryItem(
      number: 6,
      question: 'What can you release before sleep?',
      answer: 'The urge to check emails one last time. Tomorrow will take care of itself.',
    ),
    _SummaryItem(
      number: 7,
      question: 'What is one gentle intention for tomorrow?',
      answer: 'Take three deep breaths before replying to challenging messages.',
    ),
  ];

  void _shareReflection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Share Your Reflection',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export your peaceful anchor or copy as text.',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Text',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.textPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: const Text('Reflection copied to clipboard!'),
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.image_outlined,
                  label: 'Export Card',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.textPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: const Text('Image card generated.'),
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.lock_outline_rounded,
                  label: 'Keep Private',
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _finishAndReturnHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final visibleResponses = _isExpanded
        ? _defaultResponses
        : _defaultResponses.take(4).toList();
    final remainingCount = _defaultResponses.length - 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _finishAndReturnHome,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'October 20, 2026',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _shareReflection,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.ios_share_rounded,
                        size: 19,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with mood badge
                    SummaryHeaderCard(
                      mood: widget.mood,
                      moodEmoji: widget.moodEmoji,
                    ),
                    const SizedBox(height: 28),

                    // Section Title: RESPONSE SUMMARY
                    Text(
                      'RESPONSE SUMMARY',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Answer items
                    ...visibleResponses.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ResponseItemCard(
                          index: item.number,
                          question: item.question,
                          answer: item.answer,
                        ),
                      );
                    }),

                    // Expand / Collapse "+ 3 more reflective responses"
                    if (!_isExpanded && remainingCount > 0)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _isExpanded = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+ $remainingCount more reflective responses',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Additional Freeform Note Card
                    if (widget.freeformNote != null &&
                        widget.freeformNote!.isNotEmpty)
                      FreeformSummaryCard(
                        title: widget.freeformTitle,
                        note: widget.freeformNote!,
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bottom Return Home Button ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finishAndReturnHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Done for Tonight  ✓',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final int number;
  final String question;
  final String answer;

  const _SummaryItem({
    required this.number,
    required this.question,
    required this.answer,
  });
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
