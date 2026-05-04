import 'package:flutter/services.dart';

/// Bridge to the Android [InferenceForegroundService].
///
/// On non-Android platforms, all methods are no-ops.
class ForegroundService {
  ForegroundService._();

  static const _channel = MethodChannel('app/inference_service');

  /// Start the foreground service with a generation notification.
  static Future<void> start(String turnId) async {
    try {
      await _channel.invokeMethod('start', {'turnId': turnId});
    } on MissingPluginException {
      // Not on Android — that's fine.
    }
  }

  /// Update the notification with generation progress.
  static Future<void> updateProgress(int tokensGenerated) async {
    try {
      await _channel.invokeMethod(
        'updateProgress',
        {'tokensGenerated': tokensGenerated},
      );
    } on MissingPluginException {
      // Not on Android.
    }
  }

  /// Stop the foreground service and dismiss the notification.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on MissingPluginException {
      // Not on Android.
    }
  }
}
