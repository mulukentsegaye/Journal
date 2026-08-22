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

  /// Clean normalized Supabase Project URL (guarantees base origin e.g. https://xyz.supabase.co)
  static String get supabaseUrl {
    var raw = _rawUrl.trim();
    try {
      final uri = Uri.parse(raw);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        final portPart = uri.hasPort ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$portPart';
      }
    } catch (_) {}
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    if (raw.endsWith('/rest/v1')) {
      raw = raw.substring(0, raw.length - '/rest/v1'.length);
    }
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    return raw;
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
