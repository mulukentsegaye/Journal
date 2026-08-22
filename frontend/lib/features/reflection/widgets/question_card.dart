import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/voice_input_button.dart';

/// A single question step inside the reflection flow.
///
/// Shows the category label, emoji, question text,
/// a styled multi-line text field, and a 1-tap voice dictation button.
class QuestionCard extends StatelessWidget {
  final String category;
  final String emoji;
  final String question;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;

  const QuestionCard({
    super.key,
    required this.category,
    required this.emoji,
    required this.question,
    required this.hint,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Category pill ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Question text ──────────────────────────────────
          Text(
            question,
            style: GoogleFonts.lora(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // ── Answer text field & Voice Mic ──────────────────
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textHint.withValues(alpha: 0.6),
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    contentPadding: const EdgeInsets.all(18),
                    border: InputBorder.none,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      VoiceInputButton(
                        controller: controller,
                        label: 'Speak answer',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Encouragement note ────────────────────────────
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 5),
              Text(
                'Only you can see your reflections.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
