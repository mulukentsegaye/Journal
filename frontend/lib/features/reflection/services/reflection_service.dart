import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reflection_entry_model.dart';
import '../../journal/models/journal_entry.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../auth/services/auth_service.dart';
import 'firestore_service.dart';

/// Centralized state management and repository for user reflections.
/// Prevents redundant Firestore stream subscriptions and provides reactive
/// updates across the app.
class ReflectionService extends ChangeNotifier {
  static final ReflectionService _instance = ReflectionService._internal();
  factory ReflectionService([FirestoreService? firestoreService]) {
    if (firestoreService != null) {
      _instance._firestoreService = firestoreService;
    }
    return _instance;
  }

  ReflectionService._internal() {
    _initStream();
    _authSubscription = AuthService().isLoggedInStream.listen((_) {
      _initStream();
    });
  }

  FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<ReflectionEntryModel>>? _subscription;
  StreamSubscription<bool>? _authSubscription;

  List<ReflectionEntryModel> _entries = [];
  bool _isLoading = true;
  String? _error;

  List<ReflectionEntryModel> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Initialize and listen to the single shared reflections stream.
  void _initStream() {
    _subscription?.cancel();
    _isLoading = true;

    try {
      _subscription = _firestoreService.streamReflections().listen(
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

  /// Refreshes the reflections stream subscription.
  void refresh() {
    _initStream();
  }

  /// Save or update a reflection.
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    await _firestoreService.saveReflection(entry);
  }

  /// Delete a reflection by document ID.
  Future<void> deleteReflection(String docId) async {
    await _firestoreService.deleteReflection(docId);
  }

  /// Toggle bookmark status.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    await _firestoreService.toggleBookmark(docId, currentBookmark);
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
    return await _firestoreService.getYesterdayOrLatestReflection();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
