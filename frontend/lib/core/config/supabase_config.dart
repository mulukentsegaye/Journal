/// Configuration parameters for connecting to Supabase.
///
/// You can supply credentials via `--dart-define` at build/run time:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
/// Or configure your project credentials directly in the defaults below.
class SupabaseConfig {
  /// Raw Supabase Project URL
  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hwvvtvqextfvgzoxnxdy.supabase.co',
  );

  /// Clean normalized Supabase Project URL (ensures no trailing slash or /rest/v1 suffix)
  static String get supabaseUrl {
    var url = _rawUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - '/rest/v1'.length);
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Supabase Anonymous Public API Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3dnZ0dnFleHRmdmd6b3hueGR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0MTc2NzksImV4cCI6MjEwMjk5MzY3OX0.AjU1rond8niy8QXLwhxOpfEzXubbB1higEwYjMm-kXA',
  );

  /// Helper to check if Supabase has been configured with real project credentials.
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('placeholder') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('placeholder');
  }
}
