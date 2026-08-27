import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils PBKDF2 & Cryptography Tests', () {
    test('generateSecureRandomBytes returns byte array with requested length', () {
      final bytes16 = CryptoUtils.generateSecureRandomBytes(16);
      expect(bytes16.length, equals(16));

      final bytes32 = CryptoUtils.generateSecureRandomBytes(32);
      expect(bytes32.length, equals(32));

      // Check non-zero randomness
      expect(bytes32.any((b) => b != 0), isTrue);
    });

    test('pbkdf2HmacSha256 derives deterministic key from password and salt', () {
      final password = Uint8List.fromList(utf8.encode('password'));
      final salt = Uint8List.fromList(utf8.encode('salt'));

      final key1 = CryptoUtils.pbkdf2HmacSha256(
        password: password,
        salt: salt,
        iterations: 1000,
        keyLength: 32,
      );

      final key2 = CryptoUtils.pbkdf2HmacSha256(
        password: password,
        salt: salt,
        iterations: 1000,
        keyLength: 32,
      );

      expect(key1, equals(key2));
      expect(key1.length, equals(32));
    });

    test('hashPin generates valid PBKDF2 format and verifies correctly', () {
      const pin = '1234';
      final hashStr = CryptoUtils.hashPin(pin: pin, iterations: 1000);

      expect(hashStr.startsWith(CryptoUtils.pbkdf2Prefix), isTrue);
      expect(hashStr.contains('1000'), isTrue);

      // Verify correct PIN matches
      expect(CryptoUtils.verifyPin(pin: pin, storedHash: hashStr), isTrue);

      // Verify incorrect PIN fails
      expect(CryptoUtils.verifyPin(pin: '9999', storedHash: hashStr), isFalse);
      expect(CryptoUtils.verifyPin(pin: '1235', storedHash: hashStr), isFalse);
      expect(CryptoUtils.verifyPin(pin: '', storedHash: hashStr), isFalse);
    });

    test('verifyPin validates legacy SHA-256 hash for seamless migration', () {
      const pin = '5678';
      final legacySha256 =
          sha256.convert(utf8.encode('daily_reflection_pin_salt:$pin')).toString();

      // Verify correct PIN matches legacy hash
      expect(
        CryptoUtils.verifyPin(pin: pin, storedHash: legacySha256),
        isTrue,
      );

      // Verify wrong PIN fails legacy hash
      expect(
        CryptoUtils.verifyPin(pin: '0000', storedHash: legacySha256),
        isFalse,
      );
    });

    test('constantTimeEquals compares constant-time equality', () {
      expect(CryptoUtils.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(CryptoUtils.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(CryptoUtils.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });
}
