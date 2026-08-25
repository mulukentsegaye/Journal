import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:daily_reflection/core/services/notification_service.dart';
import 'package:daily_reflection/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('NotificationService Tests', () {
    test('singleton instance returns same instance', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    test('constants are correctly configured', () {
      expect(NotificationService.reminderNotificationId, equals(1001));
      expect(NotificationService.testNotificationId, equals(9999));
      expect(NotificationService.channelId, equals('daily_reflection_reminder'));
      expect(NotificationService.channelName, equals('Daily Reflection Reminders'));
    });

    test('nextInstanceOfTime schedules future time correctly', () {
      final service = NotificationService();
      const testTime = TimeOfDay(hour: 20, minute: 30);
      final scheduled = service.nextInstanceOfTime(testTime);

      expect(scheduled.hour, equals(20));
      expect(scheduled.minute, equals(30));
      expect(scheduled.isAfter(tz.TZDateTime.now(tz.local).subtract(const Duration(seconds: 1))), isTrue);
    });
  });

  group('SettingsService Reminder Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default reminder settings', () async {
      final settings = SettingsService();
      await settings.loadSettings();

      expect(settings.reminderEnabled, isTrue);
      expect(settings.reminderTime.hour, equals(18));
      expect(settings.reminderTime.minute, equals(0));
      expect(settings.formattedReminderTime, equals('6:00 PM'));
    });

    test('setReminderEnabled updates state', () async {
      final settings = SettingsService();
      await settings.loadSettings();

      await settings.setReminderEnabled(false);
      expect(settings.reminderEnabled, isFalse);

      await settings.setReminderEnabled(true);
      expect(settings.reminderEnabled, isTrue);
    });

    test('setReminderTime updates time and formatted time', () async {
      final settings = SettingsService();
      await settings.loadSettings();

      await settings.setReminderTime(const TimeOfDay(hour: 21, minute: 15));
      expect(settings.reminderTime.hour, equals(21));
      expect(settings.reminderTime.minute, equals(15));
      expect(settings.formattedReminderTime, equals('9:15 PM'));
    });
  });
}
