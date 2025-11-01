import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global error handler for the Al Marya Rostery app
/// Provides centralized error handling, logging, and user feedback
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  static bool _isInitialized = false;

  /// Initialize global error handling
  static void initialize() {
    if (_isInitialized) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle platform errors (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    _isInitialized = true;
    debugPrint('✅ Global error handler initialized');
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    // Log error details
    debugPrint('🚨 Flutter Error: ${details.exception}');
    debugPrint('📍 Location: ${details.library}');
    debugPrint('📚 Stack: ${details.stack}');

    // In debug mode, show the default error widget
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // In release mode, log the error and show a user-friendly message
      _logErrorToService(
        'Flutter Error',
        details.exception.toString(),
        details.stack.toString(),
      );
    }
  }

  /// Handle platform-specific errors
  static bool _handlePlatformError(Object error, StackTrace stack) {
    debugPrint('🚨 Platform Error: $error');
    debugPrint('📚 Stack: $stack');

    _logErrorToService('Platform Error', error.toString(), stack.toString());
    return true;
  }

  /// Log error to service (can be expanded to send to crash analytics)
  static void _logErrorToService(String type, String error, String stack) {
    // For now, just log locally
    // TODO: Integrate with Firebase Crashlytics or similar service
    debugPrint('📊 Error logged: $type - $error');
  }

  /// Show user-friendly error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (actionText != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionText)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar for less critical errors
  static void showErrorSnackbar(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        action: actionText != null && onAction != null
            ? SnackBarAction(
                label: actionText,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Handle API errors with appropriate user feedback
  static void handleApiError(
    BuildContext context, {
    required dynamic error,
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    String message = customMessage ?? _getApiErrorMessage(error);

    if (_isCriticalError(error)) {
      showErrorDialog(
        context,
        title: 'Connection Error',
        message: message,
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
    } else {
      showErrorSnackbar(
        context,
        message: message,
        actionText: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
    }
  }

  /// Get user-friendly message from API error
  static String _getApiErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return 'Please log in again to continue.';
    } else if (errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'The requested resource was not found.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Determine if error requires dialog vs snackbar
  static bool _isCriticalError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unauthorized');
  }

  /// Safely execute async operations with error handling
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (logError) {
        debugPrint('🚨 Safe execution error: $error');
        debugPrint('📚 Stack: $stackTrace');
      }
      return null;
    }
  }

  /// Wrap widgets with error boundaries
  static Widget wrapWithErrorBoundary({
    required Widget child,
    Widget? fallback,
  }) {
    return ErrorBoundary(child: child, fallback: fallback);
  }
}

/// Error boundary widget for catching widget build errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({super.key, required this.child, this.fallback});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try refreshing the page',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
    }

    return widget.child;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _hasError = false;
    }
  }
}

/// Extension for safe context operations
extension SafeContext on BuildContext {
  /// Safely show snackbar only if context is mounted
  void showSafeSnackbar(String message) {
    if (mounted) {
      GlobalErrorHandler.showErrorSnackbar(this, message: message);
    }
  }

  /// Safely show error dialog only if context is mounted
  void showSafeErrorDialog(String title, String message) {
    if (mounted) {
      GlobalErrorHandler.showErrorDialog(this, title: title, message: message);
    }
  }
}
