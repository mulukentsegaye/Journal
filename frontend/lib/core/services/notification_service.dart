import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service responsible for managing local push notifications and daily reflection reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int reminderNotificationId = 1001;
  static const int eveningReminderNotificationId = 1001;
  static const int morningReminderNotificationId = 1002;
  static const int testNotificationId = 9999;
  static const String channelId = 'daily_reflection_reminder';
  static const String channelName = 'Daily Reflection Reminders';
  static const String channelDescription =
      'Daily evening reminders to reflect and journal';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Whether local notifications are supported on the current platform.
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux);

  /// Callback when a user interacts with a notification
  void Function(String? payload)? onNotificationTapped;

  /// Initialize local notification plugin and configure timezones.
  Future<void> initialize({void Function(String? payload)? onTapped}) async {
    if (_isInitialized) return;
    onNotificationTapped = onTapped;

    if (!isSupportedPlatform) {
      _isInitialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      await _configureLocalTimeZone();

      // 2. Setup platform-specific initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (onNotificationTapped != null) {
            onNotificationTapped!(response.payload);
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// Resolve and configure device local timezone with graceful fallback.
  Future<void> _configureLocalTimeZone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Could not set local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Request runtime permissions for notifications on Android (13+) and iOS/macOS.
  Future<bool> requestPermissions() async {
    if (!isSupportedPlatform) return true;
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final granted =
              await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      } else if (Platform.isMacOS) {
        final macOSPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();

        if (macOSPlugin != null) {
          final granted = await macOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission request error: $e');
      return false;
    }
  }

  /// Check whether notification permissions are granted.
  Future<bool> areNotificationsEnabled() async {
    if (!isSupportedPlatform) return true;
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Default notification details across platforms.
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Calculate next TZDateTime instance for a given TimeOfDay in the local timezone.
  tz.TZDateTime nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule a repeating daily reflection reminder at [time].
  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    if (!isSupportedPlatform) {
      debugPrint('Daily reminders not supported on this platform.');
      return false;
    }
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Request notification permissions if not already granted
      await requestPermissions();

      // Cancel any existing reminder first
      await cancelReminder();

      final scheduledTime = nextInstanceOfTime(time);

      await _notificationsPlugin.zonedSchedule(
        id: reminderNotificationId,
        title: 'Time to Reflect 🌙',
        body: 'Take a quiet moment to record your thoughts and unwind for today.',
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'evening_reflection_reminder',
      );

      debugPrint('Daily reflection reminder scheduled for: $scheduledTime');
      return true;
    } catch (e) {
      debugPrint('Failed to schedule daily reflection reminder: $e');
      return false;
    }
  }

  /// Cancel the scheduled evening reflection reminder.
  Future<void> cancelReminder() async {
    if (!isSupportedPlatform) return;
    try {
      await _notificationsPlugin.cancel(id: reminderNotificationId);
      debugPrint('Daily reflection reminder cancelled.');
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }

  /// Schedule morning intention reminder at [time].
  Future<bool> scheduleMorningReminder(TimeOfDay time) async {
    if (!isSupportedPlatform) {
      debugPrint('Morning reminders not supported on this platform.');
      return false;
    }
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await requestPermissions();
      await cancelMorningReminder();

      final scheduledTime = nextInstanceOfTime(time);

      await _notificationsPlugin.zonedSchedule(
        id: morningReminderNotificationId,
        title: 'Morning Intention ☀️',
        body: 'Start your day with clarity. What are your intentions for today?',
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning_intention_reminder',
      );

      debugPrint('Morning reminder scheduled for: $scheduledTime');
      return true;
    } catch (e) {
      debugPrint('Failed to schedule morning reminder: $e');
      return false;
    }
  }

  /// Cancel scheduled morning intention reminder.
  Future<void> cancelMorningReminder() async {
    if (!isSupportedPlatform) return;
    try {
      await _notificationsPlugin.cancel(id: morningReminderNotificationId);
      debugPrint('Morning reminder cancelled.');
    } catch (e) {
      debugPrint('Failed to cancel morning reminder: $e');
    }
  }

  /// Schedule evening reflection reminder.
  Future<bool> scheduleEveningReminder(TimeOfDay time) =>
      scheduleDailyReminder(time);

  /// Cancel evening reflection reminder.
  Future<void> cancelEveningReminder() => cancelReminder();

  /// Send an immediate test notification to verify delivery and permissions.
  Future<bool> sendTestNotification({bool isMorning = false}) async {
    if (!isSupportedPlatform) {
      debugPrint('Test notifications not supported on this platform.');
      return false;
    }
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await requestPermissions();

      await _notificationsPlugin.show(
        id: testNotificationId,
        title: isMorning
            ? 'Morning Intention Preview ☀️'
            : 'Reflection Reminder Preview ✨',
        body: isMorning
            ? 'Start your day with clarity. What are your intentions for today? 🌿'
            : 'Take a quiet moment to record your thoughts and unwind for today. 🌙',
        notificationDetails: _notificationDetails(),
        payload: isMorning ? 'test_morning' : 'test_notification',
      );
      return true;
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
      return false;
    }
  }
}
