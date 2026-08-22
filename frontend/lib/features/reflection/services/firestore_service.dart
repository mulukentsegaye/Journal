import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../firebase_options.dart';
import '../../auth/services/auth_service.dart';
import '../models/reflection_entry_model.dart';

/// Service to handle saving and streaming reflections either to
/// Cloud Firestore (for authenticated users) or local SharedPreferences (for guests/offline).
class FirestoreService {
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseAuth? _injectedAuth;

  FirestoreService([this._injectedFirestore, this._injectedAuth]);

  static const String _keyLocalGuestReflections = 'local_guest_reflections';
  static final StreamController<List<ReflectionEntryModel>> _localStreamController =
      StreamController<List<ReflectionEntryModel>>.broadcast();

  FirebaseFirestore get _firestore {
    return _injectedFirestore ?? FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    return _injectedAuth ?? FirebaseAuth.instance;
  }

  /// Ensures Firebase is initialized before accessing Firestore.
  Future<void> _ensureInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (_) {}
  }

  /// Get current user's UID (Firebase UID or Local Guest UID).
  String? get currentUserId {
    return AuthService().currentUserId;
  }

  bool get _isLocalGuestSession {
    final auth = AuthService();
    return auth.isLocalGuest || auth.currentUser == null || (auth.currentUserId?.startsWith('guest_') == true);
  }

  /// Path to user's reflections collection: users/{uid}/reflections
  CollectionReference<Map<String, dynamic>>? _userReflectionsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('reflections');
  }

  // ── Local Guest Storage Helpers ──────────────────────────────
  Future<List<ReflectionEntryModel>> _loadLocalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyLocalGuestReflections) ?? [];
      final entries = rawList.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final id = map['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}';
        return ReflectionEntryModel.fromMap(map, id);
      }).toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistLocalEntries(List<ReflectionEntryModel> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = entries.map((e) {
        final map = e.toMap();
        map['id'] = e.id;
        return jsonEncode(map);
      }).toList();
      await prefs.setStringList(_keyLocalGuestReflections, rawList);
      _localStreamController.add(entries);
    } catch (_) {}
  }

  Stream<List<ReflectionEntryModel>> _streamLocalReflections() async* {
    final initial = await _loadLocalEntries();
    yield initial;
    yield* _localStreamController.stream;
  }

  // ── Public CRUD Methods ──────────────────────────────────────

  /// Save or update a reflection in Firestore (or local storage for guest).
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

    if (_isLocalGuestSession) {
      final entries = await _loadLocalEntries();
      final index = entries.indexWhere((e) => e.id == docId);
      if (index >= 0) {
        entries[index] = entryWithId;
      } else {
        entries.insert(0, entryWithId);
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      await _persistLocalEntries(entries);
      return;
    }

    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) {
      // Fallback to local storage if Firestore reference unavailable
      final entries = await _loadLocalEntries();
      final index = entries.indexWhere((e) => e.id == docId);
      if (index >= 0) {
        entries[index] = entryWithId;
      } else {
        entries.insert(0, entryWithId);
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      await _persistLocalEntries(entries);
      return;
    }

    await col.doc(docId).set(
      entryWithId.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Stream of reflections for the current user, ordered by date (newest first).
  Stream<List<ReflectionEntryModel>> streamReflections() {
    if (_isLocalGuestSession) {
      return _streamLocalReflections();
    }

    try {
      final col = _userReflectionsRef();
      if (col == null) return _streamLocalReflections();

      return col
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReflectionEntryModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (_) {
      return _streamLocalReflections();
    }
  }

  /// Toggle bookmark for a given reflection document.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    if (_isLocalGuestSession) {
      final entries = await _loadLocalEntries();
      final index = entries.indexWhere((e) => e.id == docId);
      if (index >= 0) {
        final old = entries[index];
        entries[index] = ReflectionEntryModel(
          id: old.id,
          date: old.date,
          mood: old.mood,
          moodEmoji: old.moodEmoji,
          answers: old.answers,
          freeformTitle: old.freeformTitle,
          freeformNote: old.freeformNote,
          isBookmarked: !currentBookmark,
          type: old.type,
          createdAt: old.createdAt,
        );
        await _persistLocalEntries(entries);
      }
      return;
    }

    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) return;

    await col.doc(docId).update({
      'isBookmarked': !currentBookmark,
    });
  }

  /// Delete a reflection document.
  Future<void> deleteReflection(String docId) async {
    if (_isLocalGuestSession) {
      final entries = await _loadLocalEntries();
      entries.removeWhere((e) => e.id == docId);
      await _persistLocalEntries(entries);
      return;
    }

    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) return;

    await col.doc(docId).delete();
  }

  /// Fetch the most recent reflection before today (for "Yesterday's Summary").
  Future<ReflectionEntryModel?> getYesterdayOrLatestReflection() async {
    if (_isLocalGuestSession) {
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

    try {
      await _ensureInitialized();
      final col = _userReflectionsRef();
      if (col == null) return null;

      final snapshot = await col
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        final entry = ReflectionEntryModel.fromMap(doc.data(), doc.id);
        final isToday = entry.date.year == now.year &&
            entry.date.month == now.month &&
            entry.date.day == now.day;
        if (!isToday) {
          return entry;
        }
      }

      return ReflectionEntryModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (_) {
      return null;
    }
  }
}
