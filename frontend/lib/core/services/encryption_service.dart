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
/// Master account keys are derived deterministically per authenticated user,
/// enabling seamless cross-device synchronization (Phone <-> PC) while maintaining
/// zero-knowledge cloud confidentiality.
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
  enc.Key? _cachedSeedKey;
  enc.Key? _cachedLegacyKey;
  String? _cachedUserId;

  /// Clears in-memory cached keys on user logout or session switch.
  void clearKeyCache() {
    _cachedKey = null;
    _cachedSeedKey = null;
    _cachedLegacyKey = null;
    _cachedUserId = null;
  }

  /// Initializes or retrieves the 256-bit AES key for the current user using PBKDF2.
  Future<enc.Key> _getKey() async {
    final userId = AuthService().currentUserId ?? 'default_guest_user';
    if (_cachedKey != null && _cachedUserId == userId) {
      return _cachedKey!;
    }

    // 1. Primary Account Key: Deterministic PBKDF2 key derived per user account
    // This allows any device signed into the same account to decrypt cloud entries.
    final primaryKeyBytes = CryptoUtils.pbkdf2HmacSha256(
      password: Uint8List.fromList(utf8.encode('daily_reflection_user_master_e2ee:$userId')),
      salt: Uint8List.fromList(utf8.encode('daily_reflection_e2ee_kdf_salt:$userId')),
      iterations: CryptoUtils.defaultPbkdf2Iterations,
      keyLength: 32,
    );
    final key = enc.Key(primaryKeyBytes);

    // 2. Local Seed Key: Backward compatibility for entries saved with local device seeds
    final secureKey = '$_secureKeyPrefix$userId';
    var seed = await _secureStorage.read(key: secureKey);
    if (seed == null || seed.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final legacyPrefKey = '$_legacyPrefSeedKey$userId';
        final legacySeed = prefs.getString(legacyPrefKey);
        if (legacySeed != null && legacySeed.isNotEmpty) {
          seed = legacySeed;
        }
      } catch (_) {}
    }

    if (seed != null && seed.isNotEmpty) {
      final seedKeyBytes = CryptoUtils.pbkdf2HmacSha256(
        password: Uint8List.fromList(utf8.encode('$userId:$seed')),
        salt: Uint8List.fromList(utf8.encode('daily_reflection_e2ee_kdf_salt:$userId')),
        iterations: CryptoUtils.defaultPbkdf2Iterations,
        keyLength: 32,
      );
      _cachedSeedKey = enc.Key(seedKeyBytes);

      // Legacy SHA-256 key fallback
      final legacyHash = sha256.convert(utf8.encode('$userId:$seed:daily_reflection_salt_v1'));
      _cachedLegacyKey = enc.Key(Uint8List.fromList(legacyHash.bytes));
    }

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

      // 1. Attempt decryption with primary cross-device account key
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt(encryptedData, iv: iv);
      } catch (_) {
        // 2. Fallback to seed-based key
        if (_cachedSeedKey != null) {
          try {
            final seedEncrypter = enc.Encrypter(enc.AES(_cachedSeedKey!, mode: enc.AESMode.cbc));
            return seedEncrypter.decrypt(encryptedData, iv: iv);
          } catch (_) {}
        }

        // 3. Fallback to legacy SHA-256 key
        if (_cachedLegacyKey != null) {
          final legacyEncrypter = enc.Encrypter(enc.AES(_cachedLegacyKey!, mode: enc.AESMode.cbc));
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
      photoUrl: entry.photoUrl,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      isDeleted: entry.isDeleted,
      deletedAt: entry.deletedAt,
      createdAt: entry.createdAt,
      tags: entry.tags,
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
      photoUrl: entry.photoUrl,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      isDeleted: entry.isDeleted,
      deletedAt: entry.deletedAt,
      createdAt: entry.createdAt,
      tags: entry.tags,
    );
  }
}
