import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

/// Displays an inspirational quote in italic serif with attribution.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              const Text(
                '——',
                style: TextStyle(
                  color: Color(0xFFB0A89F),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(author, style: AppTextStyles.quoteAttribution),
            ],
          ),
        ],
      ),
    );
  }
}
