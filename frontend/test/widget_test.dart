import 'package:flutter_test/flutter_test.dart';

import 'package:daily_reflection/app.dart';

void main() {
  testWidgets('App renders Today page', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyReflectionApp());

    // Verify the greeting is displayed
    expect(find.textContaining('Good'), findsOneWidget);

    // Verify the bottom nav is displayed
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
