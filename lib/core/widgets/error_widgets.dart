import 'package:flutter/material.dart';

/// Comprehensive error widgets for the Al Marya Rostery app
/// Provides consistent error UI components across the app

/// Generic error display widget
class ErrorDisplayWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? backgroundColor;
  final bool showDetails;
  final String? details;

  const ErrorDisplayWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.backgroundColor,
    this.showDetails = false,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: backgroundColor ?? Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (showDetails && details != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Error Details'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    details!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Network error specific widget
class NetworkErrorWidget extends StatelessWidget {
  final String? customMessage;
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.customMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      message:
          customMessage ??
          'Please check your internet connection and try again.',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}

/// Loading error widget for API calls
class ApiErrorWidget extends StatelessWidget {
  final String? customMessage;
  final VoidCallback? onRetry;
  final String? errorDetails;

  const ApiErrorWidget({
    super.key,
    this.customMessage,
    this.onRetry,
    this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      icon: Icons.cloud_off,
      title: 'Failed to Load Data',
      message:
          customMessage ??
          'Something went wrong while loading data. Please try again.',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      showDetails: errorDetails != null,
      details: errorDetails,
    );
  }
}

/// Empty state widget (not exactly an error, but related)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact error widget for list items
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CompactErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[800], fontSize: 14),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Error boundary widget that catches errors in subtrees
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }

      return ErrorDisplayWidget(
        title: 'Something went wrong',
        message: 'An unexpected error occurred. Please try again.',
        actionText: 'Reset',
        onAction: () {
          setState(() {
            _error = null;
          });
        },
      );
    }

    return widget.child;
  }

  void catchError(Object error) {
    setState(() {
      _error = error;
    });
  }
}

/// Form validation error widget
class FormErrorWidget extends StatelessWidget {
  final List<String> errors;
  final VoidCallback? onDismiss;

  const FormErrorWidget({super.key, required this.errors, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Please fix the following errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                '• $error',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar helpers for errors
class ErrorSnackbars {
  static void showError(
    BuildContext context, {
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
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

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Loading state with error fallback
class LoadingWithErrorWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final Widget child;
  final VoidCallback? onRetry;

  const LoadingWithErrorWidget({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return ApiErrorWidget(customMessage: errorMessage, onRetry: onRetry);
    }

    return child;
  }
}
