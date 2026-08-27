import 'dart:async';
import 'dart:convert';
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
    } catch (_) {}
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

/// Top-level isolate function for serializing reflection entries to JSON.
/// Executed off the main UI thread via [compute] to prevent UI jank.
List<String> serializeEntriesToJsonStrings(List<Map<String, dynamic>> entryMaps) {
  return entryMaps.map((m) => jsonEncode(m)).toList();
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

  SupabaseClient? get _client {
    if (_injectedClient != null) return _injectedClient;
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
  }

  /// Pushes any pending writes and deletes to Supabase (with client-side E2EE).
  Future<void> syncPendingChanges() async {
    if (!_isOnlineAndAuth) return;
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Process pending deletes
      final pendingDeletes = prefs.getStringList(_keyPendingDeletes) ?? [];
      if (pendingDeletes.isNotEmpty) {
        for (final id in List<String>.from(pendingDeletes)) {
          try {
            await client.from('reflections').delete().eq('id', id);
            pendingDeletes.remove(id);
          } catch (_) {
            break; // Network issue, retry later
          }
        }
        await prefs.setStringList(_keyPendingDeletes, pendingDeletes);
      }

      // 2. Process pending writes (encrypt before uploading)
      final pendingWrites = prefs.getStringList(_keyPendingWrites) ?? [];
      if (pendingWrites.isNotEmpty) {
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
          } catch (_) {
            break;
          }
        }
        await prefs.setStringList(_keyPendingWrites, pendingWrites);
      }

      // 3. Fetch latest from Supabase with paginated batches, decrypt on device, and merge
      await _pullRemoteChanges();
    } catch (_) {}
  }

  /// Pulls remote reflections from Supabase using paginated batches (pageSize: 50),
  /// decrypts on-device, and merges into local repository.
  Future<void> _pullRemoteChanges({
    int pageSize = defaultPageSize,
    int maxPages = 4,
  }) async {
    if (!_isOnlineAndAuth) return;
    final client = _client;
    final user = AuthService().currentUser;
    if (client == null || user == null) return;

    try {
      final remoteEntries = <ReflectionEntryModel>[];
      int page = 0;
      bool hasMore = true;

      while (hasMore && page < maxPages) {
        final from = page * pageSize;
        final to = from + pageSize - 1;

        final response = await client
            .from('reflections')
            .select()
            .order('date', ascending: false)
            .range(from, to);

        final remoteRows = response as List;
        if (remoteRows.isEmpty) {
          hasMore = false;
          break;
        }

        for (final row in remoteRows) {
          final rawEntry = ReflectionEntryModel.fromSupabase(row as Map<String, dynamic>);
          final decryptedEntry = await _encryption.decryptEntry(rawEntry);
          remoteEntries.add(decryptedEntry);
        }

        if (remoteRows.length < pageSize) {
          hasMore = false;
        } else {
          page++;
        }
      }

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
      }
    } catch (_) {}
  }

  /// Fetches a specific paginated window of reflections from Supabase on demand.
  Future<List<ReflectionEntryModel>> fetchRemotePage({
    int page = 0,
    int pageSize = defaultPageSize,
  }) async {
    if (!_isOnlineAndAuth) return [];
    final client = _client;
    if (client == null) return [];

    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await client
          .from('reflections')
          .select()
          .order('date', ascending: false)
          .range(from, to);

      final rows = response as List;
      final entries = <ReflectionEntryModel>[];

      for (final row in rows) {
        final rawEntry = ReflectionEntryModel.fromSupabase(row as Map<String, dynamic>);
        final decrypted = await _encryption.decryptEntry(rawEntry);
        entries.add(decrypted);
      }

      return entries;
    } catch (e) {
      debugPrint('Failed to fetch remote page $page: $e');
      return [];
    }
  }

  // ── Public CRUD Methods ──────────────────────────────────────

  /// Save or update a reflection (instant local save + background E2EE cloud sync).
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    final docId = entry.id.isNotEmpty
        ? entry.id
        : '${DateTime.now().millisecondsSinceEpoch}';

    final entryWithId = ReflectionEntryModel(
      id: docId,
      date: entry.date,
      mood: entry.mood,
      moodEmoji: entry.moodEmoji,
      answers: entry.answers,
      freeformTitle: entry.freeformTitle,
      freeformNote: entry.freeformNote,
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

    // 2. Queue write or sync encrypted payload to Supabase
    if (_isOnlineAndAuth) {
      try {
        final user = AuthService().currentUser;
        final encrypted = await _encryption.encryptEntry(entryWithId);
        await _client!.from('reflections').upsert(
          encrypted.toSupabaseMap(userId: user?.id),
          onConflict: 'id',
        );
      } catch (_) {
        await _queueWrite(entryWithId);
      }
    } else {
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
        } catch (_) {
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
      } catch (_) {
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
    } catch (_) {}
  }
}
