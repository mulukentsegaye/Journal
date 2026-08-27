import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SecurityService Tests', () {
    test('singleton instance returns identical object', () {
      final s1 = SecurityService();
      final s2 = SecurityService();
      expect(identical(s1, s2), isTrue);
    });

    test('setting and verifying PIN with PBKDF2', () async {
      final service = SecurityService();
      await service.loadSecuritySettings();

      expect(service.hasPin, isFalse);

      await service.setPin('1234');
      expect(service.hasPin, isTrue);
      expect(service.isLockEnabled, isTrue);

      final success = await service.verifyPin('1234');
      expect(success, isTrue);

      final failure = await service.verifyPin('9999');
      expect(failure, isFalse);
    });

    test('rate limiting triggers lockout after consecutive failures', () async {
      final service = SecurityService();
      await service.setPin('4321');

      for (int i = 0; i < 5; i++) {
        await service.verifyPin('0000');
      }

      expect(service.failedAttempts, equals(5));
      expect(service.isRateLimited, isTrue);
      expect(service.lockoutSecondsRemaining, greaterThan(0));

      // Attempt while locked out should fail immediately
      final blocked = await service.verifyPin('4321');
      expect(blocked, isFalse);
    });

    test('removePin cleans up state', () async {
      final service = SecurityService();
      await service.setPin('1111');
      expect(service.hasPin, isTrue);

      await service.removePin();
      expect(service.hasPin, isFalse);
      expect(service.isLockEnabled, isFalse);
      expect(service.isLocked, isFalse);
    });
  });
}
