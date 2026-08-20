import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/constants/app_strings.dart';

void main() {
  group('Quote Rotation Tests', () {
    test('quoteOfTheDay returns non-empty quote and author', () {
      final quoteData = AppStrings.quoteOfTheDay;
      expect(quoteData.containsKey('quote'), true);
      expect(quoteData.containsKey('author'), true);
      expect(quoteData['quote']!.isNotEmpty, true);
      expect(quoteData['author']!.isNotEmpty, true);
    });

    test('dailyQuotes repository has multiple mindful quotes', () {
      expect(AppStrings.dailyQuotes.length >= 10, true);
      for (final item in AppStrings.dailyQuotes) {
        expect(item['quote']!.isNotEmpty, true);
        expect(item['author']!.isNotEmpty, true);
      }
    });
  });
}
