import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reflection/core/utils/email_validator.dart';

void main() {
  group('EmailValidator Tests', () {
    test('validates correct email syntax', () {
      final res1 = EmailValidator.validateSyntax('user@gmail.com');
      expect(res1.isValid, isTrue);
      expect(res1.suggestedEmail, isNull);

      final res2 = EmailValidator.validateSyntax('first.last@company.org');
      expect(res2.isValid, isTrue);

      final res3 = EmailValidator.validateSyntax('student_123@university.edu');
      expect(res3.isValid, isTrue);
    });

    test('rejects empty or malformed emails', () {
      expect(EmailValidator.validateSyntax('').isValid, isFalse);
      expect(EmailValidator.validateSyntax('   ').isValid, isFalse);
      expect(EmailValidator.validateSyntax('plainaddress').isValid, isFalse);
      expect(EmailValidator.validateSyntax('@missinguser.com').isValid, isFalse);
      expect(EmailValidator.validateSyntax('user@').isValid, isFalse);
      expect(EmailValidator.validateSyntax('user@domain').isValid, isFalse);
    });

    test('detects common typos for Gmail domains', () {
      final res1 = EmailValidator.validateSyntax('john.doe@gmial.com');
      expect(res1.isValid, isFalse);
      expect(res1.suggestedEmail, 'john.doe@gmail.com');
      expect(res1.errorMessage, contains('@gmail.com'));

      final res2 = EmailValidator.validateSyntax('test@gmaill.com');
      expect(res2.suggestedEmail, 'test@gmail.com');

      final res3 = EmailValidator.validateSyntax('user@gamil.com');
      expect(res3.suggestedEmail, 'user@gmail.com');

      final res4 = EmailValidator.validateSyntax('user@gmail.con');
      expect(res4.suggestedEmail, 'user@gmail.com');
    });

    test('detects common typos for Yahoo, Hotmail, Outlook, and iCloud domains', () {
      final yahoo = EmailValidator.validateSyntax('user@yaho.com');
      expect(yahoo.suggestedEmail, 'user@yahoo.com');

      final hotmail = EmailValidator.validateSyntax('user@hotmial.com');
      expect(hotmail.suggestedEmail, 'user@hotmail.com');

      final outlook = EmailValidator.validateSyntax('user@outlok.com');
      expect(outlook.suggestedEmail, 'user@outlook.com');

      final icloud = EmailValidator.validateSyntax('user@iclud.com');
      expect(icloud.suggestedEmail, 'user@icloud.com');
    });

    test('checkDomainExists identifies nonexistent domains via DNS lookup', () async {
      final error = await EmailValidator.checkDomainExists('test@thisdomaindoesnotexist999888777111.xyz');
      expect(error, isNotNull);
      expect(error, contains('does not exist'));
    });

    test('checkDomainExists succeeds for known real domains', () async {
      final error = await EmailValidator.checkDomainExists('test@google.com');
      expect(error, isNull);
    });
  });
}
