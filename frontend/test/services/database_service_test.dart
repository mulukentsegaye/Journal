import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';
import 'package:daily_reflection/features/reflection/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('DatabaseService & Isolate Worker Tests', () {
    test('parseEntriesFromJsonStrings correctly parses and sorts entries', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final raw1 = jsonEncode({
        'id': 'entry_yesterday',
        'date': yesterday.toIso8601String(),
        'mood': 'Peaceful',
        'moodEmoji': '🌿',
        'freeformTitle': 'Yesterday reflection',
        'freeformNote': 'Quiet moment',
        'answers': {},
        'createdAt': yesterday.toIso8601String(),
      });

      final raw2 = jsonEncode({
        'id': 'entry_today',
        'date': now.toIso8601String(),
        'mood': 'Grateful',
        'moodEmoji': '🙏',
        'freeformTitle': 'Today reflection',
        'freeformNote': 'Mindful day',
        'answers': {},
        'createdAt': now.toIso8601String(),
      });

      final parsed = parseEntriesFromJsonStrings([raw1, raw2, 'invalid_json']);
      expect(parsed.length, equals(2));
      // Verify date descending sort
      expect(parsed.first.id, equals('entry_today'));
      expect(parsed.last.id, equals('entry_yesterday'));
    });

    test('serializeEntriesToJsonStrings correctly serializes entries', () {
      final entry = ReflectionEntryModel(
        id: 'test_123',
        date: DateTime(2026, 8, 27),
        mood: 'Calm',
        moodEmoji: '🌱',
        freeformTitle: 'Evening walk',
        freeformNote: 'Enjoyed fresh air',
        answers: const {1: 'Peace'},
        createdAt: DateTime(2026, 8, 27),
      );

      final map = entry.toMap();
      map['id'] = entry.id;

      final serialized = serializeEntriesToJsonStrings([map]);
      expect(serialized.length, equals(1));

      final decoded = jsonDecode(serialized.first) as Map<String, dynamic>;
      expect(decoded['id'], equals('test_123'));
      expect(decoded['mood'], equals('Calm'));
    });

    test('DatabaseService saves and retrieves local entries', () async {
      final db = DatabaseService();
      final entry = ReflectionEntryModel(
        id: 'local_save_test',
        date: DateTime.now(),
        mood: 'Joyful',
        moodEmoji: '✨',
        freeformTitle: 'Great accomplishment',
        freeformNote: 'Completed goals today',
        answers: const {},
        createdAt: DateTime.now(),
      );

      await db.saveReflection(entry);

      final streamEntries = await db.streamReflections().first;
      expect(streamEntries.any((e) => e.id == 'local_save_test'), isTrue);

      final latest = await db.getYesterdayOrLatestReflection();
      expect(latest?.id, equals('local_save_test'));
    });
  });
}
