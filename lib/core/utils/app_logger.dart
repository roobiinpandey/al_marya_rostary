import 'package:flutter/foundation.dart';

/// Production-ready logging utility
/// Logs are only printed in debug mode, not in production
class AppLogger {
  static const String _prefix = '[Al Marya]';

  /// Log informational messages (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_prefix ℹ️ $tagPrefix$message');
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_prefix ✅ $tagPrefix$message');
    }
  }

  /// Log warning messages (debug and production)
  static void warning(String message, {String? tag}) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    debugPrint('$_prefix ⚠️ $tagPrefix$message');
  }

  /// Log error messages (debug and production)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    debugPrint('$_prefix ❌ $tagPrefix$message');
    if (error != null) {
      debugPrint('$_prefix Error details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$_prefix Stack trace: $stackTrace');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_prefix 🔍 $tagPrefix$message');
    }
  }

  /// Log network requests (only in debug mode)
  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_prefix 🌐 $tagPrefix$message');
    }
  }

  /// Log data operations (only in debug mode)
  static void data(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('$_prefix 💾 $tagPrefix$message');
    }
  }
}
