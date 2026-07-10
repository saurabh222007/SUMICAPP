import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// AppLogger acts as a wrapper around the 'logger' package.
/// Prevents printing log information in production/release mode to secure data and boost performance.
abstract class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,         // Number of stacktrace frames to print
      errorMethodCount: 8,    // Number of stacktrace frames if error
      lineLength: 80,         // Width of output lines
      colors: true,           // Colorized console logs
      printEmojis: true,      // Emojis for quick warning/error identification
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  /// Log debug messages.
  static void d(String message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }

  /// Log informational messages.
  static void i(String message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }

  /// Log warning messages.
  static void w(String message) {
    if (kDebugMode) {
      _logger.w(message);
    }
  }

  /// Log error messages with optional exception/stack trace.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
