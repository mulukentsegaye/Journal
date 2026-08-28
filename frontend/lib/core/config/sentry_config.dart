/// Configuration parameters for Sentry Crash Reporting & Telemetry.
///
/// Supply a custom Sentry DSN via `--dart-define` at build/run time:
/// ```bash
/// flutter run --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
/// ```
class SentryConfig {
  static const String _rawDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Sentry DSN (Data Source Name)
  static String get dsn => _rawDsn.trim();

  /// Whether Sentry DSN is configured
  static bool get isConfigured =>
      dsn.isNotEmpty &&
      !dsn.contains('placeholder') &&
      !dsn.contains('examplePublicKey');
}
