/// Centralized error translation and formatting utility for Daily Reflection.
/// Converts technical exceptions, platform messages, socket failures,
/// and database codes into clear, calm, human-understandable guidance.
class ErrorFormatter {
  ErrorFormatter._();

  /// Translates any error or exception into user-friendly human language.
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final raw = error.toString().trim();
    if (raw.isEmpty) return 'An unexpected error occurred. Please try again.';

    // 1. Network / Connectivity / Socket / Host Lookup errors
    if (_isNetworkError(raw)) {
      return 'Network connection unavailable. Please check your internet connection and try again.';
    }

    // 2. Timeout errors
    if (_isTimeoutError(raw)) {
      return 'The connection timed out. Please check your internet connection and try again.';
    }

    // 3. Supabase Database Schema & RLS errors
    if (raw.contains('PGRST204') ||
        raw.contains('schema cache') ||
        raw.contains('Could not find the') ||
        raw.contains('column of')) {
      return 'Database schema missing columns. Please run db/fix_rls_error.sql in your Supabase SQL Editor.';
    }

    if (raw.contains('42501') ||
        raw.contains('row-level security') ||
        raw.contains('USING expression') ||
        raw.contains('Forbidden') ||
        raw.contains('permission denied for table')) {
      return 'Database permission error (42501): Supabase RLS policy violation. Please run db/fix_rls_error.sql in your Supabase SQL Editor.';
    }

    if (raw.contains('duplicate key') ||
        raw.contains('23505') ||
        raw.contains('already exists')) {
      return 'This entry already exists. Please try again or refresh your data.';
    }

    // 4. Supabase Auth errors
    final authMessage = _formatAuthMessage(raw);
    if (authMessage != null) {
      return authMessage;
    }

    // 5. Photo & Media errors
    if (raw.toLowerCase().contains('save photo') ||
        raw.toLowerCase().contains('pathaccessexception') ||
        raw.toLowerCase().contains('filesystemexception')) {
      return 'Could not save photo to your device. Please check storage permissions.';
    }

    if (_isPhotoError(raw)) {
      return 'Could not access photo. Please check your camera and gallery permissions.';
    }

    if (raw.contains('Failed to share PDF') ||
        raw.contains('Failed to generate PDF') ||
        raw.contains('pdf')) {
      return 'Unable to generate or share the PDF keepsake. Please try again.';
    }

    // 6. Voice & Speech Recognition errors
    final speechMessage = _formatSpeechMessage(raw);
    if (speechMessage != null) {
      return speechMessage;
    }

    // 7. Security / PIN / Biometric errors
    if (raw.contains('LockedOut') || raw.contains('PermanentlyLockedOut')) {
      return 'Too many incorrect attempts. Please wait a moment or use your PIN.';
    }

    // 8. Sanitize technical prefixes if safe
    final cleaned = _sanitizeRawMessage(raw);
    if (cleaned.isNotEmpty && !_looksLikeStackTraceOrCode(cleaned)) {
      return cleaned;
    }

    return 'Something went wrong. Please try again in a moment.';
  }

  static bool _isNetworkError(String msg) {
    final lower = msg.toLowerCase();
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

  static bool _isTimeoutError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded');
  }

  static bool _isPhotoError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('image_picker') ||
        lower.contains('photoviewer') ||
        lower.contains('pickimage') ||
        (lower.contains('permission') &&
            (lower.contains('camera') ||
                lower.contains('photo') ||
                lower.contains('storage')));
  }

  static String? _formatAuthMessage(String msg) {
    final lower = msg.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email or password')) {
      return 'Invalid email or password. Please check and try again.';
    }

    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Your email has not been confirmed yet. Please check your inbox for the confirmation link.';
    }

    if (lower.contains('valid email') || lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (lower.contains('password') &&
        (lower.contains('short') ||
            lower.contains('least 6') ||
            lower.contains('weak') ||
            lower.contains('6 characters'))) {
      return 'Password must be at least 6 characters long.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit')) {
      return 'Too many attempts in a short time. Please wait a moment and try again.';
    }

    if (lower.contains('user not found')) {
      return 'No account was found with that email address.';
    }

    if (lower.contains('token is expired') ||
        lower.contains('invalid_token') ||
        lower.contains('invalid token') ||
        lower.contains('jwt') ||
        lower.contains('session expired') ||
        lower.contains('token has expired')) {
      return 'Session expired. Please sign out and sign back in to continue syncing.';
    }

    if (lower.contains('password should be different')) {
      return 'New password must be different from your current password.';
    }

    if (lower.contains('anonymous sign-ins are disabled') ||
        (lower.contains('anonymous') && lower.contains('disabled'))) {
      return 'Guest login is currently offline on the cloud. You can continue locally.';
    }

    if (lower.contains('supabase is not configured')) {
      return 'Cloud service is not configured. Please use Guest Mode to continue offline.';
    }

    return null;
  }

  static String? _formatSpeechMessage(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('error_speech_timeout') || lower.contains('speech timeout')) {
      return 'Voice input timed out. Tap the microphone to try speaking again.';
    }
    if (lower.contains('error_no_match') || lower.contains('no speech match')) {
      return 'No speech recognized. Please speak closer to your microphone and try again.';
    }
    if (lower.contains('error_audio_error') ||
        lower.contains('error_busy') ||
        lower.contains('error_listen_failed')) {
      return 'Microphone unavailable. Please check microphone permissions and try again.';
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

  static bool _looksLikeStackTraceOrCode(String s) {
    final lower = s.toLowerCase();
    return lower.contains('os error:') ||
        lower.contains('errno =') ||
        lower.contains('uri=http') ||
        lower.contains('stack trace') ||
        lower.contains('.dart:') ||
        lower.contains('postgrestexception(') ||
        lower.contains('authexception(') ||
        lower.contains('socketexception:');
  }
}
