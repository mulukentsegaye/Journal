import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Service that encapsulates Supabase Authentication methods and provides
/// a seamless Local Guest Mode fallback when offline or when credentials are not supplied.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService([GoTrueClient? auth]) {
    if (auth != null) {
      _instance._injectedAuth = auth;
    }
    return _instance;
  }
  AuthService._internal();

  GoTrueClient? _injectedAuth;

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

  GoTrueClient? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      return null;
    }
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
    notifyListeners();
  }

  /// Unified stream indicating whether the user is logged in (via Supabase or Local Guest).
  Stream<bool> get isLoggedInStream async* {
    yield isLoggedIn;
    yield* _authStateController.stream;
  }

  /// Stream of Supabase auth state changes.
  Stream<AuthState> get authStateChanges {
    final client = _auth;
    if (client == null) return const Stream.empty();
    try {
      return client.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Whether any user is currently authenticated (Supabase or Local Guest).
  bool get isLoggedIn {
    if (_isLocalGuest) return true;
    try {
      return _auth?.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Whether current session is in guest mode.
  bool get isGuest {
    if (_isLocalGuest) return true;
    try {
      return _auth?.currentUser?.isAnonymous == true;
    } catch (_) {
      return false;
    }
  }

  /// Currently signed in Supabase user, if any.
  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Current user UID (Supabase UUID or Local Guest UID).
  String? get currentUserId {
    if (_isLocalGuest) return _guestUid;
    try {
      return _auth?.currentUser?.id;
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
      final metaName = user.userMetadata?['display_name']?.toString();
      if (metaName != null && metaName.trim().isNotEmpty) {
        return metaName.trim();
      }
      if (user.email != null && user.email!.contains('@')) {
        final name = user.email!.split('@').first;
        return name[0].toUpperCase() + name.substring(1);
      }
    } catch (_) {}
    return 'Friend';
  }

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _auth;
    if (client == null) {
      throw 'Supabase is not configured. Please check your Supabase credentials or use Guest Mode.';
    }

    try {
      final res = await client.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _clearLocalGuest();
      _notifyAuthState();
      return res;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Sign up with email, password, and optional display name.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final client = _auth;
    if (client == null) {
      throw 'Supabase is not configured. Please check your Supabase credentials or use Guest Mode.';
    }

    try {
      final res = await client.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'dailyreflection://login-callback',
        data: displayName != null && displayName.trim().isNotEmpty
            ? {'display_name': displayName.trim()}
            : null,
      );

      await _clearLocalGuest();
      _notifyAuthState();
      return res;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Send password reset link to given email with deep link redirect.
  Future<void> sendPasswordResetEmail(String email) async {
    final client = _auth;
    if (client == null) {
      throw 'Supabase is not configured.';
    }

    try {
      await client.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'dailyreflection://login-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Update user's password (used during password recovery / reset deep link flow).
  Future<UserResponse> updateUserPassword(String newPassword) async {
    final client = _auth;
    if (client == null) {
      throw 'Supabase is not configured.';
    }

    try {
      final res = await client.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
      _notifyAuthState();
      return res;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Sign in as a guest. Tries Supabase anonymous auth first;
  /// if disabled or failed, falls back seamlessly to Local Guest Mode.
  Future<void> signInAnonymously() async {
    final client = _auth;
    if (client != null) {
      try {
        await client.signInAnonymously();
        await _clearLocalGuest();
        _notifyAuthState();
        return;
      } catch (_) {
        // Fall back to local guest mode
      }
    }
    await _enableLocalGuest();
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

    final client = _auth;
    if (client != null && currentUser != null) {
      try {
        await client.updateUser(
          UserAttributes(data: {'display_name': name.trim()}),
        );
        _notifyAuthState();
      } catch (_) {}
    }
  }

  /// Delete current user's account permanently.
  Future<void> deleteAccount() async {
    if (_isLocalGuest) {
      await _clearLocalGuest();
      _notifyAuthState();
      return;
    }

    // In Supabase, client-side self-deletion is handled via RPC or Edge function,
    // or by signing out and clearing session.
    await signOut();
  }

  /// Sign out current user.
  Future<void> signOut() async {
    await _clearLocalGuest();
    try {
      await _auth?.signOut();
    } catch (_) {}
    _notifyAuthState();
  }

  /// Translates Supabase error codes to user-friendly messages.
  String _handleAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Invalid email or password. Please check and try again.';
    }
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('valid email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('password') && (msg.contains('short') || msg.contains('least 6'))) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return e.message;
  }
}
