import 'dart:io';
import 'package:flutter/foundation.dart';

/// Result of an email validation and typo check.
class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestedEmail;

  const EmailValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestedEmail,
  });

  const EmailValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        suggestedEmail = null;

  const EmailValidationResult.invalid(String message, {this.suggestedEmail})
      : isValid = false,
        errorMessage = message;
}

/// Utility for validating email syntax, catching domain typos,
/// and verifying domain existence via DNS before sending confirmation emails.
class EmailValidator {
  EmailValidator._();

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Map of common misspelled email domains to their correct versions.
  static const Map<String, String> _domainTypoMap = {
    // Gmail
    'gmial.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'gmaik.com': 'gmail.com',
    'gemail.com': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmail.cm': 'gmail.com',
    'gmaiol.com': 'gmail.com',
    'gmailc.om': 'gmail.com',
    'gmaild.com': 'gmail.com',
    'gmeil.com': 'gmail.com',
    'gmail.cpm': 'gmail.com',
    'gmaul.com': 'gmail.com',
    'gnail.com': 'gmail.com',

    // Yahoo
    'yaho.com': 'yahoo.com',
    'yahooo.com': 'yahoo.com',
    'yaho.co': 'yahoo.com',
    'yahoo.con': 'yahoo.com',
    'yaho.cm': 'yahoo.com',
    'yhoo.com': 'yahoo.com',
    'ymail.con': 'ymail.com',

    // Hotmail & Outlook
    'hotmial.com': 'hotmail.com',
    'hotmaill.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotmail.con': 'hotmail.com',
    'hotmail.co': 'hotmail.com',
    'outlok.com': 'outlook.com',
    'outloo.com': 'outlook.com',
    'outlock.com': 'outlook.com',
    'outlook.con': 'outlook.com',
    'ootlook.com': 'outlook.com',
    'outluk.com': 'outlook.com',

    // iCloud
    'iclud.com': 'icloud.com',
    'icld.com': 'icloud.com',
    'icoud.com': 'icloud.com',
    'icloud.con': 'icloud.com',
    'iclou.com': 'icloud.com',

    // Proton
    'protonmial.com': 'protonmail.com',
    'protonmai.com': 'protonmail.com',
  };

  /// Validates email syntax and detects common domain typos.
  static EmailValidationResult validateSyntax(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const EmailValidationResult.invalid('Please enter your email.');
    }

    if (!trimmed.contains('@')) {
      return const EmailValidationResult.invalid('Email must contain an @ symbol.');
    }

    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return const EmailValidationResult.invalid('Please enter a valid email.');
    }

    final username = parts[0];
    final domain = parts[1].toLowerCase();

    if (!_emailRegExp.hasMatch(trimmed)) {
      return const EmailValidationResult.invalid('Please enter a valid email.');
    }

    // Check for common domain typos
    final suggestedDomain = _domainTypoMap[domain];
    if (suggestedDomain != null) {
      final suggestedEmail = '$username@$suggestedDomain';
      return EmailValidationResult.invalid(
        'Did you mean @$suggestedDomain?',
        suggestedEmail: suggestedEmail,
      );
    }

    // Check domain extension (TLD)
    final domainParts = domain.split('.');
    if (domainParts.length < 2 || domainParts.last.length < 2) {
      return const EmailValidationResult.invalid('Invalid domain extension.');
    }

    return const EmailValidationResult.valid();
  }

  /// Checks if the email domain actually exists on the internet via DNS lookup.
  /// Returns null if valid / resolvable, or an error message if domain does not exist.
  static Future<String?> checkDomainExists(String email) async {
    if (kIsWeb) return null; // DNS lookup not available on web

    final trimmed = email.trim();
    if (!trimmed.contains('@')) return 'Invalid email address.';

    final domain = trimmed.split('@').last.toLowerCase().trim();

    try {
      final results = await InternetAddress.lookup(domain)
          .timeout(const Duration(seconds: 4));
      if (results.isEmpty || results.first.rawAddress.isEmpty) {
        return 'Email domain "$domain" does not exist.';
      }
    } on SocketException catch (_) {
      return 'Email domain "$domain" does not exist. Check spelling.';
    } catch (_) {
      // If timeout or other network issue, allow to proceed so users aren't blocked on slow connections
      return null;
    }

    return null;
  }
}
