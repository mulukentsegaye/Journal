import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../shared/widgets/voice_input_button.dart';

/// Card containing title and multi-line body editor for freeform reflection.
class FreeformEditor extends StatelessWidget {
  final TextEditingController contentController;
  final FocusNode? contentFocusNode;
  final ValueChanged<String>? onContentChanged;
  final List<String> tags;
  final ValueChanged<List<String>>? onTagsChanged;

  const FreeformEditor({
    super.key,
    required this.contentController,
    this.contentFocusNode,
    this.onContentChanged,
    this.tags = const [],
    this.onTagsChanged,
  });

  static const List<String> promptPills = [
    '✨ A gentle moment',
    '🍂 Untangling a worry',
    '🌿 What brought peace?',
    '☕ Small sensory details',
  ];

  static const List<String> presetTags = [
    'gratitude',
    'ideas',
    'work',
    'mindset',
    'family',
    'peace',
    'creative',
    'memories',
  ];


  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Tag',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. mindfulness, study',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            prefixText: '#',
            prefixStyle: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onSubmitted: (val) {
            _addCustomTag(val);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _addCustomTag(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomTag(String input) {
    final clean = input.replaceAll('#', '').trim().toLowerCase();
    if (clean.isNotEmpty && !tags.contains(clean)) {
      onTagsChanged?.call([...tags, clean]);
    }
  }

  void _toggleTag(String tag) {
    final clean = tag.replaceAll('#', '').trim().toLowerCase();
    if (tags.contains(clean)) {
      onTagsChanged?.call(tags.where((t) => t != clean).toList());
    } else {
      onTagsChanged?.call([...tags, clean]);
    }
  }

  Widget _buildTagChip(String tag, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _toggleTag(tag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#$tag',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: promptPills.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        final current = contentController.text;
                        final addition = current.isEmpty ? '$prompt\n' : '\n\n$prompt\n';
                        contentController.text = current + addition;
                        contentController.selection = TextSelection.fromPosition(
                          TextPosition(offset: contentController.text.length),
                        );
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

          // ── Tag Pills Bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  // "+ Tag" button
                  GestureDetector(
                    onTap: () => _showAddTagDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            'Tag',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Custom tags not in presetTags
                  ...tags
                      .where((t) => !presetTags.contains(t.toLowerCase()))
                      .map((tag) => _buildTagChip(tag, isSelected: true)),

                  // Preset tags
                  ...presetTags.map((tag) {
                    final isSelected = tags.contains(tag.toLowerCase());
                    return _buildTagChip(tag, isSelected: isSelected);
                  }),
                ],
              ),
            ),
          ),



          // ── Content / Note Body Input ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: contentController,
              focusNode: contentFocusNode,
              onChanged: onContentChanged,
              maxLength: 10000,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              maxLines: null,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Write your thoughts here...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textHint.withValues(alpha: 0.6),
                  height: 1.6,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 4, bottom: 12),
              ),
            ),
          ),

          // ── Voice Input Bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VoiceInputButton(
                  controller: contentController,
                  label: 'Speak your thoughts',
                  onTextChanged: onContentChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
