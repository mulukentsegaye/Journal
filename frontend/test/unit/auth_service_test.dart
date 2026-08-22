import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/features/auth/services/auth_service.dart';
import 'package:daily_reflection/features/reflection/services/database_service.dart';
import 'package:daily_reflection/features/reflection/models/reflection_entry_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Guest Mode & Fallback Tests', () {
    test('signInAnonymously activates guest mode when Supabase is unconfigured/offline', () async {
      final auth = AuthService();
      await auth.signInAnonymously();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.isGuest, isTrue);
      expect(auth.isLocalGuest, isTrue);
      expect(auth.userName, equals('Guest'));
      expect(auth.currentUserId, startsWith('guest_'));
    });

    test('updateDisplayName updates guest name in local guest mode', () async {
      final auth = AuthService();
      await auth.signInAnonymously();
      await auth.updateDisplayName('Mindful Traveler');

      expect(auth.userName, equals('Mindful Traveler'));
    });

    test('signOut clears guest session', () async {
      final auth = AuthService();
      await auth.signInAnonymously();
      expect(auth.isLoggedIn, isTrue);

      await auth.signOut();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.isLocalGuest, isFalse);
    });

    test('DatabaseService saves and streams local reflections in Guest Mode', () async {
      final auth = AuthService();
      await auth.signInAnonymously();

      final dbService = DatabaseService();
      final now = DateTime.now();
      final entry = ReflectionEntryModel(
        id: 'guest_test_entry_1',
        date: now,
        mood: 'Grateful',
        moodEmoji: '🙏',
        answers: {1: 'Evening peace'},
        freeformNote: 'A restful evening.',
        createdAt: now,
      );

      await dbService.saveReflection(entry);

      final latest = await dbService.getYesterdayOrLatestReflection();
      expect(latest, isNotNull);
      expect(latest!.id, equals('guest_test_entry_1'));
      expect(latest.mood, equals('Grateful'));
      expect(latest.freeformNote, equals('A restful evening.'));

      // Toggle bookmark
      await dbService.toggleBookmark('guest_test_entry_1', false);
      final bookmarked = await dbService.getYesterdayOrLatestReflection();
      expect(bookmarked!.isBookmarked, isTrue);

      // Delete reflection
      await dbService.deleteReflection('guest_test_entry_1');
      final afterDelete = await dbService.getYesterdayOrLatestReflection();
      expect(afterDelete, isNull);
    });
  });
}
