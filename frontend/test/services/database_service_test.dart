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

    test('DatabaseService soft-deletes to Recycle Bin, restores, and permanently deletes', () async {
      final db = DatabaseService();
      final entry = ReflectionEntryModel(
        id: 'trash_test_1',
        date: DateTime.now(),
        mood: 'Calm',
        moodEmoji: '🌿',
        freeformTitle: 'Peaceful afternoon',
        freeformNote: 'Sat by the window',
        answers: const {},
        createdAt: DateTime.now(),
      );

      await db.saveReflection(entry);

      // 1. Soft delete -> marks isDeleted = true
      await db.deleteReflection('trash_test_1');
      var list = await db.streamReflections().first;
      final trashed = list.firstWhere((e) => e.id == 'trash_test_1');
      expect(trashed.isDeleted, isTrue);
      expect(trashed.deletedAt, isNotNull);

      // 2. Restore -> marks isDeleted = false
      await db.restoreReflection('trash_test_1');
      list = await db.streamReflections().first;
      final restored = list.firstWhere((e) => e.id == 'trash_test_1');
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);

      // 3. Soft delete again and permanent delete
      await db.deleteReflection('trash_test_1');
      await db.permanentlyDeleteReflection('trash_test_1');
      list = await db.streamReflections().first;
      expect(list.any((e) => e.id == 'trash_test_1'), isFalse);
    });

    test('DatabaseService emptyTrash removes all soft-deleted items', () async {
      final db = DatabaseService();
      final entry1 = ReflectionEntryModel(
        id: 'trash_item_1',
        date: DateTime.now(),
        mood: 'Calm',
        createdAt: DateTime.now(),
      );
      final entry2 = ReflectionEntryModel(
        id: 'active_item_2',
        date: DateTime.now(),
        mood: 'Grateful',
        createdAt: DateTime.now(),
      );

      await db.saveReflection(entry1);
      await db.saveReflection(entry2);

      await db.deleteReflection('trash_item_1');
      await db.emptyTrash();

      final list = await db.streamReflections().first;
      expect(list.any((e) => e.id == 'trash_item_1'), isFalse);
      expect(list.any((e) => e.id == 'active_item_2'), isTrue);
    });

    test('ReflectionEntryModel copyWith preserves bookmark state', () {
      final model = ReflectionEntryModel(
        id: 'bm_model_1',
        date: DateTime(2026, 9, 1),
        mood: 'Peaceful',
        isBookmarked: true,
        createdAt: DateTime(2026, 9, 1),
      );

      final modified = model.copyWith(mood: 'Radiant');
      expect(modified.isBookmarked, isTrue);
      expect(modified.mood, equals('Radiant'));

      final unbookmarked = modified.copyWith(isBookmarked: false);
      expect(unbookmarked.isBookmarked, isFalse);
    });

    test('DatabaseService toggleBookmark updates and persists isBookmarked', () async {
      final db = DatabaseService();
      final entry = ReflectionEntryModel(
        id: 'bm_toggle_test',
        date: DateTime.now(),
        mood: 'Grateful',
        isBookmarked: false,
        createdAt: DateTime.now(),
      );

      await db.saveReflection(entry);
      var list = await db.streamReflections().first;
      expect(list.firstWhere((e) => e.id == 'bm_toggle_test').isBookmarked, isFalse);

      await db.toggleBookmark('bm_toggle_test', false);
      list = await db.streamReflections().first;
      expect(list.firstWhere((e) => e.id == 'bm_toggle_test').isBookmarked, isTrue);

      await db.toggleBookmark('bm_toggle_test', true);
      list = await db.streamReflections().first;
      expect(list.firstWhere((e) => e.id == 'bm_toggle_test').isBookmarked, isFalse);
    });

    test('DatabaseService generateUniqueId generates timestamped non-empty id', () {
      final id1 = DatabaseService.generateUniqueId();
      final id2 = DatabaseService.generateUniqueId();

      expect(id1.isNotEmpty, isTrue);
      expect(id2.isNotEmpty, isTrue);
      expect(id1, isNot(equals(id2)));
    });

    test('DatabaseService formatSyncError provides friendly error messages', () {
      final db = DatabaseService();

      // 42501 RLS error
      final rlsError = 'PostgrestException(message: new row violates row-level security policy (USING expression) for table "reflections", code: 42501, details: Forbidden, hint: null)';
      final formattedRls = db.formatSyncError(rlsError);
      expect(formattedRls, contains('Cloud sync permission error'));

      // Network socket error
      final netError = 'SocketException: Failed host lookup';
      final formattedNet = db.formatSyncError(netError);
      expect(formattedNet, contains('Network connection unavailable'));

      // Auth error
      final authError = 'AuthException: Invalid token';
      final formattedAuth = db.formatSyncError(authError);
      expect(formattedAuth, contains('Session expired'));

      // PGRST204 Missing column schema cache error
      final pgrstError = "PostgrestException(message: Could not find the 'deleted_at' column of 'reflections' in the schema cache, code: PGRST204, details: Bad Request, hint: null)";
      final formattedPgrst = db.formatSyncError(pgrstError);
      expect(formattedPgrst, contains('Unable to sync with database'));
    });

    test('ReflectionEntryModel serializes and deserializes tags correctly', () {
      final entry = ReflectionEntryModel(
        id: 'tag_test_1',
        date: DateTime(2026, 9, 9),
        mood: 'Peaceful',
        tags: const ['gratitude', 'mindset', 'evening'],
        createdAt: DateTime(2026, 9, 9),
      );

      final map = entry.toMap();
      expect(map['tags'], equals(['gratitude', 'mindset', 'evening']));

      final restored = ReflectionEntryModel.fromMap(map, 'tag_test_1');
      expect(restored.tags, equals(['gratitude', 'mindset', 'evening']));

      final journal = restored.toJournalEntry();
      expect(journal.tags, equals(['gratitude', 'mindset', 'evening']));

      final modified = restored.copyWith(tags: ['creative']);
      expect(modified.tags, equals(['creative']));
    });

    test('DatabaseService saves and streams entries with tags', () async {
      final db = DatabaseService();
      final entry = ReflectionEntryModel(
        id: 'db_tags_test',
        date: DateTime.now(),
        mood: 'Calm',
        tags: const ['work', 'ideas'],
        createdAt: DateTime.now(),
      );

      await db.saveReflection(entry);
      final list = await db.streamReflections().first;
      final retrieved = list.firstWhere((e) => e.id == 'db_tags_test');
      expect(retrieved.tags, equals(['work', 'ideas']));
    });
  });
}

