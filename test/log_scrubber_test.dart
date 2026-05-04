import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm_app/src/log_scrubber.dart';

void main() {
  group('sanitize', () {
    test('passes through normal strings unchanged', () {
      expect(sanitize('Hello, world!'), equals('Hello, world!'));
      expect(sanitize('general.architecture = gemma3n'), equals('general.architecture = gemma3n'));
    });

    test('redacts API keys', () {
      final result = sanitize('api_key = sk-1234567890abcdef');
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('sk-1234567890abcdef')));
    });

    test('redacts bearer tokens', () {
      const token = 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0';
      final result = sanitize(token);
      expect(result, contains('[REDACTED]'));
    });

    test('redacts secrets and passwords', () {
      final result = sanitize('password = super-secret-123');
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('super-secret-123')));
    });

    test('handles multiple sensitive patterns', () {
      final input = 'api_key = abc123 and token = xyz789';
      final result = sanitize(input);
      // Should redact both
      expect(result, contains('[REDACTED]'));
    });

    test('handles empty string', () {
      expect(sanitize(''), equals(''));
    });
  });

  group('containsSensitiveData', () {
    test('returns true for strings with secrets', () {
      expect(containsSensitiveData('api_key = secret123'), isTrue);
      expect(containsSensitiveData('token: abcdef123456'), isTrue);
    });

    test('returns false for normal strings', () {
      expect(containsSensitiveData('Hello, world!'), isFalse);
      expect(containsSensitiveData('model = gemma3n'), isFalse);
    });
  });
}
