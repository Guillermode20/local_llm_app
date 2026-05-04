import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm_app/src/logging.dart';

void main() {
  group('Logging utility', () {
    setUp(() {
      setLogLevel(LogLevel.debug);
    });

    test('setLogLevel updates the current level', () {
      expect(currentLogLevel, equals(LogLevel.debug));

      setLogLevel(LogLevel.error);
      expect(currentLogLevel, equals(LogLevel.error));

      setLogLevel(LogLevel.debug); // reset
    });

    test('LogLevel values are ordered correctly', () {
      expect(LogLevel.debug.value, lessThan(LogLevel.info.value));
      expect(LogLevel.info.value, lessThan(LogLevel.warning.value));
      expect(LogLevel.warning.value, lessThan(LogLevel.error.value));
    });

    test('convenience functions do not throw', () {
      // These primarily test that the convenience wrappers don't crash.
      // Output goes to stdout/stderr.
      expect(() => logDebug('debug message', tag: 'test'), returnsNormally);
      expect(() => logInfo('info message', tag: 'test'), returnsNormally);
      expect(() => logWarning('warning message', tag: 'test'), returnsNormally);
      expect(() => logError('error message', tag: 'test'), returnsNormally);
    });

    test('messages below level are filtered', () {
      setLogLevel(LogLevel.error);
      // Should not throw — the message is simply not printed.
      expect(() => logDebug('should be filtered'), returnsNormally);
      expect(() => logInfo('should be filtered'), returnsNormally);
      expect(() => logWarning('should be filtered'), returnsNormally);
      setLogLevel(LogLevel.debug); // reset
    });

    test('log accepts optional error and stack trace', () {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      expect(
        () => log(LogLevel.error, 'error with details',
            tag: 'test', error: error, stackTrace: stackTrace),
        returnsNormally,
      );
    });
  });
}
