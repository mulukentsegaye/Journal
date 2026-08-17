import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/reflection_progress_bar.dart';
import '../widgets/question_card.dart';
import '../widgets/reflection_nav_buttons.dart';
import '../../freeform/pages/freeform_page.dart';

/// Evening Reflection — a guided multi-step question flow.
///
/// Users step through a series of introspective questions,
/// type responses, and navigate forward/backward with smooth
/// animated transitions.
class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<TextEditingController> _textControllers;
  late final List<FocusNode> _focusNodes;

  static const _questions = <_Question>[
    _Question(
      category: 'DAILY ANCHOR',
      emoji: '😊',
      text: 'What made you smile today?',
      hint: 'A warm cup of coffee, a kind word, a quiet moment…',
    ),
    _Question(
      category: 'GRATITUDE',
      emoji: '🙏',
      text: 'Who or what are you most grateful for?',
      hint: 'Think of a person, experience, or small blessing…',
    ),
    _Question(
      category: 'GROWTH',
      emoji: '🌱',
      text: 'What was a slight friction or lesson?',
      hint: 'A challenge that taught you something, however small…',
    ),
    _Question(
      category: 'BODY CHECK-IN',
      emoji: '🧘',
      text: 'Where did you feel tension in your body?',
      hint: 'Your shoulders, jaw, chest — notice without judgement…',
    ),
    _Question(
      category: 'CONNECTION',
      emoji: '💬',
      text: 'What meaningful interaction did you have?',
      hint: 'A conversation, a glance, a shared silence…',
    ),
    _Question(
      category: 'LETTING GO',
      emoji: '🍃',
      text: 'What can you release before sleep?',
      hint: 'A worry, a to-do, something out of your control…',
    ),
    _Question(
      category: 'INTENTION',
      emoji: '✨',
      text: 'What is one gentle intention for tomorrow?',
      hint: 'Something small and kind you can carry forward…',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textControllers =
        List.generate(_questions.length, (_) => TextEditingController());
    _focusNodes = List.generate(_questions.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _textControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    // Unfocus current field before animating
    _focusNodes[_currentIndex].unfocus();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _cancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave reflection?',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your answers so far won\'t be saved.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                Text('Leave', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  bool get _isLastQuestion => _currentIndex == _questions.length - 1;

  void _finish() {
    final answers = <int, String>{};
    for (int i = 0; i < _textControllers.length; i++) {
      final text = _textControllers[i].text.trim();
      if (text.isNotEmpty) {
        answers[i + 1] = text;
      }
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FreeformPage(
          isStandalone: true,
          reflectionAnswers: answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back arrow
                  GestureDetector(
                    onTap: () => _currentIndex > 0
                        ? _goTo(_currentIndex - 1)
                        : _cancel(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Evening Reflection',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancel,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ReflectionProgressBar(
                current: _currentIndex + 1,
                total: _questions.length,
              ),
            ),
            const SizedBox(height: 8),

            // ── Question pages ───────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return QuestionCard(
                    category: q.category,
                    emoji: q.emoji,
                    question: q.text,
                    hint: q.hint,
                    controller: _textControllers[index],
                    focusNode: _focusNodes[index],
                  );
                },
              ),
            ),

            // ── Navigation buttons ───────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ReflectionNavButtons(
                showPrevious: _currentIndex > 0,
                isLast: _isLastQuestion,
                onPrevious: () => _goTo(_currentIndex - 1),
                onNext: _isLastQuestion
                    ? _finish
                    : () => _goTo(_currentIndex + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question {
  final String category;
  final String emoji;
  final String text;
  final String hint;

  const _Question({
    required this.category,
    required this.emoji,
    required this.text,
    required this.hint,
  });
}
