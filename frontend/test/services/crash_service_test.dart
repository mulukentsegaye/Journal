import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/config/sentry_config.dart';
import 'package:daily_reflection/core/services/crash_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashService & SentryConfig Tests', () {
    test('singleton instance returns identical object', () {
      final s1 = CrashService();
      final s2 = CrashService();
      expect(identical(s1, s2), isTrue);
    });

    test('SentryConfig handles unconfigured state gracefully', () {
      // By default without --dart-define, DSN is empty or unconfigured
      expect(SentryConfig.isConfigured, isFalse);
    });

    test('CrashService initializes cleanly when DSN is unconfigured', () async {
      final service = CrashService();
      bool runnerExecuted = false;

      await service.initialize(
        appRunner: () {
          runnerExecuted = true;
        },
      );

      expect(runnerExecuted, isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('recordError and addBreadcrumb do not throw', () async {
      final service = CrashService();
      
      expect(
        () => service.addBreadcrumb('Navigated to Journal tab', category: 'navigation'),
        returnsNormally,
      );

      expect(
        () => service.setUserId('anonymous_user_123'),
        returnsNormally,
      );

      expect(
        () => service.clearUser(),
        returnsNormally,
      );

      await expectLater(
        service.recordError(
          Exception('Simulated test exception'),
          StackTrace.current,
          reason: 'Unit testing crash reporting pipeline',
          fatal: false,
        ),
        completes,
      );
    });
  });
}
