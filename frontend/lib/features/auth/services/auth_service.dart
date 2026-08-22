import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../firebase_options.dart';

/// Service that encapsulates Firebase Authentication methods and provides
/// a seamless Local Guest Mode fallback when Firebase anonymous auth is disabled/offline.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService([FirebaseAuth? auth]) {
    if (auth != null) {
      _instance._injectedAuth = auth;
    }
    return _instance;
  }
  AuthService._internal();

  FirebaseAuth? _injectedAuth;

  static const String _keyIsLocalGuest = 'auth_is_local_guest';
  static const String _keyGuestName = 'auth_guest_display_name';
  static const String _keyGuestUid = 'auth_guest_uid';

  bool _isLocalGuest = false;
  String _guestName = 'Guest';
  String _guestUid = 'guest_local_user';
  bool _isSessionLoaded = false;

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  bool get isLocalGuest => _isLocalGuest;
  bool get isSessionLoaded => _isSessionLoaded;

  FirebaseAuth get _auth {
    return _injectedAuth ?? FirebaseAuth.instance;
  }

  /// Ensures Firebase is initialized before making any auth calls.
  Future<void> _ensureInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (_) {}
  }

  /// Load persisted session state on app launch.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLocalGuest = prefs.getBool(_keyIsLocalGuest) ?? false;
      _guestName = prefs.getString(_keyGuestName) ?? 'Guest';
      _guestUid = prefs.getString(_keyGuestUid) ??
          'guest_${DateTime.now().millisecondsSinceEpoch}';
      if (_isLocalGuest && !prefs.containsKey(_keyGuestUid)) {
        await prefs.setString(_keyGuestUid, _guestUid);
      }
    } catch (_) {}
    _isSessionLoaded = true;
    _notifyAuthState();
  }

  void _notifyAuthState() {
    _authStateController.add(isLoggedIn);
  }

  /// Unified stream indicating whether the user is logged in (via Firebase or Local Guest).
  Stream<bool> get isLoggedInStream async* {
    yield isLoggedIn;
    yield* _authStateController.stream;
  }

  /// Stream of Firebase auth state changes.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Whether any user is currently authenticated (Firebase or Local Guest).
  bool get isLoggedIn {
    if (_isLocalGuest) return true;
    try {
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Whether current session is in guest mode.
  bool get isGuest {
    if (_isLocalGuest) return true;
    try {
      return _auth.currentUser?.isAnonymous == true;
    } catch (_) {
      return false;
    }
  }

  /// Currently signed in user, if any.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Current user UID.
  String? get currentUserId {
    if (_isLocalGuest) return _guestUid;
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// User's display name or email prefix.
  String get userName {
    if (_isLocalGuest) {
      return _guestName.isNotEmpty ? _guestName : 'Guest';
    }
    try {
      final user = currentUser;
      if (user == null) return 'Friend';
      if (user.isAnonymous) {
        return _guestName.isNotEmpty ? _guestName : 'Guest';
      }
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        return user.displayName!.trim();
      }
      if (user.email != null && user.email!.contains('@')) {
        final name = user.email!.split('@').first;
        return name[0].toUpperCase() + name.substring(1);
      }
    } catch (_) {}
    return 'Friend';
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _clearLocalGuest();
      _notifyAuthState();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email, password, and optional display name.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _ensureInitialized();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      await _clearLocalGuest();
      _notifyAuthState();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset link to given email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _ensureInitialized();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in as a guest. Tries Firebase anonymous auth first;
  /// if disabled or failed, falls back seamlessly to Local Guest Mode.
  Future<void> signInAnonymously() async {
    await _ensureInitialized();
    try {
      await _auth.signInAnonymously();
      await _clearLocalGuest();
    } catch (_) {
      // Firebase anonymous auth failed/disabled in console: activate Local Guest Mode
      await _enableLocalGuest();
    }
    _notifyAuthState();
  }

  Future<void> _enableLocalGuest() async {
    _isLocalGuest = true;
    _guestName = 'Guest';
    _guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLocalGuest, true);
      await prefs.setString(_keyGuestName, _guestName);
      await prefs.setString(_keyGuestUid, _guestUid);
    } catch (_) {}
  }

  Future<void> _clearLocalGuest() async {
    _isLocalGuest = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLocalGuest, false);
    } catch (_) {}
  }

  /// Update the current user's profile display name.
  Future<void> updateDisplayName(String name) async {
    if (_isLocalGuest || (currentUser?.isAnonymous == true)) {
      _guestName = name.trim();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyGuestName, _guestName);
      } catch (_) {}
      _notifyAuthState();
      if (_isLocalGuest) return;
    }

    await _ensureInitialized();
    try {
      await currentUser?.updateDisplayName(name.trim());
      await currentUser?.reload();
      _notifyAuthState();
    } catch (_) {}
  }

  /// Delete current user's account permanently.
  Future<void> deleteAccount() async {
    if (_isLocalGuest) {
      await _clearLocalGuest();
      _notifyAuthState();
      return;
    }

    await _ensureInitialized();
    try {
      await currentUser?.delete();
      await _clearLocalGuest();
      _notifyAuthState();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    await _clearLocalGuest();
    try {
      await _auth.signOut();
    } catch (_) {}
    _notifyAuthState();
  }

  /// Translates Firebase error codes to friendly user messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network connection issue. Please check your internet connection.';
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return 'This sign-in method is currently restricted.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
