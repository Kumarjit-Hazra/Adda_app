import 'package:flutter/foundation.dart';

/// Lightweight, structured logger service for ADDA.
enum LogLevel { debug, info, warning, error }

class LoggerService {
  const LoggerService._();

  static void log(
    String tag,
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level == LogLevel.debug) return;

    final prefix = switch (level) {
      LogLevel.debug => '🔍 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '❌ [ERROR]',
    };

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('$prefix $timestamp [$tag] $message');
    if (error != null) {
      debugPrint('   Details: $error');
    }
    if (stackTrace != null && level == LogLevel.error) {
      debugPrint('   $stackTrace');
    }
  }

  static void d(String tag, String message) =>
      log(tag, message, level: LogLevel.debug);
  static void i(String tag, String message) =>
      log(tag, message, level: LogLevel.info);
  static void w(String tag, String message, [Object? error]) =>
      log(tag, message, level: LogLevel.warning, error: error);
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => log(
    tag,
    message,
    level: LogLevel.error,
    error: error,
    stackTrace: stackTrace,
  );
}
