import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/encryption_service.dart';
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
  /// User is offline or not authenticated — cloud sync is disabled.
  offline,
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

  static const String _keyLocalReflections = 'daily_reflections_local_cache';
  static const String _keyPendingWrites = 'daily_reflections_pending_writes';
  static const String _keyPendingDeletes = 'daily_reflections_pending_deletes';
  static const int defaultPageSize = 50;

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
  Future<String?> uploadReflectionPhoto(String localPath, String entryId, String userId) async {
    if (!_isOnlineAndAuth) return null;
    final client = _client;
    if (client == null) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final filename = '${entryId}_moment.jpg';
      final storagePath = '$userId/$filename';

      await client.storage.from('reflection_photos').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

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
        if (entry.photoUrl != null &&
            entry.photoUrl!.isNotEmpty &&
            !entry.photoUrl!.startsWith('http://') &&
            !entry.photoUrl!.startsWith('https://')) {
          final file = File(entry.photoUrl!);
          if (file.existsSync()) {
            final cloudUrl = await uploadReflectionPhoto(entry.photoUrl!, entry.id, userId);
            if (cloudUrl != null && cloudUrl.isNotEmpty) {
              final updated = entry.copyWith(photoUrl: cloudUrl);
              entries[i] = updated;
              modified = true;

              // Also update Supabase database row with new photo_url
              try {
                await _client!
                    .from('reflections')
                    .update({'photo_url': cloudUrl})
                    .eq('id', entry.id)
                    .eq('user_id', userId);
                debugPrint('[DatabaseService] ✓ Updated reflection ${entry.id} with cloud photo URL in Supabase');
              } catch (e) {
                debugPrint('[DatabaseService] ✗ Failed to update photo_url in reflections table: $e');
              }
            }
          }
        }
      }

      if (modified) {
        await _persistLocalEntries(entries);
      }
    } catch (e) {
      debugPrint('[DatabaseService] Error in _uploadPendingLocalPhotos: $e');
    }
  }

  /// Pushes any pending writes and deletes to Supabase (with client-side E2EE).
  Future<void> syncPendingChanges() async {
    if (!_isOnlineAndAuth) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Sync skipped: offline or not authenticated (isLocalGuest=${AuthService().isLocalGuest}, currentUser=${AuthService().currentUser?.id})');
      return;
    }
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) {
      _setSyncStatus(SyncStatus.offline);
      debugPrint('[DatabaseService] Sync skipped: client=$client, user=$user');
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
                  // Remove to prevent permanently jamming the queue
                  pendingWrites.remove(item);
                  break;
                }
              } else {
                rethrow;
              }
            }
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Failed to upsert pending entry: $e');
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
    if (!_isOnlineAndAuth) {
      _setSyncStatus(SyncStatus.offline);
      throw 'You are offline or not signed in. Please sign in with your email to enable cloud sync.';
    }
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) {
      _setSyncStatus(SyncStatus.offline);
      throw 'Cloud connection unavailable. Please check your internet connection.';
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
                await prefs.setStringList(_keyPendingWrites, pendingWrites);
                throw formatSyncError(inner);
              }
            } else {
              rethrow;
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
    final str = e.toString();
    if (str.contains('PGRST204') ||
        str.contains('schema cache') ||
        str.contains('Could not find the') ||
        str.contains('column of')) {
      return 'Database schema missing columns. Please run db/fix_rls_error.sql in your Supabase SQL Editor.';
    }
    if (str.contains('42501') ||
        str.contains('row-level security') ||
        str.contains('USING expression') ||
        str.contains('Forbidden')) {
      return 'Database permission error (42501): Supabase RLS policy violation. Please run db/fix_rls_error.sql in your Supabase SQL Editor.';
    }
    if (str.contains('SocketException') ||
        str.contains('Failed host lookup') ||
        str.contains('Network') ||
        str.contains('ClientException')) {
      return 'Network connection unavailable. Please check your internet connection.';
    }
    if (str.contains('AuthException') ||
        str.contains('invalid_token') ||
        str.contains('JWT') ||
        str.contains('expired')) {
      return 'Session expired. Please sign out and sign back in to continue syncing.';
    }
    return str;
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

      final localEntries = await _loadLocalEntries();
      final map = <String, ReflectionEntryModel>{};

      // If we successfully pulled the complete ground-truth dataset from cloud
      if (!hasMore) {
        // Collect IDs of pending local writes so we don't accidentally remove offline creations
        final prefs = await SharedPreferences.getInstance();
        final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
        final pendingIds = <String>{};
        for (final item in pendingWrites) {
          try {
            final m = jsonDecode(item) as Map<String, dynamic>;
            if (m['id'] != null) pendingIds.add(m['id'].toString());
          } catch (_) {}
        }

        final remoteIds = remoteEntries.map((e) => e.id).toSet();
        for (final e in localEntries) {
          if (remoteIds.contains(e.id) || pendingIds.contains(e.id)) {
            map[e.id] = e;
          } else {
            debugPrint('[DatabaseService] Reconciled remotely deleted entry ${e.id}');
          }
        }
        for (final e in remoteEntries) {
          map[e.id] = e;
        }
        final merged = map.values.toList();
        merged.sort((a, b) => b.date.compareTo(a.date));
        await _persistLocalEntries(merged);
        debugPrint('[DatabaseService] Reconciled ${merged.length} total entries (${localEntries.length} local -> ${merged.length})');
      } else if (remoteEntries.isNotEmpty) {
        // Fallback for very large datasets if pagination was truncated
        for (final e in localEntries) {
          map[e.id] = e;
        }
        for (final e in remoteEntries) {
          map[e.id] = e;
        }
        final merged = map.values.toList();
        merged.sort((a, b) => b.date.compareTo(a.date));
        await _persistLocalEntries(merged);
        debugPrint('[DatabaseService] Merged ${merged.length} total entries (${localEntries.length} local + ${remoteEntries.length} remote)');
      }
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

    // If photo is a local file, upload to Supabase Storage for multi-device sync
    String? effectivePhotoUrl = entry.photoUrl;
    if (_isOnlineAndAuth &&
        user != null &&
        effectivePhotoUrl != null &&
        effectivePhotoUrl.isNotEmpty &&
        !effectivePhotoUrl.startsWith('http://') &&
        !effectivePhotoUrl.startsWith('https://')) {
      final cloudUrl = await uploadReflectionPhoto(effectivePhotoUrl, docId, user.id);
      if (cloudUrl != null && cloudUrl.isNotEmpty) {
        effectivePhotoUrl = cloudUrl;
      }
    }

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

    final entryWithId = ReflectionEntryModel(
      id: docId,
      date: entry.date,
      mood: entry.mood,
      moodEmoji: entry.moodEmoji,
      answers: sanitizedAnswers,
      freeformTitle: sanitizedTitle,
      freeformNote: sanitizedNote,
      photoUrl: effectivePhotoUrl,
      isBookmarked: entry.isBookmarked,
      type: entry.type,
      isDeleted: entry.isDeleted,
      deletedAt: entry.deletedAt,
      createdAt: entry.createdAt,
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

    // 2. Push encrypted payload to Supabase immediately, or queue for later
    if (_isOnlineAndAuth) {
      try {
        final encrypted = await _encryption.encryptEntry(entryWithId);
        await _client!.from('reflections').upsert(
          encrypted.toSupabaseMap(userId: user?.id),
          onConflict: 'id',
        );
        debugPrint('[DatabaseService] ✓ Pushed entry $docId to Supabase cloud');
        _setSyncStatus(SyncStatus.synced);
      } on PostgrestException catch (pe) {
        if ((pe.code == '42501' ||
                pe.message.contains('row-level security') ||
                pe.message.contains('USING expression')) &&
            user != null) {
          debugPrint('[DatabaseService] 42501 on save $docId. Auto-rekeying with user prefix...');
          final newId = generateUniqueId();
          final rekeyed = entryWithId.copyWith(id: newId);
          final reEncrypted = await _encryption.encryptEntry(rekeyed);
          try {
            await _client!.from('reflections').upsert(
              reEncrypted.toSupabaseMap(userId: user.id),
              onConflict: 'id',
            );
            final currentEntries = await _loadLocalEntries();
            final idx = currentEntries.indexWhere((e) => e.id == docId);
            if (idx >= 0) {
              currentEntries[idx] = rekeyed;
              await _persistLocalEntries(currentEntries);
            }
            debugPrint('[DatabaseService] ✓ Auto-recovered and pushed rekeyed entry $newId');
            _setSyncStatus(SyncStatus.synced);
          } catch (e) {
            debugPrint('[DatabaseService] ✗ Cloud push failed for rekeyed entry $newId: $e');
            await _queueWrite(rekeyed);
            _scheduleRetrySync();
          }
        } else {
          debugPrint('[DatabaseService] ✗ Cloud push failed for $docId, queuing: $pe');
          await _queueWrite(entryWithId);
          _scheduleRetrySync();
        }
      } catch (e) {
        debugPrint('[DatabaseService] ✗ Cloud push failed for $docId, queuing: $e');
        await _queueWrite(entryWithId);
        _scheduleRetrySync();
      }
    } else {
      debugPrint('[DatabaseService] Offline — queuing entry $docId for later sync');
      await _queueWrite(entryWithId);
    }
  }

  /// Stream of reflections, emitting initial cached entries and updates.
  Stream<List<ReflectionEntryModel>> streamReflections() async* {
    final initial = await _loadLocalEntries();
    yield initial;

    // Trigger background sync when stream is listened
    if (_isOnlineAndAuth) {
      unawaited(syncPendingChanges());
    } else {
      _setSyncStatus(SyncStatus.offline);
    }

    yield* _streamController.stream;
  }

  /// Toggle bookmark for a given reflection document.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final updated = old.copyWith(isBookmarked: !currentBookmark);
      entries[index] = updated;
      await _persistLocalEntries(entries);

      if (_isOnlineAndAuth) {
        try {
          await _client!
              .from('reflections')
              .update({'is_bookmarked': !currentBookmark}).eq('id', docId);
          debugPrint('[DatabaseService] ✓ Updated bookmark for $docId in cloud');
        } catch (e) {
          debugPrint('[DatabaseService] ✗ Bookmark cloud update failed: $e');
          await _queueWrite(updated);
        }
      } else {
        await _queueWrite(updated);
      }
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

  /// Moves a reflection to the Recycle Bin (Soft Delete with cross-device sync).
  Future<void> deleteReflection(String docId) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final trashed = old.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      entries[index] = trashed;
      await _persistLocalEntries(entries);
      await _removePendingWrite(docId);

      if (_isOnlineAndAuth) {
        try {
          final user = AuthService().currentUser;
          final encrypted = await _encryption.encryptEntry(trashed);
          await _client!.from('reflections').upsert(
            encrypted.toSupabaseMap(userId: user?.id),
            onConflict: 'id',
          );
          debugPrint('[DatabaseService] ✓ Moved reflection $docId to Recycle Bin in cloud');
          _setSyncStatus(SyncStatus.synced);
        } catch (e) {
          debugPrint('[DatabaseService] ✗ Recycle Bin cloud sync failed for $docId, queuing: $e');
          await _queueWrite(trashed);
          _scheduleRetrySync();
        }
      } else {
        debugPrint('[DatabaseService] Offline — queuing soft delete for $docId');
        await _queueWrite(trashed);
      }
    }
  }

  /// Restores a reflection from the Recycle Bin back to the active journal.
  Future<void> restoreReflection(String docId) async {
    final entries = await _loadLocalEntries();
    final index = entries.indexWhere((e) => e.id == docId);
    if (index >= 0) {
      final old = entries[index];
      final restored = old.copyWith(
        isDeleted: false,
        clearDeletedAt: true,
      );
      entries[index] = restored;
      await _persistLocalEntries(entries);
      await _removePendingWrite(docId);

      if (_isOnlineAndAuth) {
        try {
          final user = AuthService().currentUser;
          final encrypted = await _encryption.encryptEntry(restored);
          await _client!.from('reflections').upsert(
            encrypted.toSupabaseMap(userId: user?.id),
            onConflict: 'id',
          );
          debugPrint('[DatabaseService] ✓ Restored reflection $docId in cloud');
          _setSyncStatus(SyncStatus.synced);
        } catch (e) {
          debugPrint('[DatabaseService] ✗ Restore cloud sync failed for $docId, queuing: $e');
          await _queueWrite(restored);
          _scheduleRetrySync();
        }
      } else {
        await _queueWrite(restored);
      }
    }
  }

  /// Permanently deletes a reflection document from local storage and cloud.
  Future<void> permanentlyDeleteReflection(String docId) async {
    final entries = await _loadLocalEntries();
    entries.removeWhere((e) => e.id == docId);
    await _persistLocalEntries(entries);
    await _removePendingWrite(docId);

    if (_isOnlineAndAuth) {
      try {
        final user = AuthService().currentUser;
        if (user != null) {
          await _client!.from('reflections').delete().eq('id', docId).eq('user_id', user.id);
        } else {
          await _client!.from('reflections').delete().eq('id', docId);
        }
        debugPrint('[DatabaseService] ✓ Permanently deleted $docId from cloud');
      } catch (e) {
        debugPrint('[DatabaseService] ✗ Permanent cloud delete failed for $docId: $e');
        await _queueDelete(docId);
      }
    } else {
      await _queueDelete(docId);
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

  /// Clears local reflections cache on account switch/sign out.
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLocalReflections);
      await prefs.remove(_keyPendingWrites);
      await prefs.remove(_keyPendingDeletes);
      _streamController.add([]);
      _setSyncStatus(SyncStatus.idle);
      debugPrint('[DatabaseService] Local cache cleared');
    } catch (e) {
      debugPrint('[DatabaseService] Failed to clear local cache: $e');
    }
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
