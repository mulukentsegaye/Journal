import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../models/reflection_entry_model.dart';

/// Cloud Firestore service to handle saving and streaming reflections
/// private to the authenticated user.
class FirestoreService {
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseAuth? _injectedAuth;

  FirestoreService([this._injectedFirestore, this._injectedAuth]);

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

  /// Get current user's UID.
  String? get currentUserId {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Path to user's reflections collection: users/{uid}/reflections
  CollectionReference<Map<String, dynamic>>? _userReflectionsRef() {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('reflections');
  }

  /// Save or update a reflection in Firestore.
  Future<void> saveReflection(ReflectionEntryModel entry) async {
    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) return;

    // Use document ID if provided, or generate a unique timestamp-based ID
    final docId = entry.id.isNotEmpty
        ? entry.id
        : '${DateTime.now().millisecondsSinceEpoch}';

    await col.doc(docId).set(
      entry.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Stream of reflections for the current user, ordered by date (newest first).
  Stream<List<ReflectionEntryModel>> streamReflections() {
    try {
      final col = _userReflectionsRef();
      if (col == null) return const Stream.empty();

      return col
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReflectionEntryModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Toggle bookmark for a given reflection document.
  Future<void> toggleBookmark(String docId, bool currentBookmark) async {
    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) return;

    await col.doc(docId).update({
      'isBookmarked': !currentBookmark,
    });
  }

  /// Delete a reflection document.
  Future<void> deleteReflection(String docId) async {
    await _ensureInitialized();
    final col = _userReflectionsRef();
    if (col == null) return;

    await col.doc(docId).delete();
  }

  /// Fetch the most recent reflection before today (for "Yesterday's Summary").
  Future<ReflectionEntryModel?> getYesterdayOrLatestReflection() async {
    try {
      await _ensureInitialized();
      final col = _userReflectionsRef();
      if (col == null) return null;

      final snapshot = await col
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // If the top one is today, return the second one (yesterday/previous), or return the first
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
