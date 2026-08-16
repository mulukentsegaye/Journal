import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Displays an inspirational quote with a decorative left accent border.
class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$quote"',
            style: AppTextStyles.quote,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '—  ',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Flexible(
                child: Text(author, style: AppTextStyles.quoteAttribution),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
