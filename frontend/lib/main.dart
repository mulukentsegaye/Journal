import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/crash_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/security_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/reflection/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Crash Reporting and Error Telemetry
  await CrashService().initialize(
    appRunner: () async {
      // Initialize notifications & timezone support
      await NotificationService().initialize();

      // Initialize Supabase if configured, or fail gracefully to local-first mode
      if (SupabaseConfig.isConfigured) {
        try {
          await Supabase.initialize(
            url: SupabaseConfig.supabaseUrl,
            // ignore: deprecated_member_use
            anonKey: SupabaseConfig.supabaseAnonKey,
          );
        } catch (e, st) {
          CrashService().recordError(e, st, reason: 'Supabase initialization failed');
        }
      }

      await AuthService().loadSession();
      await DatabaseService().migrateUnscopedCache();
      await SettingsService().loadSettings();
      await SecurityService().loadSecuritySettings();

      runApp(const DailyReflectionApp());
    },
  );
}
