import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/crypto_utils.dart';

/// Centralized manager for Biometric & PIN App Lock, PBKDF2 cryptography,
/// hardware-backed secure storage (Keystore/Keychain), and brute-force protection.
class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  }) {
    if (secureStorage != null) {
      _instance._secureStorage = secureStorage;
    }
    if (localAuth != null) {
      _instance._localAuth = localAuth;
    }
    return _instance;
  }
  SecurityService._internal();

  LocalAuthentication _localAuth = LocalAuthentication();
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static const String _keyIsLockEnabled = 'security_is_lock_enabled';
  static const String _keyIsBiometricsEnabled = 'security_is_biometrics_enabled';
  static const String _keyLockTimeout = 'security_lock_timeout_seconds';
  static const String _legacyKeyPinHash = 'security_pin_hash';
  static const String _secureKeyPinHash = 'secure_app_lock_pin_hash';

  bool _isLockEnabled = false;
  bool _isBiometricsEnabled = true;
  String? _pinHash;
  int _lockTimeoutSeconds = 0; // 0 = Immediately upon backgrounding

  bool _isLocked = false;
  DateTime? _lastPausedTime;
  bool _isInitialized = false;

  // ── Brute-force & Rate-Limiting Defense ─────────────────────────
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;
  bool get isLocked => _isLocked;
  bool get isInitialized => _isInitialized;
  int get failedAttempts => _failedAttempts;

  /// Whether PIN entry is currently locked out due to repeated failed attempts.
  bool get isRateLimited {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  /// Number of seconds remaining in current lockout cooldown.
  int get lockoutSecondsRemaining {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Loads security preferences and retrieves salted PIN from hardware Keystore/Keychain.
  Future<void> loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLockEnabled = prefs.getBool(_keyIsLockEnabled) ?? false;
      _isBiometricsEnabled = prefs.getBool(_keyIsBiometricsEnabled) ?? true;
      _lockTimeoutSeconds = prefs.getInt(_keyLockTimeout) ?? 0;

      // 1. Read PIN hash from Hardware-backed Secure Storage
      var pinHash = await _secureStorage.read(key: _secureKeyPinHash);

      // 2. Check for legacy unencrypted PIN in SharedPreferences for seamless migration
      if (pinHash == null || pinHash.isEmpty) {
        final legacyHash = prefs.getString(_legacyKeyPinHash);
        if (legacyHash != null && legacyHash.isNotEmpty) {
          pinHash = legacyHash;
        }
      }

      _pinHash = pinHash;

      // If lock is enabled, start locked
      if (_isLockEnabled && hasPin) {
        _isLocked = true;
      }
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Sets or updates the security PIN using PBKDF2-HMAC-SHA256 and stores in Secure Storage.
  Future<void> setPin(String pin) async {
    final saltedHash = CryptoUtils.hashPin(pin: pin);
    _pinHash = saltedHash;
    _isLockEnabled = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();

    try {
      // Store in hardware keystore / keychain
      await _secureStorage.write(key: _secureKeyPinHash, value: saltedHash);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLockEnabled, true);
      // Clean up legacy plaintext hash if present
      await prefs.remove(_legacyKeyPinHash);
    } catch (e) {
      debugPrint('Error saving PIN to secure storage: $e');
    }
  }

  /// Verifies entered PIN against stored hash with PBKDF2 and rate-limiting defense.
  Future<bool> verifyPin(String pin) async {
    if (_pinHash == null) return false;

    // Check rate-limiting lockout
    if (isRateLimited) {
      return false;
    }

    final isMatch = CryptoUtils.verifyPin(pin: pin, storedHash: _pinHash!);

    if (isMatch) {
      _failedAttempts = 0;
      _lockoutUntil = null;

      // Automatic zero-loss migration: If hash is legacy SHA-256, upgrade to PBKDF2
      if (!_pinHash!.startsWith(CryptoUtils.pbkdf2Prefix)) {
        unawaited(_upgradeLegacyPinHash(pin));
      }

      unlockApp();
      return true;
    } else {
      _failedAttempts++;

      if (_failedAttempts >= 10) {
        // 5-minute lockout after 10 failed attempts
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
      } else if (_failedAttempts >= 8) {
        // 1-minute lockout after 8 failed attempts
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 1));
      } else if (_failedAttempts >= 5) {
        // 30-second lockout after 5 failed attempts
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      }

      notifyListeners();
      return false;
    }
  }

  /// Upgrades legacy PIN hash to PBKDF2-HMAC-SHA256 in background.
  Future<void> _upgradeLegacyPinHash(String pin) async {
    try {
      final upgradedHash = CryptoUtils.hashPin(pin: pin);
      _pinHash = upgradedHash;
      await _secureStorage.write(key: _secureKeyPinHash, value: upgradedHash);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyPinHash);
      debugPrint('Successfully upgraded legacy PIN hash to PBKDF2.');
    } catch (e) {
      debugPrint('Failed to upgrade legacy PIN: $e');
    }
  }

  /// Removes PIN and disables lock.
  Future<void> removePin() async {
    _pinHash = null;
    _isLockEnabled = false;
    _isLocked = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();

    try {
      await _secureStorage.delete(key: _secureKeyPinHash);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyPinHash);
      await prefs.setBool(_keyIsLockEnabled, false);
    } catch (e) {
      debugPrint('Error removing PIN: $e');
    }
  }

  /// Enables or disables App Lock.
  Future<void> setLockEnabled(bool enabled) async {
    _isLockEnabled = enabled;
    if (!enabled) {
      _isLocked = false;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLockEnabled, enabled);
    } catch (_) {}
  }

  /// Toggles biometric prompt usage.
  Future<void> setBiometricsEnabled(bool enabled) async {
    _isBiometricsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsBiometricsEnabled, enabled);
    } catch (_) {}
  }

  /// Sets auto-lock timeout duration in seconds (0 = immediate, 60 = 1 min, 300 = 5 min).
  Future<void> setLockTimeout(int seconds) async {
    _lockTimeoutSeconds = seconds;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLockTimeout, seconds);
    } catch (_) {}
  }

  /// Checks if the device hardware supports biometrics.
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric authentication dialog (Face ID, Touch ID, Fingerprint).
  Future<bool> authenticateWithBiometrics() async {
    if (!_isBiometricsEnabled) return false;

    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock Daily Reflection',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        unlockApp();
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  /// Manually locks the app.
  void lockApp() {
    if (_isLockEnabled && hasPin) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Unlocks the app.
  void unlockApp() {
    _isLocked = false;
    _lastPausedTime = null;
    notifyListeners();
  }

  /// Handles app lifecycle state paused (app went to background).
  void handleAppPaused() {
    if (_isLockEnabled && hasPin) {
      _lastPausedTime = DateTime.now();
    }
  }

  /// Handles app lifecycle state resumed (app came back to foreground).
  void handleAppResumed() {
    if (!_isLockEnabled || !hasPin) return;

    if (_lastPausedTime == null) {
      _isLocked = true;
      notifyListeners();
      return;
    }

    final elapsed = DateTime.now().difference(_lastPausedTime!).inSeconds;
    if (elapsed >= _lockTimeoutSeconds) {
      _isLocked = true;
      notifyListeners();
    }
  }
}
