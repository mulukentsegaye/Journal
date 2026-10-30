import 'package:flutter_test/flutter_test.dart' hide ErrorFormatter;
import 'package:daily_reflection/core/utils/error_formatter.dart';

void main() {
  group('ErrorFormatter Tests', () {
    test('formats AuthRetryableFetchException with 521 as server temporarily unavailable', () {
      const error = 'AuthRetryableFetchException(message: error code: 521, statusCode: 521)';
      expect(ErrorFormatter.format(error), 'Server temporarily unavailable.');
    });

    test('formats Cloudflare 5xx / Bad Gateway / Service Unavailable', () {
      expect(ErrorFormatter.format('502 Bad Gateway'), 'Server temporarily unavailable.');
      expect(ErrorFormatter.format('503 Service Unavailable'), 'Server temporarily unavailable.');
      expect(ErrorFormatter.format('504 Gateway Timeout'), 'Server temporarily unavailable.');
      expect(ErrorFormatter.format('Error 520: Web server is returning an unknown error'), 'Server temporarily unavailable.');
    });

    test('formats network and socket errors cleanly', () {
      expect(ErrorFormatter.format('SocketException: Failed host lookup'), 'Network connection unavailable.');
      expect(ErrorFormatter.format('ClientException: XMLHttpRequest error'), 'Network connection unavailable.');
    });

    test('formats timeout exceptions', () {
      expect(ErrorFormatter.format('TimeoutException after 0:00:10.000000: Task timed out'), 'Connection timed out. Please try again.');
    });

    test('formats database sync and RLS errors', () {
      expect(ErrorFormatter.format('PostgrestException(message: new row violates row-level security policy, code: 42501)'), 'Cloud sync permission error.');
      expect(ErrorFormatter.format('PostgrestException(message: Could not find the col column in the schema cache, code: PGRST204)'), 'Unable to sync with database.');
      expect(ErrorFormatter.format('duplicate key value violates unique constraint'), 'This entry already exists.');
    });

    test('formats auth errors cleanly and concisely', () {
      expect(ErrorFormatter.format('Invalid login credentials'), 'Invalid email or password.');
      expect(ErrorFormatter.format('User already registered'), 'Account already exists. Try signing in.');
      expect(ErrorFormatter.format('Email not confirmed'), 'Please confirm your email before signing in.');
      expect(ErrorFormatter.format('Password should be at least 6 characters'), 'Password must be at least 6 characters.');
      expect(ErrorFormatter.format('over_email_send_rate_limit'), 'Too many attempts. Please wait a moment.');
      expect(ErrorFormatter.format('Token has expired'), 'Session expired. Please sign in again.');
    });

    test('blocks raw technical exceptions from leaking to user', () {
      const technicalError = 'CustomDatabaseDriverException(details: {internal_code: 9942}, file: main.dart:12)';
      expect(ErrorFormatter.format(technicalError), 'Something went wrong. Please try again.');
    });

    test('allows safe human friendly plain text to pass through', () {
      expect(ErrorFormatter.format('Please select an entry first.'), 'Please select an entry first.');
    });
  });
}
