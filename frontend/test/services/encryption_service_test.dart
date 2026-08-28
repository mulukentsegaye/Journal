import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_reflection/core/services/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('EncryptionService Tests', () {
    test('singleton instance returns identical object', () {
      final e1 = EncryptionService();
      final e2 = EncryptionService();
      expect(identical(e1, e2), isTrue);
    });

    test('encryptText and decryptText round trip with PBKDF2 key', () async {
      final service = EncryptionService();
      const plainText = 'A mindful evening thought recorded securely.';

      final cipherText = await service.encryptText(plainText);
      expect(cipherText.startsWith('enc:aes256:'), isTrue);
      expect(cipherText, isNot(equals(plainText)));

      final decrypted = await service.decryptText(cipherText);
      expect(decrypted, equals(plainText));
    });

    test('encryptAnswers and decryptAnswers map round trip', () async {
      final service = EncryptionService();
      final answers = {
        1: 'I am grateful for peace and clarity.',
        2: 'Overcame obstacles with mindful patience.',
      };

      final encryptedMap = await service.encryptAnswers(answers);
      expect(encryptedMap[1], isNot(equals(answers[1])));

      final decryptedMap = await service.decryptAnswers(encryptedMap);
      expect(decryptedMap[1], equals(answers[1]));
      expect(decryptedMap[2], equals(answers[2]));
    });

    test('cross-device simulated encryption and decryption on same account', () async {
      // Simulate Device 1 (Phone)
      final device1Service = EncryptionService();
      const noteFromPhone = 'Reflecting from my mobile phone today!';
      final encryptedOnPhone = await device1Service.encryptText(noteFromPhone);

      // Simulate Device 2 (PC) with independent cache reset
      final device2Service = EncryptionService();
      device2Service.clearKeyCache();

      final decryptedOnPC = await device2Service.decryptText(encryptedOnPhone);
      expect(decryptedOnPC, equals(noteFromPhone));
    });
  });
}
