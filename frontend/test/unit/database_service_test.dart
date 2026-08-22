import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/features/reflection/services/database_service.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';
import 'package:daily_reflection/core/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DatabaseService Local-First & Sync Tests', () {
    test('SupabaseConfig correctly normalizes project URL', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabaseUrl.endsWith('/'), isFalse);
      expect(SupabaseConfig.supabaseUrl.endsWith('/rest/v1'), isFalse);
      expect(SupabaseConfig.isConfigured, isA<bool>());
    });

    test('ReflectionEntryModel serialization to/from Supabase Map format', () {
      final now = DateTime.now();
      final model = ReflectionEntryModel(
        id: 'refl_123',
        date: now,
        mood: 'Energized',
        moodEmoji: '⚡',
        answers: {1: 'Great morning run', 2: 'Clear priorities'},
        freeformTitle: 'Productive Day',
        freeformNote: 'Felt very energized today.',
        isBookmarked: true,
        type: ReflectionType.guided,
        createdAt: now,
      );

      final supaMap = model.toSupabaseMap(userId: 'user_abc_456');
      expect(supaMap['id'], equals('refl_123'));
      expect(supaMap['user_id'], equals('user_abc_456'));
      expect(supaMap['mood'], equals('Energized'));
      expect(supaMap['mood_emoji'], equals('⚡'));
      expect(supaMap['freeform_title'], equals('Productive Day'));
      expect(supaMap['freeform_note'], equals('Felt very energized today.'));
      expect(supaMap['is_bookmarked'], isTrue);
      expect(supaMap['answers']['1'], equals('Great morning run'));

      final restored = ReflectionEntryModel.fromSupabase(supaMap);
      expect(restored.id, equals('refl_123'));
      expect(restored.mood, equals('Energized'));
      expect(restored.moodEmoji, equals('⚡'));
      expect(restored.freeformTitle, equals('Productive Day'));
      expect(restored.freeformNote, equals('Felt very energized today.'));
      expect(restored.isBookmarked, isTrue);
      expect(restored.answers[1], equals('Great morning run'));
      expect(restored.answers[2], equals('Clear priorities'));
    });

    test('DatabaseService saves and retrieves reflections locally (0ms offline mode)', () async {
      final db = DatabaseService();
      final now = DateTime.now();
      final entry = ReflectionEntryModel(
        id: 'test_db_entry_1',
        date: now,
        mood: 'Peaceful',
        moodEmoji: '🌿',
        answers: {1: 'Quiet tea in morning'},
        freeformNote: 'Very peaceful sunset.',
        createdAt: now,
      );

      await db.saveReflection(entry);

      final latest = await db.getYesterdayOrLatestReflection();
      expect(latest, isNotNull);
      expect(latest!.id, equals('test_db_entry_1'));
      expect(latest.mood, equals('Peaceful'));
      expect(latest.freeformNote, equals('Very peaceful sunset.'));
      expect(latest.isBookmarked, isFalse);

      // Bookmark toggle
      await db.toggleBookmark('test_db_entry_1', false);
      final updated = await db.getYesterdayOrLatestReflection();
      expect(updated!.isBookmarked, isTrue);

      // Deletion
      await db.deleteReflection('test_db_entry_1');
      final afterDelete = await db.getYesterdayOrLatestReflection();
      expect(afterDelete, isNull);
    });
  });
}
