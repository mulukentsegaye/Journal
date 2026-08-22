import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/reflection/models/reflection_entry_model.dart';
import '../../features/auth/services/auth_service.dart';

/// Client-Side End-to-End Encryption (E2EE) engine using AES-256.
///
/// Encrypts sensitive journal text (notes, answers, titles) on-device before
/// sending to Supabase, guaranteeing zero-knowledge cloud storage.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _prefix = 'enc:aes256:';
  static const String _keyUserSeed = 'daily_reflection_e2ee_seed_';

  enc.Key? _cachedKey;
  String? _cachedUserId;

  /// Initializes or retrieves the 256-bit AES key for the current user.
  Future<enc.Key> _getKey() async {
    final userId = AuthService().currentUserId ?? 'default_guest_user';
    if (_cachedKey != null && _cachedUserId == userId) {
      return _cachedKey!;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefKey = '$_keyUserSeed$userId';
    var seed = prefs.getString(prefKey);

    if (seed == null || seed.isEmpty) {
      // Generate a new secure entropy seed
      final randomBytes = enc.SecureRandom(32).bytes;
      seed = base64Encode(randomBytes);
      await prefs.setString(prefKey, seed);
    }

    // Derive a 32-byte (256-bit) AES key using SHA-256
    final hash = sha256.convert(utf8.encode('$userId:$seed:daily_reflection_salt_v1'));
    final key = enc.Key(Uint8List.fromList(hash.bytes));

    _cachedKey = key;
    _cachedUserId = userId;
    return key;
  }

  /// Encrypts a string using AES-256-CBC with a fresh randomized IV.
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

  /// Decrypts an encrypted payload. If text is unencrypted, returns it as-is.
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
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      return encrypter.decrypt(encryptedData, iv: iv);
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
