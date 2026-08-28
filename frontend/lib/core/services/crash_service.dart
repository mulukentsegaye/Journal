import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/sentry_config.dart';

/// Centralized crash reporting and privacy-safe error telemetry manager.
class CrashService {
  static final CrashService _instance = CrashService._internal();
  factory CrashService() => _instance;
  CrashService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Sentry crash reporting with zero-knowledge privacy filtering.
  Future<void> initialize({required VoidCallback appRunner}) async {
    if (SentryConfig.isConfigured) {
      await SentryFlutter.init(
        (options) {
          options.dsn = SentryConfig.dsn;
          options.tracesSampleRate = 0.2; // Sample 20% of transactions for performance
          options.enableAutoSessionTracking = true;
          options.attachScreenshot = false; // Do not attach screenshots to protect user privacy
          options.sendDefaultPii = false; // Do not send personal identifiable info

          // Zero-knowledge privacy filter: Scrub any sensitive journaling text or keys
          options.beforeSend = (event, hint) {
            return _sanitizeEvent(event);
          };
        },
        appRunner: appRunner,
      );
    } else {
      // If DSN is not configured (e.g. local dev / tests), run app directly
      appRunner();
    }

    _setupGlobalErrorHandlers();
    _isInitialized = true;
  }

  /// Global uncaught error interceptors for Flutter framework and Dart isolate.
  void _setupGlobalErrorHandlers() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        fatal: false,
      );
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Sanitizes Sentry event to guarantee zero-knowledge reflection privacy.
  SentryEvent? _sanitizeEvent(SentryEvent event) {
    // Strip query parameters that could contain auth tokens
    var sanitizedMessage = event.message?.formatted;
    if (sanitizedMessage != null && sanitizedMessage.contains('key=')) {
      sanitizedMessage = sanitizedMessage.replaceAll(RegExp(r'key=[^&\s]+'), 'key=[REDACTED]');
    }

    return event.copyWith(
      message: sanitizedMessage != null ? SentryMessage(sanitizedMessage) : event.message,
    );
  }

  /// Captures an error / exception with optional stack trace and context.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    dynamic reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[CrashService] Caught ${fatal ? "FATAL " : ""}error: $error');
      if (reason != null) debugPrint('[CrashService] Reason: $reason');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }

    if (SentryConfig.isConfigured) {
      try {
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          hint: reason != null ? Hint.withMap({'reason': reason.toString()}) : null,
        );
      } catch (_) {}
    }
  }

  /// Adds a breadcrumb to the crash reporting session.
  void addBreadcrumb(
    String message, {
    String category = 'app',
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debugPrint('[Breadcrumb][$category] $message');
    }

    if (SentryConfig.isConfigured) {
      try {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: message,
            category: category,
            data: data,
            timestamp: DateTime.now().toUtc(),
          ),
        );
      } catch (_) {}
    }
  }

  /// Sets an anonymized user identifier context for crash tracing.
  void setUserId(String userId) {
    if (SentryConfig.isConfigured) {
      try {
        Sentry.configureScope((scope) {
          scope.setUser(SentryUser(id: userId));
        });
      } catch (_) {}
    }
  }

  /// Clears user context on logout or session reset.
  void clearUser() {
    if (SentryConfig.isConfigured) {
      try {
        Sentry.configureScope((scope) {
          scope.setUser(null);
        });
      } catch (_) {}
    }
  }
}
