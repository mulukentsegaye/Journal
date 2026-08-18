import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';

/// Service that encapsulates Firebase Authentication methods.
class AuthService {
  final FirebaseAuth? _injectedAuth;

  AuthService([this._injectedAuth]);

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

  /// Stream of auth state changes (logged in / logged out).
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
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

  /// User's display name or email prefix.
  String get userName {
    try {
      final user = currentUser;
      if (user == null) return 'Friend';
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
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
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

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
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
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
