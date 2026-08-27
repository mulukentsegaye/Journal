import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic utility functions for key derivation, secure random generation,
/// and salted password/PIN hashing using PBKDF2-HMAC-SHA256 (RFC 8018).
class CryptoUtils {
  CryptoUtils._();

  static const int defaultPbkdf2Iterations = 100000;
  static const int defaultKeyLength = 32; // 256-bit AES key
  static const int defaultPinSaltLength = 16; // 128-bit salt
  static const String pbkdf2Prefix = 'pbkdf2\$sha256\$';

  /// Generates cryptographically secure pseudo-random bytes.
  static Uint8List generateSecureRandomBytes(int length) {
    final rng = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  /// Derives a key using PBKDF2-HMAC-SHA256 (RFC 8018 / PKCS #5 v2.1).
  static Uint8List pbkdf2HmacSha256({
    required Uint8List password,
    required Uint8List salt,
    int iterations = defaultPbkdf2Iterations,
    int keyLength = defaultKeyLength,
  }) {
    if (iterations < 1) {
      throw ArgumentError('Iterations must be at least 1');
    }
    if (keyLength < 1) {
      throw ArgumentError('Key length must be at least 1');
    }

    final hmac = Hmac(sha256, password);
    final numBlocks = (keyLength + 31) ~/ 32;
    final result = Uint8List(keyLength);
    int offset = 0;

    for (int i = 1; i <= numBlocks; i++) {
      // U_1 = PRF(Password, Salt || INT_32_BE(i))
      final blockInit = Uint8List(salt.length + 4);
      blockInit.setAll(0, salt);
      blockInit[salt.length] = (i >> 24) & 0xff;
      blockInit[salt.length + 1] = (i >> 16) & 0xff;
      blockInit[salt.length + 2] = (i >> 8) & 0xff;
      blockInit[salt.length + 3] = i & 0xff;

      var u = Uint8List.fromList(hmac.convert(blockInit).bytes);
      final block = Uint8List.fromList(u);

      // U_2 ... U_c
      for (int j = 1; j < iterations; j++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (int k = 0; k < block.length; k++) {
          block[k] ^= u[k];
        }
      }

      final bytesToCopy = (i == numBlocks && (keyLength % 32) != 0)
          ? (keyLength % 32)
          : 32;
      result.setRange(offset, offset + bytesToCopy, block.take(bytesToCopy));
      offset += bytesToCopy;
    }

    return result;
  }

  /// Hashes a PIN with a given or newly generated salt using PBKDF2-HMAC-SHA256.
  /// Format: `pbkdf2$sha256$<iterations>$<salt_base64>$<hash_base64>`
  static String hashPin({
    required String pin,
    Uint8List? salt,
    int iterations = defaultPbkdf2Iterations,
  }) {
    final pinSalt = salt ?? generateSecureRandomBytes(defaultPinSaltLength);
    final pinBytes = Uint8List.fromList(utf8.encode(pin));

    final derived = pbkdf2HmacSha256(
      password: pinBytes,
      salt: pinSalt,
      iterations: iterations,
      keyLength: defaultKeyLength,
    );

    final saltB64 = base64Encode(pinSalt);
    final hashB64 = base64Encode(derived);

    return '$pbkdf2Prefix$iterations\$$saltB64\$$hashB64';
  }

  /// Verifies entered PIN against a stored hash string (PBKDF2 or legacy SHA-256).
  static bool verifyPin({
    required String pin,
    required String storedHash,
  }) {
    if (storedHash.isEmpty) return false;

    // 1. Check for PBKDF2 format
    if (storedHash.startsWith(pbkdf2Prefix)) {
      try {
        final parts = storedHash.substring(pbkdf2Prefix.length).split('\$');
        if (parts.length != 3) return false;

        final iterations = int.parse(parts[0]);
        final salt = base64Decode(parts[1]);
        final expectedHash = base64Decode(parts[2]);

        final pinBytes = Uint8List.fromList(utf8.encode(pin));
        final computedHash = pbkdf2HmacSha256(
          password: pinBytes,
          salt: Uint8List.fromList(salt),
          iterations: iterations,
          keyLength: expectedHash.length,
        );

        return constantTimeEquals(computedHash, expectedHash);
      } catch (_) {
        return false;
      }
    }

    // 2. Legacy SHA-256 fallback (for zero-data-loss user migration)
    final legacyHash =
        sha256.convert(utf8.encode('daily_reflection_pin_salt:$pin')).toString();
    return constantTimeEquals(
      utf8.encode(legacyHash),
      utf8.encode(storedHash),
    );
  }

  /// Performs constant-time comparison to prevent timing side-channel attacks.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
