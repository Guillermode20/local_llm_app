/// Log scrubbing utilities to prevent sensitive data from appearing in logs.
///
/// Use [sanitize] before passing user-provided strings to any logging call
/// to redact potentially sensitive patterns (API keys, tokens, file paths).
library;

/// Patterns that indicate sensitive data and should be redacted.
final _sensitivePatterns = <RegExp>[
  RegExp(r'(api[_-]?key|apikey|secret|token|password|passwd)\s*[:=]\s*\S+',
      caseSensitive: false),
  RegExp(r'bearer\s+[a-z0-9._\-+/~=]{20,}', caseSensitive: false),
  RegExp(r'sk-[a-z0-9]{20,}', caseSensitive: false),
  RegExp(r'\b[a-f0-9]{40}\b'), // SHA-1 hashes
];

/// Redact sensitive patterns from [input].
///
/// Returns the sanitized string with matched secrets replaced by `[REDACTED]`.
/// Returns the original string if no patterns match.
String sanitize(String input) {
  var result = input;
  for (final pattern in _sensitivePatterns) {
    result = result.replaceAll(pattern, '[REDACTED]');
  }
  return result;
}

/// Check whether [input] contains any patterns that look like secrets.
bool containsSensitiveData(String input) {
  return _sensitivePatterns.any((p) => p.hasMatch(input));
}
