import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/constants/app_strings.dart';

void main() {
  group('Daily Reflection 7 Questions Configuration Tests', () {
    test('AppStrings defines all 7 new introspective reflection questions', () {
      expect(AppStrings.questionPrompts.length, equals(7));
      expect(
        AppStrings.questionPrompts[1],
        equals('What are 7 things I am grateful for today?'),
      );
      expect(
        AppStrings.questionPrompts[2],
        equals('What are 7 good things I noticed today that I might normally overlook?'),
      );
      expect(
        AppStrings.questionPrompts[3],
        equals('What are 7 positive things I did today—for myself or someone else?'),
      );
      expect(
        AppStrings.questionPrompts[4],
        equals('What are 7 moments today when I was fully present?'),
      );
      expect(
        AppStrings.questionPrompts[5],
        equals('What are 7 things I could have done better today?'),
      );
      expect(
        AppStrings.questionPrompts[6],
        equals('What are 7 things I learned about myself today?'),
      );
      expect(
        AppStrings.questionPrompts[7],
        equals('What are 7 things I will intentionally do differently tomorrow?'),
      );
    });

    test('reflectionQuestions list contains matching categories, emojis, and hints', () {
      expect(AppStrings.reflectionQuestions.length, equals(7));
      for (int i = 0; i < 7; i++) {
        final q = AppStrings.reflectionQuestions[i];
        expect(q['text'], equals(AppStrings.questionPrompts[i + 1]));
        expect(q['category'], isNotEmpty);
        expect(q['emoji'], isNotEmpty);
        expect(q['hint'], isNotEmpty);
      }
    });
  });
}
