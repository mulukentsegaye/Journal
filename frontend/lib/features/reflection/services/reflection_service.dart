import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reflection_entry_model.dart';
import '../../journal/models/journal_entry.dart';
import '../../../core/utils/streak_calculator.dart';
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

  List<ReflectionEntryModel> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Current cloud sync status.
  SyncStatus get syncStatus => _syncStatus;

  /// Last sync error message, if any.
  String? get lastSyncError => _databaseService.lastSyncError;

  /// Reactive streak computed from current cached entries.
  int get streakCount => StreakCalculator.calculateStreak(_entries);

  /// Reactive list of journal entries.
  List<JournalEntry> get journalEntries =>
      _entries.map((m) => m.toJournalEntry()).toList();

  /// Map of calendar dates to history reflection entries.
  Map<DateTime, ReflectionEntryModel> get entriesByDate {
    final map = <DateTime, ReflectionEntryModel>{};
    for (final e in _entries) {
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
          _error = err.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
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

  /// Delete a reflection by document ID.
  Future<void> deleteReflection(String docId) async {
    await _databaseService.deleteReflection(docId);
  }

  /// Toggle bookmark status.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    await _databaseService.toggleBookmark(docId, currentBookmark);
  }

  /// Fetch the latest or yesterday's reflection for the home card.
  Future<ReflectionEntryModel?> getYesterdayOrLatestReflection() async {
    if (_entries.isNotEmpty) {
      final now = DateTime.now();
      for (final entry in _entries) {
        final isToday = entry.date.year == now.year &&
            entry.date.month == now.month &&
            entry.date.day == now.day;
        if (!isToday) return entry;
      }
      return _entries.first;
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
