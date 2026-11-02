import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/core/services/settings_service.dart';
import 'package:daily_reflection/features/onboarding/pages/onboarding_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().resetOnboarding();
  });

  testWidgets('OnboardingPage renders updated slides and consistent feature chips',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(),
      ),
    );
    await tester.pump();

    // Slide 1: Mindful Journaling
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('MINDFUL JOURNALING'), findsOneWidget);
    expect(find.text('Write Freely, Speak Freely.'), findsOneWidget);
    expect(find.text('Freeform'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Advance to Slide 2
    await tester.tap(find.text('Continue'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Slide 2: 100% Private & Secure
    expect(find.text('100% PRIVATE & SECURE'), findsOneWidget);
    expect(find.text('Your Private Sanctuary.'), findsOneWidget);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('App Lock'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);

    // Advance to Slide 3
    await tester.tap(find.text('Continue'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Slide 3: Cherish Your Journey
    expect(find.text('CHERISH YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Remember Every Moment.'), findsOneWidget);
    expect(find.text('PDF Book'), findsOneWidget);
    expect(find.text('Streaks'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Begin My Journey 🌿'), findsOneWidget);

    // Tap final button to complete onboarding
    await tester.tap(find.text('Begin My Journey 🌿'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(SettingsService().hasCompletedOnboarding, isTrue);
  });

  testWidgets('scroll drag triggers interactive transition effects without errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(),
      ),
    );
    await tester.pump();

    // Partial swipe left
    await tester.drag(find.byType(PageView), const Offset(-180, 0));
    await tester.pump(const Duration(milliseconds: 50));

    // Release and fling swipe to next page
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Settled on Slide 2
    expect(find.text('100% PRIVATE & SECURE'), findsOneWidget);
  });
}
