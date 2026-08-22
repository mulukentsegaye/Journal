import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized manager for Biometric & PIN App Lock and App Lifecycle security.
class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _keyIsLockEnabled = 'security_is_lock_enabled';
  static const String _keyIsBiometricsEnabled = 'security_is_biometrics_enabled';
  static const String _keyPinHash = 'security_pin_hash';
  static const String _keyLockTimeout = 'security_lock_timeout_seconds';

  bool _isLockEnabled = false;
  bool _isBiometricsEnabled = true;
  String? _pinHash;
  int _lockTimeoutSeconds = 0; // 0 = Immediately upon backgrounding

  bool _isLocked = false;
  DateTime? _lastPausedTime;
  bool _isInitialized = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;
  bool get isLocked => _isLocked;
  bool get isInitialized => _isInitialized;

  /// Loads security preferences on launch.
  Future<void> loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLockEnabled = prefs.getBool(_keyIsLockEnabled) ?? false;
      _isBiometricsEnabled = prefs.getBool(_keyIsBiometricsEnabled) ?? true;
      _pinHash = prefs.getString(_keyPinHash);
      _lockTimeoutSeconds = prefs.getInt(_keyLockTimeout) ?? 0;

      // If lock is enabled, start locked
      if (_isLockEnabled && hasPin) {
        _isLocked = true;
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  /// Hashes a 4-digit PIN code using SHA-256.
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode('daily_reflection_pin_salt:$pin')).toString();
  }

  /// Sets or updates the security PIN code and automatically enables lock.
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    _pinHash = hash;
    _isLockEnabled = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPinHash, hash);
      await prefs.setBool(_keyIsLockEnabled, true);
    } catch (_) {}
  }

  /// Verifies entered PIN against stored hash.
  bool verifyPin(String pin) {
    if (_pinHash == null) return false;
    final isMatch = _pinHash == _hashPin(pin);
    if (isMatch) {
      unlockApp();
    }
    return isMatch;
  }

  /// Removes PIN and disables lock.
  Future<void> removePin() async {
    _pinHash = null;
    _isLockEnabled = false;
    _isLocked = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPinHash);
      await prefs.setBool(_keyIsLockEnabled, false);
    } catch (_) {}
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
