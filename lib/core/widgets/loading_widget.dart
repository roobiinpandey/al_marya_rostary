import 'package:flutter/material.dart';

/// A loading widget used consistently across the app
class LoadingWidget extends StatelessWidget {
  /// Creates a loading widget with an optional message
  const LoadingWidget({this.message, this.color, super.key});

  /// The message to display below the loading indicator
  final String? message;

  /// The color of the loading indicator
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color ?? Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A full screen loading widget with overlay
class FullScreenLoading extends StatelessWidget {
  /// Creates a full screen loading widget with an optional message
  const FullScreenLoading({this.message, this.color, super.key});

  /// The message to display below the loading indicator
  final String? message;

  /// The color of the loading indicator
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: LoadingWidget(message: message, color: color ?? Colors.white),
    );
  }
}
