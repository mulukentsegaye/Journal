/// Centralized error translation and formatting utility for Daily Reflection.
/// Converts technical exceptions, platform messages, socket failures,
/// server outages, and database codes into clear, calm, user-friendly guidance.
class ErrorFormatter {
  ErrorFormatter._();

  /// Translates any error or exception into user-friendly human language.
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final raw = error.toString().trim();
    if (raw.isEmpty) return 'An unexpected error occurred. Please try again.';

    final lower = raw.toLowerCase();

    // 1. Server & Gateway & Status 5xx / 521 errors (e.g. Cloudflare / Supabase server outage or paused project)
    if (_isServerError(lower)) {
      return 'Server temporarily unavailable.';
    }

    // 2. Network / Connectivity / Socket / Host Lookup errors
    if (_isNetworkError(lower)) {
      return 'Network connection unavailable.';
    }

    // 3. Timeout errors
    if (_isTimeoutError(lower)) {
      return 'Connection timed out. Please try again.';
    }

    // 4. Database Sync & Access errors
    if (lower.contains('pgrst204') ||
        lower.contains('schema cache') ||
        lower.contains('could not find the') ||
        lower.contains('column of')) {
      return 'Unable to sync with database.';
    }

    if (lower.contains('42501') ||
        lower.contains('row-level security') ||
        lower.contains('using expression') ||
        lower.contains('forbidden') ||
        lower.contains('permission denied')) {
      return 'Cloud sync permission error.';
    }

    if (lower.contains('duplicate key') ||
        lower.contains('23505') ||
        lower.contains('already exists')) {
      return 'This entry already exists.';
    }

    // 5. Supabase Auth errors
    final authMessage = _formatAuthMessage(lower);
    if (authMessage != null) {
      return authMessage;
    }

    // 6. Photo & Media errors
    if (lower.contains('save photo') ||
        lower.contains('pathaccessexception') ||
        lower.contains('filesystemexception')) {
      return 'Could not save photo. Check device storage.';
    }

    if (_isPhotoError(lower)) {
      return 'Could not access camera or photos.';
    }

    if (lower.contains('failed to share pdf') ||
        lower.contains('failed to generate pdf') ||
        lower.contains('pdf')) {
      return 'Could not export PDF. Please try again.';
    }

    // 7. Voice & Speech Recognition errors
    final speechMessage = _formatSpeechMessage(lower);
    if (speechMessage != null) {
      return speechMessage;
    }

    // 8. Security / PIN / Biometric errors
    if (lower.contains('lockedout') || lower.contains('permanentlylockedout')) {
      return 'Too many attempts. Wait a moment or use PIN.';
    }

    // 9. Sanitize technical prefixes if safe
    final cleaned = _sanitizeRawMessage(raw);
    if (cleaned.isNotEmpty && !_looksLikeTechnicalCode(cleaned)) {
      return cleaned;
    }

    return 'Something went wrong. Please try again.';
  }

  static bool _isServerError(String lower) {
    return lower.contains('authretryablefetchexception') ||
        lower.contains('521') ||
        lower.contains('520') ||
        lower.contains('522') ||
        lower.contains('523') ||
        lower.contains('524') ||
        lower.contains('525') ||
        lower.contains('526') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('500') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout') ||
        lower.contains('web server is down') ||
        lower.contains('internal server error') ||
        lower.contains('server error') ||
        lower.contains('origin server') ||
        lower.contains('cloudflare') ||
        (lower.contains('retryable') && lower.contains('fetch'));
  }

  static bool _isNetworkError(String lower) {
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no such host is known') ||
        lower.contains('errno = 11001') ||
        lower.contains('errno = 7') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection closed') ||
        lower.contains('clientexception') ||
        lower.contains('httpexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('certificate_verify_failed') ||
        lower.contains('tlserror') ||
        lower.contains('software caused connection abort') ||
        lower.contains('networkrequestfailed') ||
        lower.contains('failed to connect') ||
        lower.contains('no internet') ||
        (lower.contains('supabase.co') &&
            (lower.contains('failed') ||
                lower.contains('error') ||
                lower.contains('os error')));
  }

  static bool _isTimeoutError(String lower) {
    return lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded');
  }

  static bool _isPhotoError(String lower) {
    return lower.contains('image_picker') ||
        lower.contains('photoviewer') ||
        lower.contains('pickimage') ||
        (lower.contains('permission') &&
            (lower.contains('camera') ||
                lower.contains('photo') ||
                lower.contains('storage')));
  }

  static String? _formatAuthMessage(String lower) {
    if (lower.contains('not signed in')) {
      return 'You are not signed in. Please sign in with your email to enable cloud sync.';
    }

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email or password')) {
      return 'Invalid email or password.';
    }

    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'Account already exists. Try signing in.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }

    if (lower.contains('valid email') || lower.contains('invalid email')) {
      return 'Please enter a valid email.';
    }

    if (lower.contains('password') &&
        (lower.contains('short') ||
            lower.contains('least 6') ||
            lower.contains('weak') ||
            lower.contains('6 characters'))) {
      return 'Password must be at least 6 characters.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit')) {
      return 'Too many attempts. Please wait a moment.';
    }

    if (lower.contains('user not found')) {
      return 'No account found with that email.';
    }

    if (lower.contains('token is expired') ||
        lower.contains('invalid_token') ||
        lower.contains('invalid token') ||
        lower.contains('jwt') ||
        lower.contains('session expired') ||
        lower.contains('token has expired')) {
      return 'Session expired. Please sign in again.';
    }

    if (lower.contains('password should be different')) {
      return 'New password must be different.';
    }

    if (lower.contains('anonymous sign-ins are disabled') ||
        (lower.contains('anonymous') && lower.contains('disabled'))) {
      return 'Guest login offline. Continuing locally.';
    }

    if (lower.contains('supabase is not configured')) {
      return 'Cloud service unavailable.';
    }

    return null;
  }

  static String? _formatSpeechMessage(String lower) {
    if (lower.contains('error_speech_timeout') || lower.contains('speech timeout')) {
      return 'Voice input timed out.';
    }
    if (lower.contains('error_no_match') || lower.contains('no speech match')) {
      return 'No speech recognized.';
    }
    if (lower.contains('error_audio_error') ||
        lower.contains('error_busy') ||
        lower.contains('error_listen_failed')) {
      return 'Microphone unavailable. Check permissions.';
    }
    return null;
  }

  static String _sanitizeRawMessage(String msg) {
    var s = msg;
    final prefixes = [
      'Exception: ',
      'ClientException: ',
      'PostgrestException: ',
      'AuthException: ',
      'AuthRetryableFetchException: ',
      'PlatformException: ',
      'FormatException: ',
      'StateError: ',
      'ArgumentError: ',
    ];

    for (final p in prefixes) {
      if (s.startsWith(p)) {
        s = s.substring(p.length).trim();
      }
    }

    if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
    }
    return s;
  }

  static bool _looksLikeTechnicalCode(String s) {
    final lower = s.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('error:') ||
        lower.contains('os error') ||
        lower.contains('errno =') ||
        lower.contains('errno:') ||
        lower.contains('uri=') ||
        lower.contains('http') ||
        lower.contains('stack trace') ||
        lower.contains('.dart') ||
        lower.contains('(') ||
        lower.contains(')') ||
        lower.contains('{') ||
        lower.contains('}') ||
        lower.contains('[') ||
        lower.contains(']') ||
        lower.contains('statuscode') ||
        lower.contains('status_code') ||
        lower.contains('error code') ||
        lower.contains('null') ||
        lower.contains('syntaxerror') ||
        lower.contains('postgrest') ||
        lower.contains('supabase') ||
        lower.contains('failed assertion:');
  }
}
