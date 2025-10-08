import 'package:flutter/material.dart';

/// A primary button widget used consistently across the app
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button widget
  const PrimaryButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    super.key,
  });

  /// The callback when button is pressed
  final VoidCallback onPressed;

  /// The child widget inside the button
  final Widget child;

  /// Whether the button is in loading state
  final bool isLoading;

  /// The width of the button
  final double width;

  /// The height of the button
  final double height;

  /// The border radius of the button
  final double borderRadius;

  /// The background color of the button
  final Color? backgroundColor;

  /// The foreground color of the button
  final Color? foregroundColor;

  /// The padding of the button
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                child: child,
              ),
      ),
    );
  }
}
