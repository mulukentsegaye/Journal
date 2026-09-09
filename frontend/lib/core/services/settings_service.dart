import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants/app_strings.dart';
import 'notification_service.dart';
import '../../features/reflection/services/database_service.dart';

/// App-wide settings and preference manager.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyReminderEnabled = 'settings_reminder_enabled';
  static const String _keyReminderHour = 'settings_reminder_hour';
  static const String _keyReminderMinute = 'settings_reminder_minute';
  static const String _keyMorningReminderEnabled = 'settings_morning_reminder_enabled';
  static const String _keyMorningReminderHour = 'settings_morning_reminder_hour';
  static const String _keyMorningReminderMinute = 'settings_morning_reminder_minute';
  static const String _keyHasCompletedOnboarding = 'settings_has_completed_onboarding';

  ThemeMode _themeMode = ThemeMode.system;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0); // 6:00 PM
  bool _morningReminderEnabled = false;
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 8, minute: 0); // 8:00 AM
  bool _hasCompletedOnboarding = false;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get eveningReminderEnabled => _reminderEnabled;
  TimeOfDay get eveningReminderTime => _reminderTime;

  bool get morningReminderEnabled => _morningReminderEnabled;
  TimeOfDay get morningReminderTime => _morningReminderTime;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;

  /// Whether dark mode is currently active based on theme mode or system brightness.
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  /// Load persisted user preferences.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeIndex = prefs.getInt(_keyThemeMode);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }

      _reminderEnabled = prefs.getBool(_keyReminderEnabled) ?? true;
      final hour = prefs.getInt(_keyReminderHour) ?? 18;
      final minute = prefs.getInt(_keyReminderMinute) ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);

      _morningReminderEnabled = prefs.getBool(_keyMorningReminderEnabled) ?? false;
      final mHour = prefs.getInt(_keyMorningReminderHour) ?? 8;
      final mMinute = prefs.getInt(_keyMorningReminderMinute) ?? 0;
      _morningReminderTime = TimeOfDay(hour: mHour, minute: mMinute);

      _hasCompletedOnboarding = prefs.getBool(_keyHasCompletedOnboarding) ?? false;

      // Reschedule or initialize reminders according to loaded preferences
      if (_reminderEnabled) {
        NotificationService().scheduleDailyReminder(_reminderTime);
      }
      if (_morningReminderEnabled) {
        NotificationService().scheduleMorningReminder(_morningReminderTime);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Update and persist theme mode (system, light, dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (_) {}
  }

  /// Toggle daily evening reflection reminder.
  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReminderEnabled, enabled);
    } catch (_) {}

    if (enabled) {
      await NotificationService().scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationService().cancelReminder();
    }
  }

  /// Set the time for daily evening reflection reminders.
  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyReminderHour, time.hour);
      await prefs.setInt(_keyReminderMinute, time.minute);
    } catch (_) {}

    if (_reminderEnabled) {
      await NotificationService().scheduleDailyReminder(time);
    }
  }

  /// Toggle daily morning intention reminder.
  Future<void> setMorningReminderEnabled(bool enabled) async {
    _morningReminderEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMorningReminderEnabled, enabled);
    } catch (_) {}

    if (enabled) {
      await NotificationService().scheduleMorningReminder(_morningReminderTime);
    } else {
      await NotificationService().cancelMorningReminder();
    }
  }

  /// Set the time for daily morning intention reminders.
  Future<void> setMorningReminderTime(TimeOfDay time) async {
    _morningReminderTime = time;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMorningReminderHour, time.hour);
      await prefs.setInt(_keyMorningReminderMinute, time.minute);
    } catch (_) {}

    if (_morningReminderEnabled) {
      await NotificationService().scheduleMorningReminder(time);
    }
  }

  /// Marks the first-time onboarding flow as completed.
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCompletedOnboarding, true);
    } catch (_) {}
  }

  /// Resets onboarding completion flag (allows replaying tour).
  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCompletedOnboarding, false);
    } catch (_) {}
  }

  /// Format evening reminder time nicely e.g. "6:00 PM".
  String get formattedReminderTime {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _reminderTime.hour, _reminderTime.minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Format morning reminder time nicely e.g. "8:00 AM".
  String get formattedMorningReminderTime {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _morningReminderTime.hour, _morningReminderTime.minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Exports all saved reflections as a structured Markdown document.
  Future<String> exportAllReflectionsMarkdown() async {
    final db = DatabaseService();
    final rawEntries = await db.streamReflections().first;
    final entries = rawEntries.where((e) => !e.isDeleted).toList();

    if (entries.isEmpty) {
      return '# Daily Reflection Journal Backup\n\nNo reflection entries found yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('# Daily Reflection Journal Backup');
    buffer.writeln('Exported on: ${DateFormat('MMMM d, yyyy — h:mm a').format(DateTime.now())}');
    buffer.writeln('Total Reflections: ${entries.length}\n');
    buffer.writeln('---\n');

    for (final entry in entries) {
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);
      buffer.writeln('## $dateStr');
      buffer.writeln('**Mood**: ${entry.mood} ${entry.moodEmoji}\n');

      if (entry.tags.isNotEmpty) {
        final formattedTags =
            entry.tags.map((t) => t.startsWith('#') ? t : '#$t').join(' ');
        buffer.writeln('**Tags**: $formattedTags\n');
      }

      if (entry.freeformTitle != null && entry.freeformTitle!.isNotEmpty) {
        buffer.writeln('### ${entry.freeformTitle}');
      }
      if (entry.freeformNote != null && entry.freeformNote!.isNotEmpty) {
        buffer.writeln('${entry.freeformNote}\n');
      }

      if (entry.photoUrl != null && entry.photoUrl!.isNotEmpty) {
        buffer.writeln('![Photo Attachment](${entry.photoUrl})\n');
      }

      if (entry.answers.isNotEmpty) {
        buffer.writeln('#### Guided Reflections:');
        for (final entryItem in entry.answers.entries) {
          final prompt = AppStrings.questionPrompts[entryItem.key] ?? 'Question ${entryItem.key}';
          buffer.writeln('- **$prompt**\n  "${entryItem.value}"');
        }
        buffer.writeln();
      }

      buffer.writeln('---\n');
    }

    return buffer.toString().trim();
  }

  /// Exports all saved reflections as a structured, indented JSON backup.
  Future<String> exportAllReflectionsJson() async {
    final db = DatabaseService();
    final rawEntries = await db.streamReflections().first;
    final entries = rawEntries.where((e) => !e.isDeleted).toList();

    final exportData = {
      'app': 'Daily Reflection',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'total_entries': entries.length,
      'entries': entries.map((e) => e.toMap()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }
}
