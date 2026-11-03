import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/features/journal/widgets/journal_card.dart';
import 'package:daily_reflection/features/journal/models/journal_entry.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';

void main() {
  group('JournalCard.formatRelativeTime tests', () {
    test('returns "Just now" for times within 45 seconds', () {
      final now = DateTime.now();
      expect(JournalCard.formatRelativeTime(now), equals('Just now'));
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(seconds: 15))),
        equals('Just now'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(seconds: 40))),
        equals('Just now'),
      );
    });

    test('returns seconds ago for 45-59 seconds', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(seconds: 50))),
        equals('50s ago'),
      );
    });

    test('returns minutes ago for 1-59 minutes (including user 10m scenario)', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(minutes: 1))),
        equals('1m ago'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(minutes: 10))),
        equals('10m ago'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(minutes: 55))),
        equals('55m ago'),
      );
    });

    test('returns hours ago for 1-23 hours', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(hours: 1))),
        equals('1h ago'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(hours: 5))),
        equals('5h ago'),
      );
    });

    test('returns days ago for 1-6 days', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(days: 1))),
        equals('1d ago'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(days: 4))),
        equals('4d ago'),
      );
    });

    test('returns weeks ago for 7-29 days', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(days: 14))),
        equals('2w ago'),
      );
    });

    test('returns months and years ago for longer periods', () {
      final now = DateTime.now();
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(days: 65))),
        equals('2mo ago'),
      );
      expect(
        JournalCard.formatRelativeTime(now.subtract(const Duration(days: 400))),
        equals('1y ago'),
      );
    });

    test('handles UTC timestamps accurately against local time', () {
      final utcTenMinutesAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      expect(
        JournalCard.formatRelativeTime(utcTenMinutesAgo),
        equals('10m ago'),
      );
    });

    test('gracefully handles clock skew within 60s', () {
      final slightFuture = DateTime.now().add(const Duration(seconds: 15));
      expect(JournalCard.formatRelativeTime(slightFuture), equals('Just now'));
    });
  });

  group('ReflectionEntryModel timestamp parsing tests', () {
    test('fromMap preserves date and converts UTC ISO string to local', () {
      final createdUtc = DateTime.utc(2026, 11, 3, 10, 0, 0);
      final map = {
        'id': 'test_1',
        'date': createdUtc.toIso8601String(),
        'created_at': createdUtc.toIso8601String(),
        'mood': 'Calm',
      };

      final model = ReflectionEntryModel.fromMap(map, 'test_1');
      expect(model.createdAt.isUtc, isFalse);
      expect(model.createdAt.toUtc(), equals(createdUtc));
      expect(model.date.toUtc(), equals(createdUtc));
    });

    test('fromMap falls back to parsed date instead of DateTime.now() if createdAt missing', () {
      final entryDate = DateTime(2026, 10, 15, 14, 30);
      final map = {
        'id': 'test_2',
        'date': entryDate.toIso8601String(),
        'mood': 'Calm',
      };

      final model = ReflectionEntryModel.fromMap(map, 'test_2');
      expect(model.createdAt, equals(entryDate));
    });

    test('toSupabaseMap formats timestamps with UTC indicator', () {
      final localDate = DateTime(2026, 11, 3, 12, 0, 0);
      final model = ReflectionEntryModel(
        id: 'test_3',
        date: localDate,
        createdAt: localDate,
      );

      final supabaseMap = model.toSupabaseMap();
      expect(supabaseMap['date'], endsWith('Z'));
      expect(supabaseMap['created_at'], endsWith('Z'));
      expect(supabaseMap['updated_at'], endsWith('Z'));
    });
  });

  group('RelativeTimeText Widget tests', () {
    testWidgets('renders relative time text correctly', (tester) async {
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelativeTimeText(dateTime: tenMinutesAgo),
          ),
        ),
      );

      expect(find.text('10m ago'), findsOneWidget);
    });

    testWidgets('renders JournalCard with accurate relative time', (tester) async {
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      final entry = JournalEntry(
        id: 'entry_1',
        date: tenMinutesAgo,
        createdAt: tenMinutesAgo,
        title: 'Morning Reflections',
        contentSnippet: 'Wrote some thoughts this morning...',
        mood: 'Calm',
        moodEmoji: '🌿',
        moodBgColor: Colors.transparent,
        moodTextColor: Colors.white,
        questionsCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalCard(
              entry: entry,
              onTap: () {},
              onBookmarkToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('10m ago'), findsOneWidget);
      expect(find.text('Morning Reflections'), findsNothing); // snippet displayed
      expect(find.text('Read entry →'), findsOneWidget);
    });
  });
}
