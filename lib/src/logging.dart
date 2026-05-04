/// Structured logging utilities for the Local LLM App.
///
/// Provides a lightweight structured logger using [log] levels and
/// tag-based filtering. In production, this can be swapped for a
/// dedicated logging library (e.g., winston/pino/structlog equivalents).
library;

import 'dart:developer' as developer;

/// Log severity levels.
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  const LogLevel(this.value);
  final int value;
}

/// The active log threshold. Messages below this level are suppressed.
LogLevel _currentLevel = LogLevel.info;

/// Set the minimum [LogLevel] to display.
void setLogLevel(LogLevel level) {
  _currentLevel = level;
}

/// Get the current minimum log level.
LogLevel get currentLogLevel => _currentLevel;

/// Emit a structured log entry with [message], optional [tag] for
/// filtering, and optional [error] / [stackTrace] for exception context.
void log(
  LogLevel level,
  String message, {
  String tag = 'app',
  Object? error,
  StackTrace? stackTrace,
}) {
  if (level.value < _currentLevel.value) return;
  final ts = DateTime.now().toIso8601String();
  final prefix = level.name.toUpperCase();
  // ignore: avoid_print
  print('[$ts] [$prefix] [$tag] $message');
  if (error != null) {
    // ignore: avoid_print
    print('  Error: $error');
  }
  if (stackTrace != null) {
    developer.log(message, error: error, stackTrace: stackTrace);
  }
}

/// Convenience for debug-level messages.
void logDebug(String message, {String tag = 'app'}) =>
    log(LogLevel.debug, message, tag: tag);

/// Convenience for info-level messages.
void logInfo(String message, {String tag = 'app'}) =>
    log(LogLevel.info, message, tag: tag);

/// Convenience for warning-level messages.
void logWarning(String message, {String tag = 'app', Object? error}) =>
    log(LogLevel.warning, message, tag: tag, error: error);

/// Convenience for error-level messages.
void logError(
  String message, {
  String tag = 'app',
  Object? error,
  StackTrace? stackTrace,
}) =>
    log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
