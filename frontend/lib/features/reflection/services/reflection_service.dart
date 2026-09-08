import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reflection_entry_model.dart';
import '../../journal/models/journal_entry.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/utils/error_formatter.dart';
import '../../auth/services/auth_service.dart';
import 'database_service.dart';

/// Centralized state management and repository for user reflections.
/// Connects to DatabaseService (Local-First + Supabase Sync) and provides
/// reactive updates across the app.
///
/// Implements [WidgetsBindingObserver] to automatically trigger cloud sync
/// when the app resumes from background.
class ReflectionService extends ChangeNotifier with WidgetsBindingObserver {
  static final ReflectionService _instance = ReflectionService._internal();
  factory ReflectionService([DatabaseService? databaseService]) {
    if (databaseService != null) {
      _instance._databaseService = databaseService;
    }
    return _instance;
  }

  ReflectionService._internal() {
    _initStream();
    _authSubscription = AuthService().isLoggedInStream.listen((_) {
      _initStream();
    });
    // Register lifecycle observer for auto-sync on resume
    WidgetsBinding.instance.addObserver(this);
    // Listen to sync status changes
    _syncStatusSubscription = _databaseService.syncStatusStream.listen((status) {
      _syncStatus = status;
      notifyListeners();
    });
  }

  DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<ReflectionEntryModel>>? _subscription;
  StreamSubscription<bool>? _authSubscription;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;

  List<ReflectionEntryModel> _entries = [];
  bool _isLoading = true;
  String? _error;
  SyncStatus _syncStatus = SyncStatus.idle;

  /// Active, non-deleted reflections.
  List<ReflectionEntryModel> get entries =>
      List.unmodifiable(_entries.where((e) => !e.isDeleted));

  /// All reflections including soft-deleted ones in the Recycle Bin.
  List<ReflectionEntryModel> get allEntries => List.unmodifiable(_entries);

  /// Reflections currently in the Recycle Bin (Trash), sorted by deletion date.
  List<ReflectionEntryModel> get deletedEntries {
    final trashed = _entries.where((e) => e.isDeleted).toList();
    trashed.sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
    return List.unmodifiable(trashed);
  }

  /// Total count of reflections currently resting in the Recycle Bin.
  int get deletedCount => _entries.where((e) => e.isDeleted).length;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Current cloud sync status.
  SyncStatus get syncStatus => _syncStatus;

  /// Last sync error message, if any.
  String? get lastSyncError => _databaseService.lastSyncError;

  /// Reactive streak computed from current active cached entries.
  int get streakCount => StreakCalculator.calculateStreak(entries);

  /// Reactive list of journal entries (active only).
  List<JournalEntry> get journalEntries =>
      entries.map((m) => m.toJournalEntry()).toList();

  /// Map of calendar dates to history reflection entries (active only).
  Map<DateTime, ReflectionEntryModel> get entriesByDate {
    final map = <DateTime, ReflectionEntryModel>{};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map[key] = e;
    }
    return map;
  }

  /// Auto-sync when app resumes from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[ReflectionService] App resumed — triggering cloud sync');
      _databaseService.syncPendingChanges();
    }
  }

  /// Initialize and listen to the single shared reflections stream.
  void _initStream() {
    _subscription?.cancel();
    _isLoading = true;

    try {
      _subscription = _databaseService.streamReflections().listen(
        (data) {
          _entries = data;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (err) {
          _isLoading = false;
          _error = ErrorFormatter.format(err);
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = ErrorFormatter.format(e);
      notifyListeners();
    }
  }

  /// Refreshes the reflections stream subscription and syncs with cloud.
  void refresh() {
    _initStream();
    _databaseService.syncPendingChanges();
  }

  /// Force a full cloud sync with error reporting.
  /// Throws an error string if sync fails, for user-facing feedback.
  Future<void> forceSyncNow() async {
    await _databaseService.forceSyncNow();
  }

  /// Returns the number of pending writes/deletes waiting to sync.
  Future<int> getPendingCount() async {
    return await _databaseService.getPendingCount();
  }

  /// Save or update a reflection.
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    await _databaseService.saveReflection(entry);
  }

  /// Moves a reflection to the Recycle Bin.
  Future<void> deleteReflection(String docId) async {
    await _databaseService.deleteReflection(docId);
  }

  /// Restores a reflection from the Recycle Bin back to active journal.
  Future<void> restoreReflection(String docId) async {
    await _databaseService.restoreReflection(docId);
  }

  /// Permanently deletes a reflection from local storage and cloud.
  Future<void> permanentlyDeleteReflection(String docId) async {
    await _databaseService.permanentlyDeleteReflection(docId);
  }

  /// Empties all items in the Recycle Bin permanently.
  Future<void> emptyTrash() async {
    await _databaseService.emptyTrash();
  }

  /// Toggle bookmark status.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    await _databaseService.toggleBookmark(docId, currentBookmark);
  }

  /// Clears all local reflections.
  Future<void> clearAllReflections() async {
    await _databaseService.clearLocalCache();
    _entries = [];
    notifyListeners();
  }

  /// Fetch the latest or yesterday's reflection for the home card.
  Future<ReflectionEntryModel?> getYesterdayOrLatestReflection() async {
    final active = entries;
    if (active.isNotEmpty) {
      final now = DateTime.now();
      for (final entry in active) {
        final isToday = entry.date.year == now.year &&
            entry.date.month == now.month &&
            entry.date.day == now.day;
        if (!isToday) return entry;
      }
      return active.first;
    }
    return await _databaseService.getYesterdayOrLatestReflection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _subscription?.cancel();
    _syncStatusSubscription?.cancel();
    super.dispose();
  }
}
