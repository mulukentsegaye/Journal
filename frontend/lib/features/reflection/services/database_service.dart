import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/utils/error_formatter.dart';
import '../../auth/services/auth_service.dart';
import '../models/reflection_entry_model.dart';

/// Top-level isolate function for deserializing reflection entries from JSON.
/// Executed off the main UI thread via [compute] to prevent UI jank.
List<ReflectionEntryModel> parseEntriesFromJsonStrings(List<String> rawList) {
  final entries = <ReflectionEntryModel>[];
  for (final str in rawList) {
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      final id = map['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}';
      entries.add(ReflectionEntryModel.fromMap(map, id));
    } catch (e) {
      debugPrint('[DatabaseService] Failed to parse cached entry: $e');
    }
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

/// Top-level isolate function for serializing reflection entries to JSON.
/// Executed off the main UI thread via [compute] to prevent UI jank.
List<String> serializeEntriesToJsonStrings(List<Map<String, dynamic>> entryMaps) {
  return entryMaps.map((m) => jsonEncode(m)).toList();
}

/// Describes the current cloud sync state.
enum SyncStatus {
  /// Idle — no sync in progress, local cache is current.
  idle,
  /// Actively syncing with Supabase cloud.
  syncing,
  /// All local changes have been pushed and remote changes pulled.
  synced,
  /// There are pending writes queued for upload.
  pendingChanges,
  /// Sync failed with an error.
  error,
  /// Device has no internet connection.
  offline,
  /// User is not signed in to a cloud account (Local / Guest mode).
  notSignedIn,
}

/// Database service with Local-First offline persistence, AES-256 Client-Side
/// End-to-End Encryption (E2EE), paginated Supabase synchronization, and background isolate processing.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService([SupabaseClient? client]) {
    if (client != null) {
      _instance._injectedClient = client;
    }
    return _instance;
  }
  DatabaseService._internal();

  SupabaseClient? _injectedClient;
  final EncryptionService _encryption = EncryptionService();

  static const String _keyLocalReflectionsBase = 'daily_reflections_local_cache';
  static const String _keyPendingWritesBase = 'daily_reflections_pending_writes';
  static const String _keyPendingDeletesBase = 'daily_reflections_pending_deletes';
  static const String _keyLastUserId = 'daily_reflections_last_user_id';
  static const int defaultPageSize = 50;

  /// Returns user-scoped cache key to prevent cross-account data leakage.
  String _scopedKey(String base) {
    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty) return '${base}_$uid';
    return base;
  }

  String get _keyLocalReflections => _scopedKey(_keyLocalReflectionsBase);
  String get _keyPendingWrites => _scopedKey(_keyPendingWritesBase);
  String get _keyPendingDeletes => _scopedKey(_keyPendingDeletesBase);
  static const String _keyTombstonesBase = 'daily_reflections_deleted_tombstones';
  String get _keyTombstones => _scopedKey(_keyTombstonesBase);

  Future<Set<String>> _getTombstones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyTombstones) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _addTombstone(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyTombstones) ?? [];
      if (!list.contains(id)) {
        list.add(id);
        if (list.length > 2000) {
          list.removeRange(0, list.length - 2000);
        }
        await prefs.setStringList(_keyTombstones, list);
      }
    } catch (_) {}
  }

  final StreamController<List<ReflectionEntryModel>> _streamController =
      StreamController<List<ReflectionEntryModel>>.broadcast();

  // ── Sync Status ─────────────────────────────────────────────────
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastSyncError;
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  void _setSyncStatus(SyncStatus status, [String? error]) {
    _syncStatus = status;
    _lastSyncError = error;
    _syncStatusController.add(status);
  }

  SupabaseClient? get _client {
    if (_injectedClient != null) return _injectedClient;
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('[DatabaseService] Supabase client unavailable: $e');
      return null;
    }
  }

  String? get currentUserId => AuthService().currentUserId;

  bool get _isOnlineAndAuth {
    final client = _client;
    final user = AuthService().currentUser;
    return client != null && user != null && !AuthService().isLocalGuest;
  }

  /// Checks whether the device currently has active internet connectivity.
  Future<bool> hasInternetConnection({Duration timeout = const Duration(seconds: 2)}) async {
    if (kIsWeb) return true;
    try {
      final host = SupabaseConfig.isConfigured && SupabaseConfig.supabaseUrl.isNotEmpty
          ? Uri.parse(SupabaseConfig.supabaseUrl).host
          : 'google.com';
      final res = await InternetAddress.lookup(host)
          .timeout(timeout);
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
  // ── Account Isolation ────────────────────────────────────────

  /// Clears local cache and pending queues for the current user.
  /// MUST be called on sign-out to prevent data leaking to the next user.
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLocalReflections);
      await prefs.remove(_keyPendingWrites);
      await prefs.remove(_keyPendingDeletes);
      await prefs.remove(_keyTombstones);
      // Also clear legacy unscoped keys from before per-user scoping
      await prefs.remove(_keyLocalReflectionsBase);
      await prefs.remove(_keyPendingWritesBase);
      await prefs.remove(_keyPendingDeletesBase);
      await prefs.remove(_keyTombstonesBase);
      _streamController.add([]);
      _setSyncStatus(SyncStatus.idle);
      debugPrint('[DatabaseService] ✓ Local cache cleared for account isolation');
    } catch (e) {
      debugPrint('[DatabaseService] Failed to clear local cache: $e');
    }
  }

  /// Migration: non-destructively merges any legacy unscoped reflections into
  /// the current user-scoped storage key.
  Future<void> migrateUnscopedCache() async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final oldData = prefs.getStringList(_keyLocalReflectionsBase);
      final scopedKey = '${_keyLocalReflectionsBase}_$uid';
      final scopedData = prefs.getStringList(scopedKey) ?? [];

      if (oldData != null && oldData.isNotEmpty) {
        final seenIds = <String>{};
        final mergedRaw = <String>[];

        for (final item in scopedData) {
          try {
            final m = jsonDecode(item) as Map<String, dynamic>;
            final id = m['id']?.toString();
            if (id != null) seenIds.add(id);
          } catch (_) {}
          mergedRaw.add(item);
        }

        for (final item in oldData) {
          try {
            final m = jsonDecode(item) as Map<String, dynamic>;
            final id = m['id']?.toString();
            if (id != null && !seenIds.contains(id)) {
              seenIds.add(id);
              mergedRaw.add(item);
            }
          } catch (_) {}
        }

        await prefs.setStringList(scopedKey, mergedRaw);
        debugPrint('[DatabaseService] ✓ Merged ${oldData.length} unscoped entries into user-scoped cache');

        // Migrate pending writes too
        final oldWrites = prefs.getStringList(_keyPendingWritesBase) ?? [];
        if (oldWrites.isNotEmpty) {
          final scopedWritesKey = '${_keyPendingWritesBase}_$uid';
          final scopedWrites = prefs.getStringList(scopedWritesKey) ?? [];
          final combinedWrites = {...oldWrites, ...scopedWrites}.toList();
          await prefs.setStringList(scopedWritesKey, combinedWrites);
        }
      }

      // Track current user for future reference
      await prefs.setString(_keyLastUserId, uid);
    } catch (e) {
      debugPrint('[DatabaseService] Failed to migrate unscoped cache: $e');
    }
  }

  /// Deep scan across all SharedPreferences keys to recover any orphaned reflections
  /// (e.g. from prior guest sessions, unscoped storage, or interrupted migrations).
  /// Merges discovered entries into the current active cache safely.
  Future<int> recoverAllHistoricalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Find all keys that could contain reflections or pending reflections
      final candidateKeys = allKeys.where((k) =>
        k.startsWith(_keyLocalReflectionsBase) ||
        k.startsWith(_keyPendingWritesBase)
      ).toList();

      if (candidateKeys.isEmpty) return 0;

      final tombstones = await _getTombstones();
      final currentLocal = await _loadLocalEntries();
      final Map<String, ReflectionEntryModel> entryMap = {
        for (final e in currentLocal)
          if (!tombstones.contains(e.id)) e.id: e,
      };
      final initialCount = entryMap.length;

      // Extract entries from all candidate keys
      for (final key in candidateKeys) {
        List<String>? rawList;
        try {
          rawList = prefs.getStringList(key);
        } catch (_) {
          final single = prefs.getString(key);
          if (single != null && single.isNotEmpty) {
            try {
              final decoded = jsonDecode(single);
              if (decoded is List) {
                rawList = decoded.map((e) => jsonEncode(e)).toList();
              }
            } catch (_) {}
          }
        }

        if (rawList == null || rawList.isEmpty) continue;

        for (final raw in rawList) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final id = map['id']?.toString();
            if (id == null || id.isEmpty || tombstones.contains(id)) continue;

            final entry = ReflectionEntryModel.fromMap(map, id);
            final existing = entryMap[id];
            if (existing == null) {
              entryMap[id] = entry;
            } else if (entry.updatedAt.isAfter(existing.updatedAt)) {
              entryMap[id] = entry;
            }
          } catch (_) {
            // Skip unparseable item
          }
        }
      }

      final newlyRecovered = entryMap.length - initialCount;
      if (newlyRecovered > 0) {
        final mergedList = entryMap.values.toList();
        mergedList.sort((a, b) => b.date.compareTo(a.date));
        await _persistLocalEntries(mergedList);
        debugPrint('[DatabaseService] ✓ Auto-recovery restored $newlyRecovered orphaned entry/entries! Total now: ${mergedList.length}');
      }
      return newlyRecovered;
    } catch (e) {
      debugPrint('[DatabaseService] Error during auto-recovery: $e');
      return 0;
    }
  }

  // ── Local Storage Helpers (Isolate-Offloaded) ────────────────

  Future<List<ReflectionEntryModel>> _loadLocalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyLocalReflections) ?? [];
      if (rawList.isEmpty) return [];

      return await compute(parseEntriesFromJsonStrings, rawList);
    } catch (e) {
      debugPrint('[DatabaseService] Failed to load local entries: $e');
      return [];
    }
  }

  Future<void> _persistLocalEntries(List<ReflectionEntryModel> entries) async {
    try {
      final entryMaps = entries.map((e) {
        final map = e.toMap();
        map['id'] = e.id;
        return map;
      }).toList();

      final rawList = await compute(serializeEntriesToJsonStrings, entryMaps);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyLocalReflections, rawList);
      _streamController.add(entries);
    } catch (e) {
      debugPrint('[DatabaseService] Failed to persist local entries: $e');
    }
  }

  // ── Sync Queue Helpers ───────────────────────────────────────

  Future<void> _queueWrite(ReflectionEntryModel entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_keyPendingWrites) ?? [];
      final map = entry.toMap();
      map['id'] = entry.id;
      final encoded = jsonEncode(map);
      pending.removeWhere((item) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          return m['id'] == entry.id;
        } catch (_) {
          return false;
        }
      });
      pending.add(encoded);
      await prefs.setStringList(_keyPendingWrites, pending);
      _setSyncStatus(SyncStatus.pendingChanges);
      debugPrint('[DatabaseService] Queued write for entry ${entry.id} (${pending.length} total pending)');
    } catch (e) {
      debugPrint('[DatabaseService] Failed to queue write: $e');
    }
  }

  Future<void> _queueDelete(String docId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingDeletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      if (!pendingDeletes.contains(docId)) {
        pendingDeletes.add(docId);
        await prefs.setStringList(_keyPendingDeletes, pendingDeletes);
      }
      // Also remove from pending writes if present
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      pendingWrites.removeWhere((item) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          return m['id'] == docId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_keyPendingWrites, pendingWrites);
      _setSyncStatus(SyncStatus.pendingChanges);
      debugPrint('[DatabaseService] Queued delete for $docId');
    } catch (e) {
      debugPrint('[DatabaseService] Failed to queue delete: $e');
    }
  }

  /// Returns the number of pending writes and deletes waiting to be synced.
  Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final writes = prefs.getStringList(_keyPendingWrites) ?? [];
      final deletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      return writes.length + deletes.length;
    } catch (_) {
      return 0;
    }
  }

  /// Uploads an attached local photo to Supabase Storage bucket ('reflection_photos')
  /// and returns the public HTTP URL.
  Future<String?> uploadReflectionPhoto(String localPath, String entryId, String userId, {int index = 0}) async {
    if (!_isOnlineAndAuth) return null;
    final client = _client;
    if (client == null) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final filename = index == 0 ? '${entryId}_moment.jpg' : '${entryId}_moment_$index.jpg';
      final storagePath = '$userId/$filename';

      await client.storage.from('reflection_photos').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      ).timeout(const Duration(seconds: 15));

      final publicUrl = client.storage.from('reflection_photos').getPublicUrl(storagePath);
      debugPrint('[DatabaseService] ✓ Uploaded photo to Supabase storage: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Photo upload to storage failed: $e');
      return null;
    }
  }

  /// Scans local entries for any photos stored as local file paths on this device
  /// and uploads them to Supabase Storage, updating the cloud photo_url.
  Future<void> _uploadPendingLocalPhotos(String userId) async {
    if (!_isOnlineAndAuth) return;
    try {
      final entries = await _loadLocalEntries();
      bool modified = false;

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (entry.photoUrls.isEmpty) continue;

        List<String> newUrls = List.from(entry.photoUrls);
        bool entryModified = false;

        for (int p = 0; p < newUrls.length; p++) {
          final url = newUrls[p];
          if (url.isNotEmpty &&
              !url.startsWith('http://') &&
              !url.startsWith('https://')) {
            final file = File(url);
            if (file.existsSync()) {
              final cloudUrl = await uploadReflectionPhoto(url, entry.id, userId, index: p);
              if (cloudUrl != null && cloudUrl.isNotEmpty) {
                newUrls[p] = cloudUrl;
                entryModified = true;
              }
            }
          }
        }

        if (entryModified) {
          final updated = entry.copyWith(photoUrls: newUrls);
          entries[i] = updated;
          modified = true;

          // Also update Supabase database row with new photo_url
          try {
            final cloudPhotoUrl = newUrls.length > 1 ? jsonEncode(newUrls) : (newUrls.isNotEmpty ? newUrls.first : null);
            await _client!
                .from('reflections')
                .update({'photo_url': cloudPhotoUrl})
                .eq('id', entry.id)
                .eq('user_id', userId);
            debugPrint('[DatabaseService] ✓ Updated reflection ${entry.id} with cloud photo URLs in Supabase');
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Failed to update photo_url in reflections table: $e');
          }
        }
      }

      if (modified) {
        await _persistLocalEntries(entries);
      }
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Error uploading pending local photos: $e');
    }
  }

  /// Pushes any pending writes and deletes to Supabase (with client-side E2EE).
  Future<void> syncPendingChanges() async {
    final auth = AuthService();
    if (auth.isGuest || auth.currentUser == null) {
      _setSyncStatus(SyncStatus.notSignedIn);
      debugPrint('[DatabaseService] Sync skipped: user is not signed in to a cloud account');
      return;
    }

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Sync skipped: device has no internet connection');
      return;
    }

    final client = _client;
    final user = auth.currentUser;
    if (client == null || user == null) {
      _setSyncStatus(SyncStatus.error);
      debugPrint('[DatabaseService] Sync skipped: cloud client unavailable');
      return;
    }

    _setSyncStatus(SyncStatus.syncing);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 0. Upload any pending local photos to Supabase Storage
      await _uploadPendingLocalPhotos(user.id);

      // 1. Process pending deletes
      final pendingDeletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      if (pendingDeletes.isNotEmpty) {
        debugPrint('[DatabaseService] Processing ${pendingDeletes.length} pending deletes...');
        for (final id in List<String>.from(pendingDeletes)) {
          try {
            await client.from('reflections').delete().eq('id', id).eq('user_id', user.id);
            pendingDeletes.remove(id);
            debugPrint('[DatabaseService] ✓ Deleted $id from cloud');
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Failed to delete $id: $e');
            break; // Network issue, retry later
          }
        }
        await prefs.setStringList(_keyPendingDeletes, pendingDeletes);
      }

      // 2. Process pending writes (encrypt before uploading)
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      if (pendingWrites.isNotEmpty) {
        debugPrint('[DatabaseService] Processing ${pendingWrites.length} pending writes...');
        for (final item in List<String>.from(pendingWrites)) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final entry = ReflectionEntryModel.fromMap(map, map['id']?.toString() ?? '');
            final encryptedEntry = await _encryption.encryptEntry(entry);

            try {
              await client.from('reflections').upsert(
                encryptedEntry.toSupabaseMap(userId: user.id),
                onConflict: 'id',
              );
              pendingWrites.remove(item);
              debugPrint('[DatabaseService] ✓ Upserted pending entry ${entry.id} to cloud');
            } on PostgrestException catch (pe) {
              if (pe.code == '42501' ||
                  pe.message.contains('row-level security') ||
                  pe.message.contains('USING expression')) {
                debugPrint('[DatabaseService] 42501 on pending entry ${entry.id}. Attempting auto-rekey recovery...');
                final newId = generateUniqueId();
                final rekeyed = entry.copyWith(id: newId);
                final reEncrypted = await _encryption.encryptEntry(rekeyed);
                try {
                  await client.from('reflections').upsert(
                    reEncrypted.toSupabaseMap(userId: user.id),
                    onConflict: 'id',
                  );
                  final localEntries = await _loadLocalEntries();
                  final idx = localEntries.indexWhere((e) => e.id == entry.id);
                  if (idx >= 0) {
                    localEntries[idx] = rekeyed;
                    await _persistLocalEntries(localEntries);
                  }
                  pendingWrites.remove(item);
                  debugPrint('[DatabaseService] ✓ Auto-recovered and upserted rekeyed entry $newId');
                } catch (inner) {
                  debugPrint('[DatabaseService] ✗ Rekeyed entry also failed: $inner');
                  pendingWrites.remove(item);
                  continue;
                }
              } else {
                debugPrint('[DatabaseService] ✗ PostgrestException on pending entry: ${pe.message}');
                // Remove to prevent permanently jamming the queue due to schema errors
                pendingWrites.remove(item);
                continue;
              }
            }
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Failed to upsert pending entry (network?): $e');
            break;
          }
        }
        await prefs.setStringList(_keyPendingWrites, pendingWrites);
      }

      // 3. Fetch latest from Supabase with paginated batches, decrypt on device, and merge
      await _pullRemoteChanges();

      final remaining = await getPendingCount();
      if (remaining > 0) {
        _setSyncStatus(SyncStatus.pendingChanges);
      } else {
        _setSyncStatus(SyncStatus.synced);
      }
    } catch (e) {
      final formatted = formatSyncError(e);
      debugPrint('[DatabaseService] ✗ Sync failed: $formatted (original: $e)');
      _setSyncStatus(SyncStatus.error, formatted);
    }
  }

  /// Force a full sync cycle — intended for user-triggered refresh.
  /// Unlike [syncPendingChanges], this throws errors instead of swallowing them
  /// so the caller can show user-facing feedback.
  Future<void> forceSyncNow() async {
    final auth = AuthService();
    if (auth.isGuest || auth.currentUser == null) {
      _setSyncStatus(SyncStatus.notSignedIn);
      throw 'You are not signed in. Please sign in to your account to enable cloud sync.';
    }

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      _setSyncStatus(SyncStatus.offline);
      throw 'Network connection unavailable. Please check your internet connection and try again.';
    }

    final client = _client;
    final user = auth.currentUser;
    if (client == null || user == null) {
      _setSyncStatus(SyncStatus.error);
      throw 'Unable to sync with cloud right now. Please try again later.';
    }

    _setSyncStatus(SyncStatus.syncing);
    debugPrint('[DatabaseService] Force sync triggered by user');

    try {
      final prefs = await SharedPreferences.getInstance();

      // 0. Upload any pending local photos to Supabase Storage
      await _uploadPendingLocalPhotos(user.id);

      // 1. Process pending deletes
      final pendingDeletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      if (pendingDeletes.isNotEmpty) {
        for (final id in List<String>.from(pendingDeletes)) {
          await client.from('reflections').delete().eq('id', id).eq('user_id', user.id);
          pendingDeletes.remove(id);
          debugPrint('[DatabaseService] ✓ Force-synced delete: $id');
        }
        await prefs.setStringList(_keyPendingDeletes, pendingDeletes);
      }

      // 2. Process pending writes
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      if (pendingWrites.isNotEmpty) {
        for (final item in List<String>.from(pendingWrites)) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final entry = ReflectionEntryModel.fromMap(map, map['id']?.toString() ?? '');
          final encryptedEntry = await _encryption.encryptEntry(entry);

          try {
            await client.from('reflections').upsert(
              encryptedEntry.toSupabaseMap(userId: user.id),
              onConflict: 'id',
            );
            pendingWrites.remove(item);
            debugPrint('[DatabaseService] ✓ Force-synced write: ${entry.id}');
              } on PostgrestException catch (pe) {
                if (pe.code == '42501' ||
                    pe.message.contains('row-level security') ||
                    pe.message.contains('USING expression')) {
                  debugPrint('[DatabaseService] Force sync 42501 on ${entry.id}. Attempting auto-rekey...');
                  final newId = generateUniqueId();
                  final rekeyed = entry.copyWith(id: newId);
                  final reEncrypted = await _encryption.encryptEntry(rekeyed);
                  try {
                    await client.from('reflections').upsert(
                      reEncrypted.toSupabaseMap(userId: user.id),
                      onConflict: 'id',
                    );
                    final localEntries = await _loadLocalEntries();
                    final idx = localEntries.indexWhere((e) => e.id == entry.id);
                    if (idx >= 0) {
                      localEntries[idx] = rekeyed;
                      await _persistLocalEntries(localEntries);
                    }
                    pendingWrites.remove(item);
                    debugPrint('[DatabaseService] ✓ Auto-recovered and force-synced rekeyed entry $newId');
                  } catch (inner) {
                    pendingWrites.remove(item);
                    continue;
                  }
                } else {
                  debugPrint('[DatabaseService] ✗ PostgrestException on force sync: ${pe.message}');
                  pendingWrites.remove(item);
                  continue;
                }
              }
        }
        await prefs.setStringList(_keyPendingWrites, pendingWrites);
      }

      // 3. Full remote pull
      await _pullRemoteChanges(maxPages: 20);

      _setSyncStatus(SyncStatus.synced);
      debugPrint('[DatabaseService] ✓ Force sync completed successfully');
    } catch (e) {
      final formatted = formatSyncError(e);
      debugPrint('[DatabaseService] ✗ Force sync failed: $formatted (original: $e)');
      _setSyncStatus(SyncStatus.error, formatted);
      throw formatted;
    }
  }

  /// Formats synchronization errors into helpful, human-readable guidance.
  String formatSyncError(Object e) {
    return ErrorFormatter.format(e);
  }

  /// Pulls remote reflections from Supabase using paginated batches (pageSize: 50),
  /// decrypts on-device, and merges into local repository.
  Future<void> _pullRemoteChanges({
    int pageSize = defaultPageSize,
    int maxPages = 10,
  }) async {
    if (!_isOnlineAndAuth) return;
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) return;

    try {
      final remoteEntries = <ReflectionEntryModel>[];
      int page = 0;
      bool hasMore = true;

      debugPrint('[DatabaseService] Pulling remote changes for user ${user.id}...');

      while (hasMore && page < maxPages) {
        final from = page * pageSize;
        final to = from + pageSize - 1;

        final response = await client
            .from('reflections')
            .select()
            .eq('user_id', user.id)
            .order('date', ascending: false)
            .range(from, to);

        final remoteRows = response as List;
        debugPrint('[DatabaseService] Page $page: fetched ${remoteRows.length} rows');

        if (remoteRows.isEmpty) {
          hasMore = false;
          break;
        }

        for (final row in remoteRows) {
          try {
            final rawEntry = ReflectionEntryModel.fromSupabase(row as Map<String, dynamic>);
            final decryptedEntry = await _encryption.decryptEntry(rawEntry);
            remoteEntries.add(decryptedEntry);
          } catch (e) {
            debugPrint('[DatabaseService] Failed to decrypt remote entry: $e');
          }
        }

        if (remoteRows.length < pageSize) {
          hasMore = false;
        } else {
          page++;
        }
      }

      debugPrint('[DatabaseService] Total remote entries pulled: ${remoteEntries.length}');

      final tombstones = await _getTombstones();
      final localEntries = await _loadLocalEntries();
      final map = <String, ReflectionEntryModel>{};

      // Collect IDs of pending deletions and writes
      final prefs = await SharedPreferences.getInstance();
      final pendingDeletes = (prefs.getStringList(_keyPendingDeletes) ?? []).toSet();
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      final pendingWriteIds = <String>{};
      for (final item in pendingWrites) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          if (m['id'] != null) pendingWriteIds.add(m['id'].toString());
        } catch (_) {}
      }

      // Preserve existing local entries that aren't marked for permanent deletion or tombstoned
      for (final e in localEntries) {
        if (!pendingDeletes.contains(e.id) && !tombstones.contains(e.id)) {
          map[e.id] = e;
        }
      }

      final missingOnRemote = <ReflectionEntryModel>[];

      // Merge remote entries into local cache
      for (final remote in remoteEntries) {
        if (pendingDeletes.contains(remote.id) || tombstones.contains(remote.id)) {
          // If remote cloud still holds this entry but it was permanently deleted locally,
          // purge it from cloud
          unawaited(client.from('reflections').delete().eq('id', remote.id).eq('user_id', user.id));
          continue;
        }

        final existing = map[remote.id];
        if (existing == null) {
          // New entry from remote device (could be active or soft-deleted in recycle bin)
          map[remote.id] = remote;
        } else if (pendingWriteIds.contains(remote.id)) {
          // Device has pending local edit queued for push; keep local version
          map[remote.id] = existing;
        } else {
          // Both exist: check soft-delete state and last-write-wins (LWW)
          if (remote.isDeleted && !existing.isDeleted) {
            // Remotely soft-deleted on another device -> sync to local Recycle Bin!
            map[remote.id] = remote;
          } else if (existing.isDeleted && !remote.isDeleted) {
            // Locally soft-deleted on this device: preserve local delete unless remote was updated strictly after deletion
            final localDeletedTime = existing.deletedAt ?? existing.updatedAt;
            if (remote.updatedAt.isAfter(localDeletedTime)) {
              map[remote.id] = remote;
            } else {
              map[remote.id] = existing;
              missingOnRemote.add(existing);
            }
          } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
            // Remote is newer
            map[remote.id] = remote;
          } else if (existing.updatedAt.isAfter(remote.updatedAt)) {
            // Local is newer
            map[remote.id] = existing;
            missingOnRemote.add(existing);
          } else {
            // Timestamps tie: prefer whichever has soft-delete info
            map[remote.id] = remote.isDeleted ? remote : existing;
          }
        }
      }

      // Find any local entries missing from remote cloud
      final remoteIdSet = remoteEntries.map((e) => e.id).toSet();
      for (final local in localEntries) {
        if (pendingDeletes.contains(local.id) || tombstones.contains(local.id)) {
          continue;
        }
        if (!remoteIdSet.contains(local.id)) {
          if (local.isDeleted && !pendingWriteIds.contains(local.id)) {
            // It was in the Recycle Bin locally, but no longer exists on Supabase,
            // and has no pending delete/write queued -> it was permanently purged on another device!
            // Remove it locally and tombstone it so it never resurrects!
            map.remove(local.id);
            await _addTombstone(local.id);
          } else if (!local.isDeleted || pendingWriteIds.contains(local.id)) {
            missingOnRemote.add(local);
          }
        }
      }

      // Two-way sync: push any un-synced local reflections (including un-synced Recycle Bin items!)
      if (missingOnRemote.isNotEmpty) {
        debugPrint('[DatabaseService] Auto-syncing ${missingOnRemote.length} un-synced local entries (including recycle bin) to cloud...');
        for (final item in missingOnRemote) {
          try {
            final encrypted = await _encryption.encryptEntry(item);
            await client.from('reflections').upsert(
              encrypted.toSupabaseMap(userId: user.id),
              onConflict: 'id',
            );
            debugPrint('[DatabaseService] ✓ Auto-synced entry ${item.id} (isDeleted: ${item.isDeleted}) to cloud');
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Failed to auto-sync entry ${item.id}: $e');
          }
        }
      }

      final merged = map.values.toList();
      merged.sort((a, b) => b.date.compareTo(a.date));
      await _persistLocalEntries(merged);
      debugPrint('[DatabaseService] Synced and merged ${merged.length} total entries (${localEntries.length} local, ${remoteEntries.length} remote)');
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Pull remote changes failed: $e');
      rethrow;
    }
  }

  /// Fetches a specific paginated window of reflections from Supabase on demand.
  Future<List<ReflectionEntryModel>> fetchRemotePage({
    int page = 0,
    int pageSize = defaultPageSize,
  }) async {
    if (!_isOnlineAndAuth) return [];
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) return [];

    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await client
          .from('reflections')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .range(from, to);

      final rows = response as List;
      final entries = <ReflectionEntryModel>[];

      for (final row in rows) {
        try {
          final rawEntry = ReflectionEntryModel.fromSupabase(row as Map<String, dynamic>);
          final decrypted = await _encryption.decryptEntry(rawEntry);
          entries.add(decrypted);
        } catch (e) {
          debugPrint('[DatabaseService] Failed to decrypt remote entry in fetchRemotePage: $e');
        }
      }

      return entries;
    } catch (e) {
      debugPrint('[DatabaseService] Failed to fetch remote page $page: $e');
      return [];
    }
  }

  // ── Public CRUD Methods ──────────────────────────────────────

  static int _idCounter = 0;

  /// Generates a unique document ID guaranteed to be scoped to the authenticated user.
  static String generateUniqueId() {
    final user = AuthService().currentUser;
    final userPrefix = user != null ? '${user.id.substring(0, 8)}_' : '';
    final counter = (++_idCounter) % 100000;
    return '$userPrefix${DateTime.now().microsecondsSinceEpoch}_$counter';
  }

  /// Save or update a reflection (instant local save + background E2EE cloud sync).
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    final user = AuthService().currentUser;
    final docId = entry.id.isNotEmpty
        ? entry.id
        : generateUniqueId();

    // Sanitize and cap field lengths to prevent layout breaking or excessive payloads
    final sanitizedTitle = entry.freeformTitle != null
        ? (entry.freeformTitle!.length > 120 ? entry.freeformTitle!.substring(0, 120) : entry.freeformTitle)
        : null;
    final sanitizedNote = entry.freeformNote != null
        ? (entry.freeformNote!.length > 10000 ? entry.freeformNote!.substring(0, 10000) : entry.freeformNote)
        : null;
    final sanitizedAnswers = entry.answers.map((k, v) => MapEntry(
      k,
      v.length > 3000 ? v.substring(0, 3000) : v,
    ));

    final now = DateTime.now();
    final entryWithId = ReflectionEntryModel(
      id: docId,
      date: entry.date,
      mood: entry.mood,
      moodEmoji: entry.moodEmoji,
      answers: sanitizedAnswers,
      freeformTitle: sanitizedTitle,
      freeformNote: sanitizedNote,
      photoUrls: entry.photoUrls,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      isDeleted: entry.isDeleted,
      deletedAt: entry.deletedAt,
      createdAt: entry.createdAt,
      updatedAt: now,
      tags: entry.tags,
    );

    // 1. Instant local update (0ms UI latency, cleartext locally for speed)
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      entries[index] = entryWithId;
    } else {
      entries.insert(0, entryWithId);
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    await _persistLocalEntries(entries);
    debugPrint('[DatabaseService] ✓ Saved entry $docId locally');

    // 2. Cloud sync management
    if (AuthService().isGuest || user == null) {
      _setSyncStatus(SyncStatus.notSignedIn);
      debugPrint('[DatabaseService] Saved locally in guest mode');
      return;
    }

    // Always queue the write first so it is safely persisted for background sync
    await _queueWrite(entryWithId);

    // 3. Trigger background sync without blocking the caller UI
    unawaited(_syncSingleEntryInBackground(entryWithId, user));
  }

  /// Background task to upload photos and push an encrypted entry to Supabase without blocking UI.
  Future<void> _syncSingleEntryInBackground(ReflectionEntryModel entry, User user) async {
    final client = _client;
    if (client == null) return;

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Offline — entry ${entry.id} stays queued for cloud sync');
      return;
    }

    try {
      _setSyncStatus(SyncStatus.syncing);

      // Upload local photos to cloud storage if any
      List<String> effectivePhotoUrls = List.from(entry.photoUrls);
      bool photoUploaded = false;
      for (int i = 0; i < effectivePhotoUrls.length; i++) {
        final path = effectivePhotoUrls[i];
        if (path.isNotEmpty &&
            !path.startsWith('http://') &&
            !path.startsWith('https://')) {
          final cloudUrl = await uploadReflectionPhoto(path, entry.id, user.id, index: i);
          if (cloudUrl != null && cloudUrl.isNotEmpty) {
            effectivePhotoUrls[i] = cloudUrl;
            photoUploaded = true;
          }
        }
      }

      final entryToPush = photoUploaded
          ? entry.copyWith(photoUrls: effectivePhotoUrls)
          : entry;

      if (photoUploaded) {
        final currentEntries = await _loadLocalEntries();
        final idx = currentEntries.indexWhere((e) => e.id == entry.id);
        if (idx >= 0) {
          currentEntries[idx] = entryToPush;
          await _persistLocalEntries(currentEntries);
        }
      }

      final encrypted = await _encryption.encryptEntry(entryToPush);
      await client.from('reflections').upsert(
        encrypted.toSupabaseMap(userId: user.id),
        onConflict: 'id',
      ).timeout(const Duration(seconds: 10));

      await _removePendingWrite(entry.id);
      debugPrint('[DatabaseService] ✓ Background pushed entry ${entry.id} to Supabase cloud');
      _setSyncStatus(SyncStatus.synced);
    } on PostgrestException catch (pe) {
      if ((pe.code == '42501' ||
              pe.message.contains('row-level security') ||
              pe.message.contains('USING expression'))) {
        debugPrint('[DatabaseService] 42501 on save ${entry.id}. Auto-rekeying with user prefix...');
        final newId = generateUniqueId();
        final rekeyed = entry.copyWith(id: newId);
        final reEncrypted = await _encryption.encryptEntry(rekeyed);
        try {
          await client.from('reflections').upsert(
            reEncrypted.toSupabaseMap(userId: user.id),
            onConflict: 'id',
          ).timeout(const Duration(seconds: 10));
          final currentEntries = await _loadLocalEntries();
          final idx = currentEntries.indexWhere((e) => e.id == entry.id);
          if (idx >= 0) {
            currentEntries[idx] = rekeyed;
            await _persistLocalEntries(currentEntries);
          }
          await _removePendingWrite(entry.id);
          debugPrint('[DatabaseService] ✓ Auto-recovered and pushed rekeyed entry $newId');
          _setSyncStatus(SyncStatus.synced);
        } catch (e) {
          debugPrint('[DatabaseService] ✗ Cloud push failed for rekeyed entry $newId: $e');
          await _queueWrite(rekeyed);
          _scheduleRetrySync();
        }
      } else {
        debugPrint('[DatabaseService] ✗ Cloud push failed for ${entry.id}, keeping queued: $pe');
        _scheduleRetrySync();
      }
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Background sync failed for ${entry.id}, keeping queued: $e');
      _scheduleRetrySync();
    }
  }

  /// Stream of reflections, emitting initial cached entries and updates.
  Stream<List<ReflectionEntryModel>> streamReflections() async* {
    await recoverAllHistoricalEntries();
    final initial = await _loadLocalEntries();
    yield initial;

    // Trigger background sync when stream is listened
    final auth = AuthService();
    if (auth.isGuest || auth.currentUser == null) {
      _setSyncStatus(SyncStatus.notSignedIn);
    } else {
      unawaited(syncPendingChanges());
    }

    yield* _streamController.stream;
  }

  /// Toggle bookmark for a given reflection document.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final updated = old.copyWith(
        isBookmarked: !currentBookmark,
        updatedAt: DateTime.now(),
      );
      entries[index] = updated;
      await _persistLocalEntries(entries);

      final user = AuthService().currentUser;
      if (AuthService().isGuest || user == null) return;

      await _queueWrite(updated);
      unawaited(_syncSingleEntryInBackground(updated, user));
    }
  }

  Future<void> _removePendingWrite(String docId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      pendingWrites.removeWhere((item) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          return m['id'] == docId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_keyPendingWrites, pendingWrites);
    } catch (_) {}
  }

  Future<void> _removePendingDelete(String docId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingDeletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      pendingDeletes.remove(docId);
      await prefs.setStringList(_keyPendingDeletes, pendingDeletes);
    } catch (_) {}
  }

  /// Moves a reflection to the Recycle Bin (Soft Delete with cross-device sync).
  Future<void> deleteReflection(String docId) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final now = DateTime.now();
      final trashed = old.copyWith(
        isDeleted: true,
        deletedAt: now,
        updatedAt: now,
      );
      entries[index] = trashed;
      await _persistLocalEntries(entries);
      await _removePendingWrite(docId);

      final user = AuthService().currentUser;
      if (AuthService().isGuest || user == null) {
        _setSyncStatus(SyncStatus.notSignedIn);
        return;
      }

      await _queueWrite(trashed);
      unawaited(_syncSoftDeleteInBackground(trashed, user));
    }
  }

  Future<void> _syncSoftDeleteInBackground(ReflectionEntryModel trashed, User user) async {
    final client = _client;
    if (client == null) return;

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Offline — soft delete for ${trashed.id} stays queued');
      return;
    }

    try {
      _setSyncStatus(SyncStatus.syncing);
      final encrypted = await _encryption.encryptEntry(trashed);
      await client.from('reflections').upsert(
        encrypted.toSupabaseMap(userId: user.id),
        onConflict: 'id',
      ).timeout(const Duration(seconds: 10));
      await _removePendingWrite(trashed.id);
      debugPrint('[DatabaseService] ✓ Moved reflection ${trashed.id} to Recycle Bin in cloud');
      _setSyncStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Recycle Bin cloud sync failed for ${trashed.id}, keeping queued: $e');
      _scheduleRetrySync();
    }
  }

  /// Restores a reflection from the Recycle Bin back to the active journal.
  Future<void> restoreReflection(String docId) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final now = DateTime.now();
      final restored = old.copyWith(
        isDeleted: false,
        clearDeletedAt: true,
        updatedAt: now,
      );
      entries[index] = restored;
      await _persistLocalEntries(entries);
      await _removePendingWrite(docId);

      final user = AuthService().currentUser;
      if (AuthService().isGuest || user == null) {
        _setSyncStatus(SyncStatus.notSignedIn);
        return;
      }

      await _queueWrite(restored);
      unawaited(_syncSingleEntryInBackground(restored, user));
    }
  }

  /// Permanently deletes a reflection document from local storage and cloud.
  Future<void> permanentlyDeleteReflection(String docId) async {
    // 1. Record tombstone immediately so it can never be resurrected
    await _addTombstone(docId);

    // 2. Remove from active cache and pending write queue
    final entries = await _loadLocalEntries();
    entries.removeWhere((e) => e.id == docId);
    await _persistLocalEntries(entries);
    await _removePendingWrite(docId);

    // 3. Purge docId from all candidate keys in SharedPreferences (including legacy unscoped keys)
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_keyLocalReflectionsBase) || key.startsWith(_keyPendingWritesBase)) {
          final list = prefs.getStringList(key);
          if (list != null) {
            final updated = list.where((item) {
              try {
                final m = jsonDecode(item) as Map<String, dynamic>;
                return m['id'] != docId;
              } catch (_) {
                return true;
              }
            }).toList();
            if (updated.length != list.length) {
              await prefs.setStringList(key, updated);
            }
          }
        }
      }
    } catch (_) {}

    final user = AuthService().currentUser;
    if (AuthService().isGuest || user == null) return;

    await _queueDelete(docId);
    unawaited(_syncPermanentDeleteInBackground(docId, user));
  }

  Future<void> _syncPermanentDeleteInBackground(String docId, User user) async {
    final client = _client;
    if (client == null) return;

    final isOnline = await hasInternetConnection();
    if (!isOnline) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Offline — permanent delete for $docId stays queued');
      return;
    }

    try {
      _setSyncStatus(SyncStatus.syncing);
      await client.from('reflections').delete().eq('id', docId).eq('user_id', user.id).timeout(const Duration(seconds: 10));
      await _removePendingDelete(docId);
      debugPrint('[DatabaseService] ✓ Permanently deleted $docId from cloud');
      _setSyncStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('[DatabaseService] ✗ Permanent cloud delete failed for $docId, keeping queued: $e');
      _scheduleRetrySync();
    }
  }

  /// Permanently deletes all items in the Recycle Bin.
  Future<void> emptyTrash() async {
    final entries = await _loadLocalEntries();
    final trashed = entries.where((e) => e.isDeleted).toList();
    if (trashed.isEmpty) return;

    for (final e in trashed) {
      await permanentlyDeleteReflection(e.id);
    }
  }

  /// Fetch the most recent reflection before today (for "Yesterday's Summary").
  Future<ReflectionEntryModel?> getYesterdayOrLatestReflection() async {
    final entries = await _loadLocalEntries();
    if (entries.isEmpty) return null;

    final now = DateTime.now();
    for (final entry in entries) {
      final isToday = entry.date.year == now.year &&
          entry.date.month == now.month &&
          entry.date.day == now.day;
      if (!isToday) {
        return entry;
      }
    }
    return entries.first;
  }

  // ── Retry Logic ─────────────────────────────────────────────────

  Timer? _retryTimer;
  int _retryAttempt = 0;

  void _scheduleRetrySync() {
    _retryTimer?.cancel();
    _retryAttempt++;
    // Exponential backoff: 5s, 10s, 20s, 40s, max 60s
    final delaySeconds = min(5 * pow(2, _retryAttempt - 1).toInt(), 60);
    debugPrint('[DatabaseService] Scheduling retry sync in ${delaySeconds}s (attempt $_retryAttempt)');
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isOnlineAndAuth) {
        syncPendingChanges().then((_) {
          if (_syncStatus == SyncStatus.synced) {
            _retryAttempt = 0;
          }
        });
      }
    });
  }
}
