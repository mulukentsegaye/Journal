import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ReflectionEntryModel Serialization & Conversion Tests', () {
    test('toMap and fromMap preserves all fields including type', () {
      final now = DateTime.now();
      final model = ReflectionEntryModel(
        id: 'test_doc_123',
        date: now,
        mood: 'Grateful',
        moodEmoji: '🙏',
        answers: {1: 'Morning stillness', 2: 'Kind word from friend'},
        freeformTitle: 'My Reflection Note',
        freeformNote: 'Peaceful day overall.',
        isBookmarked: true,
        type: ReflectionType.freeform,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['mood'], 'Grateful');
      expect(map['moodEmoji'], '🙏');
      expect(map['freeformTitle'], 'My Reflection Note');
      expect(map['isBookmarked'], true);
      expect(map['type'], 'freeform');

      final reconstructed = ReflectionEntryModel.fromMap(map, 'test_doc_123');
      expect(reconstructed.id, 'test_doc_123');
      expect(reconstructed.mood, 'Grateful');
      expect(reconstructed.type, ReflectionType.freeform);
      expect(reconstructed.answers[1], 'Morning stillness');
      expect(reconstructed.answers[2], 'Kind word from friend');
      expect(reconstructed.isBookmarked, true);
    });

    test('toJournalEntry converts properly with correct entryType tag', () {
      final now = DateTime(2026, 8, 20);
      final model = ReflectionEntryModel(
        id: 'journal_test_1',
        date: now,
        mood: 'Calm',
        moodEmoji: '🌿',
        answers: {1: 'Deep breath'},
        type: ReflectionType.guided,
        createdAt: now,
      );

      final journal = model.toJournalEntry();
      expect(journal.id, 'journal_test_1');
      expect(journal.entryType, 'guided');
      expect(journal.questionsCount, 1);
      expect(journal.contentSnippet, 'Deep breath');
    });

    test('toHistoryEntry maps questions answered and estimated time', () {
      final now = DateTime.now();
      final model = ReflectionEntryModel(
        id: 'hist_test_1',
        date: now,
        mood: 'Calm',
        answers: {1: 'A', 2: 'B', 3: 'C', 4: 'D'},
        createdAt: now,
      );

      final history = model.toHistoryEntry();
      expect(history.id, 'hist_test_1');
      expect(history.questionsAnswered, 4);
      expect(history.minutesSpent >= 3, true);
    });
  });
}
