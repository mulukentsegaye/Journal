import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../shared/widgets/voice_input_button.dart';

/// Card containing title and multi-line body editor for freeform reflection.
class FreeformEditor extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode? titleFocusNode;
  final FocusNode? contentFocusNode;
  final ValueChanged<String>? onContentChanged;

  const FreeformEditor({
    super.key,
    required this.titleController,
    required this.contentController,
    this.titleFocusNode,
    this.contentFocusNode,
    this.onContentChanged,
  });

  static const List<String> promptPills = [
    '✨ A gentle moment',
    '🍂 Untangling a worry',
    '🌿 What brought peace?',
    '☕ Small sensory details',
  ];

  int get _wordCount {
    final text = contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Inspiration Prompt Pills ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: promptPills.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (titleController.text.isEmpty) {
                          titleController.text = prompt.replaceFirst(RegExp(r'^[^\w]+'), '').trim();
                        } else {
                          final current = contentController.text;
                          final addition = current.isEmpty ? '$prompt\n' : '\n\n$prompt\n';
                          contentController.text = current + addition;
                          contentController.selection = TextSelection.fromPosition(
                            TextPosition(offset: contentController.text.length),
                          );
                        }
                        if (onContentChanged != null) {
                          onContentChanged!(contentController.text);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          prompt,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Divider(color: AppColors.divider, height: 1),

          // ── Title Input ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: "Title of tonight's thought",
                hintStyle: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                  height: 1.3,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          Divider(color: AppColors.divider, height: 16),

          // ── Content / Note Body Input ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: contentController,
              focusNode: contentFocusNode,
              onChanged: onContentChanged,
              maxLines: null,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:
                    'Today was a transition day. Write whatever comes up — raw thoughts, quiet observations, or peaceful notes...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textHint.withValues(alpha: 0.55),
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 4, bottom: 12),
              ),
            ),
          ),

          // ── Voice Input & Word Count Bar ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VoiceInputButton(
                  controller: contentController,
                  label: 'Speak your thoughts',
                  onTextChanged: onContentChanged,
                ),
                Text(
                  '$_wordCount words',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Footer (Peace note) ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 13,
                  color: AppColors.textHint.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 5),
                Text(
                  'No rules or expectations',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
