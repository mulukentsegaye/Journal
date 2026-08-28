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

            await client.from('reflections').upsert(
              encryptedEntry.toSupabaseMap(userId: user.id),
              onConflict: 'id',
            );
            pendingWrites.remove(item);
            debugPrint('[DatabaseService] ✓ Upserted pending entry ${entry.id} to cloud');
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
      debugPrint('[DatabaseService] ✗ Sync failed: $e');
      _setSyncStatus(SyncStatus.error, e.toString());
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

          await client.from('reflections').upsert(
            encryptedEntry.toSupabaseMap(userId: user.id),
            onConflict: 'id',
          );
          pendingWrites.remove(item);
          debugPrint('[DatabaseService] ✓ Force-synced write: ${entry.id}');
        }
        await prefs.setStringList(_keyPendingWrites, pendingWrites);
      }

      // 3. Full remote pull
      await _pullRemoteChanges(maxPages: 20);

      _setSyncStatus(SyncStatus.synced);
      debugPrint('[DatabaseService] ✓ Force sync completed successfully');
    } catch (e) {
      final formatted = _formatSyncError(e);
      debugPrint('[DatabaseService] ✗ Force sync failed: $formatted (original: $e)');
      _setSyncStatus(SyncStatus.error, formatted);
      throw formatted;
    }
  }

  String _formatSyncError(Object e) {
    final str = e.toString();
    if (str.contains('42501') || str.contains('row-level security') || str.contains('USING expression')) {
      return 'Supabase RLS policy requires update. Please run the updated db/schema.sql in your Supabase SQL Editor.';
    }
    if (str.contains('SocketException') || str.contains('Failed host lookup') || str.contains('Network')) {
      return 'Network connection issue. Please check your internet connection.';
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

      if (remoteEntries.isNotEmpty) {
        final localEntries = await _loadLocalEntries();
        final map = <String, ReflectionEntryModel>{};
        for (final e in localEntries) {
          map[e.id] = e;
        }
        // Remote overrides or adds
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

  /// Save or update a reflection (instant local save + background E2EE cloud sync).
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    final user = AuthService().currentUser;
    final userPrefix = user != null ? '${user.id.substring(0, 8)}_' : '';
    final docId = entry.id.isNotEmpty
        ? entry.id
        : '$userPrefix${DateTime.now().millisecondsSinceEpoch}';

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
        final user = AuthService().currentUser;
        final encrypted = await _encryption.encryptEntry(entryWithId);
        await _client!.from('reflections').upsert(
          encrypted.toSupabaseMap(userId: user?.id),
          onConflict: 'id',
        );
        debugPrint('[DatabaseService] ✓ Pushed entry $docId to Supabase cloud');
        _setSyncStatus(SyncStatus.synced);
      } catch (e) {
        debugPrint('[DatabaseService] ✗ Cloud push failed for $docId, queuing: $e');
        await _queueWrite(entryWithId);
        // Schedule a retry
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

  /// Delete a reflection document.
  Future<void> deleteReflection(String docId) async {
    final entries = await _loadLocalEntries();
    entries.removeWhere((e) => e.id == docId);
    await _persistLocalEntries(entries);

    if (_isOnlineAndAuth) {
      try {
        await _client!.from('reflections').delete().eq('id', docId);
        debugPrint('[DatabaseService] ✓ Deleted $docId from cloud');
      } catch (e) {
        debugPrint('[DatabaseService] ✗ Cloud delete failed for $docId: $e');
        await _queueDelete(docId);
      }
    } else {
      await _queueDelete(docId);
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
