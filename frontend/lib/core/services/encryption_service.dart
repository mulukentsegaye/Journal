import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/crypto_utils.dart';
import '../../features/reflection/models/reflection_entry_model.dart';
import '../../features/auth/services/auth_service.dart';

/// Client-Side End-to-End Encryption (E2EE) engine using AES-256 and PBKDF2-HMAC-SHA256.
///
/// Master entropy seeds and encryption keys are stored exclusively in hardware-backed
/// secure storage (Android Keystore / iOS Keychain) via [FlutterSecureStorage].
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService({FlutterSecureStorage? secureStorage}) {
    if (secureStorage != null) {
      _instance._secureStorage = secureStorage;
    }
    return _instance;
  }
  EncryptionService._internal();

  static const String _prefix = 'enc:aes256:';
  static const String _secureKeyPrefix = 'secure_e2ee_seed_';
  static const String _legacyPrefSeedKey = 'daily_reflection_e2ee_seed_';

  FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  enc.Key? _cachedKey;
  enc.Key? _cachedLegacyKey;
  String? _cachedUserId;

  /// Clears in-memory cached keys on user logout or session switch.
  void clearKeyCache() {
    _cachedKey = null;
    _cachedLegacyKey = null;
    _cachedUserId = null;
  }

  /// Initializes or retrieves the 256-bit AES key for the current user using PBKDF2.
  Future<enc.Key> _getKey() async {
    final userId = AuthService().currentUserId ?? 'default_guest_user';
    if (_cachedKey != null && _cachedUserId == userId) {
      return _cachedKey!;
    }

    final secureKey = '$_secureKeyPrefix$userId';
    var seed = await _secureStorage.read(key: secureKey);

    // Check for legacy unencrypted seed in SharedPreferences for seamless migration
    if (seed == null || seed.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final legacyPrefKey = '$_legacyPrefSeedKey$userId';
        final legacySeed = prefs.getString(legacyPrefKey);

        if (legacySeed != null && legacySeed.isNotEmpty) {
          seed = legacySeed;
          // Migrate to hardware-backed secure storage and delete plaintext from prefs
          await _secureStorage.write(key: secureKey, value: seed);
          await prefs.remove(legacyPrefKey);
          debugPrint('Successfully migrated E2EE seed to Keystore/Keychain.');
        }
      } catch (e) {
        debugPrint('Legacy seed check failed: $e');
      }
    }

    // If still null, generate a cryptographically strong 32-byte random seed
    if (seed == null || seed.isEmpty) {
      final randomBytes = CryptoUtils.generateSecureRandomBytes(32);
      seed = base64Encode(randomBytes);
      await _secureStorage.write(key: secureKey, value: seed);
    }

    // Derive the 256-bit AES key using PBKDF2-HMAC-SHA256 (100,000 iterations)
    final derivedKeyBytes = CryptoUtils.pbkdf2HmacSha256(
      password: Uint8List.fromList(utf8.encode('$userId:$seed')),
      salt: Uint8List.fromList(utf8.encode('daily_reflection_e2ee_kdf_salt:$userId')),
      iterations: CryptoUtils.defaultPbkdf2Iterations,
      keyLength: 32,
    );

    final key = enc.Key(derivedKeyBytes);

    // Also prepare legacy SHA-256 key for backward-compatibility fallback decryption
    final legacyHash = sha256.convert(utf8.encode('$userId:$seed:daily_reflection_salt_v1'));
    _cachedLegacyKey = enc.Key(Uint8List.fromList(legacyHash.bytes));

    _cachedKey = key;
    _cachedUserId = userId;
    return key;
  }

  /// Encrypts a string using AES-256-CBC with PBKDF2 key and fresh randomized IV.
  /// Returns `enc:aes256:<iv_base64>:<ciphertext_base64>` or original if empty.
  Future<String> encryptText(String? plainText) async {
    if (plainText == null || plainText.isEmpty) return '';
    if (plainText.startsWith(_prefix)) return plainText; // Already encrypted

    try {
      final key = await _getKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (_) {
      return plainText; // Fallback to plain text if encryption fails
    }
  }

  /// Decrypts an encrypted payload with automatic fallback for legacy-encrypted entries.
  Future<String> decryptText(String? cipherText) async {
    if (cipherText == null || cipherText.isEmpty) return '';
    if (!cipherText.startsWith(_prefix)) return cipherText; // Plain text / unencrypted

    try {
      final key = await _getKey();
      final content = cipherText.substring(_prefix.length);
      final parts = content.split(':');
      if (parts.length != 2) return cipherText;

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);

      // 1. Attempt decryption with PBKDF2 derived key
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt(encryptedData, iv: iv);
      } catch (_) {
        // 2. Fallback to legacy SHA-256 key for backward-compatibility
        if (_cachedLegacyKey != null) {
          final legacyEncrypter =
              enc.Encrypter(enc.AES(_cachedLegacyKey!, mode: enc.AESMode.cbc));
          return legacyEncrypter.decrypt(encryptedData, iv: iv);
        }
        rethrow;
      }
    } catch (_) {
      return cipherText;
    }
  }

  /// Encrypts all answers in the map.
  Future<Map<int, String>> encryptAnswers(Map<int, String> answers) async {
    if (answers.isEmpty) return {};
    final encrypted = <int, String>{};
    for (final entry in answers.entries) {
      encrypted[entry.key] = await encryptText(entry.value);
    }
    return encrypted;
  }

  /// Decrypts all answers in the map.
  Future<Map<int, String>> decryptAnswers(Map<int, String> answers) async {
    if (answers.isEmpty) return {};
    final decrypted = <int, String>{};
    for (final entry in answers.entries) {
      decrypted[entry.key] = await decryptText(entry.value);
    }
    return decrypted;
  }

  /// Encrypts sensitive fields in a ReflectionEntryModel for cloud sync.
  Future<ReflectionEntryModel> encryptEntry(ReflectionEntryModel entry) async {
    final encTitle = entry.freeformTitle != null && entry.freeformTitle!.isNotEmpty
        ? await encryptText(entry.freeformTitle)
        : entry.freeformTitle;

    final encNote = entry.freeformNote != null && entry.freeformNote!.isNotEmpty
        ? await encryptText(entry.freeformNote)
        : entry.freeformNote;

    final encAns = await encryptAnswers(entry.answers);

    return ReflectionEntryModel(
      id: entry.id,
      date: entry.date,
      mood: entry.mood,
      moodEmoji: entry.moodEmoji,
      answers: encAns,
      freeformTitle: encTitle,
      freeformNote: encNote,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      createdAt: entry.createdAt,
    );
  }

  /// Decrypts sensitive fields in a ReflectionEntryModel for local display.
  Future<ReflectionEntryModel> decryptEntry(ReflectionEntryModel entry) async {
    final decTitle = entry.freeformTitle != null && entry.freeformTitle!.isNotEmpty
        ? await decryptText(entry.freeformTitle)
        : entry.freeformTitle;

    final decNote = entry.freeformNote != null && entry.freeformNote!.isNotEmpty
        ? await decryptText(entry.freeformNote)
        : entry.freeformNote;

    final decAns = await decryptAnswers(entry.answers);

    return ReflectionEntryModel(
      id: entry.id,
      date: entry.date,
      mood: entry.mood,
      moodEmoji: entry.moodEmoji,
      answers: decAns,
      freeformTitle: decTitle,
      freeformNote: decNote,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      createdAt: entry.createdAt,
    );
  }
}
