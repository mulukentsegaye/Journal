import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/features/today/widgets/quote_card.dart';
import 'package:daily_reflection/features/history/widgets/streak_banner.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('QuoteCard renders quote and author text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuoteCard(
              quote: 'Quiet the mind and the soul will speak.',
              author: 'Ma Jaya Sati Bhagavati',
            ),
          ),
        ),
      );

      expect(find.text('"Quiet the mind and the soul will speak."'), findsOneWidget);
      expect(find.text('Ma Jaya Sati Bhagavati'), findsOneWidget);
    });

    testWidgets('StreakBanner renders completed days count and progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBanner(
              completedDays: 14,
              totalDays: 30,
            ),
          ),
        ),
      );

      expect(find.text('14 of 30 days reflected'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
