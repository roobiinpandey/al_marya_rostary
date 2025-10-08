import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom text form field widget used consistently across the app
class AppTextField extends StatelessWidget {
  /// Creates a custom text form field widget
  const AppTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.hintText,
    this.helperText,
    this.errorText,
    this.borderRadius = 12.0,
    super.key,
  }) : assert(
         controller == null || initialValue == null,
         'Cannot provide both a controller and an initialValue',
       );

  /// The label text for the field
  final String label;

  /// The controller for the text field
  final TextEditingController? controller;

  /// The initial value for the field
  final String? initialValue;

  /// The validator function for the field
  final String? Function(String?)? validator;

  /// Callback when the text changes
  final ValueChanged<String>? onChanged;

  /// Callback when the field is saved
  final ValueChanged<String?>? onSaved;

  /// The keyboard type for the field
  final TextInputType? keyboardType;

  /// The action to take when the input action button is pressed
  final TextInputAction? textInputAction;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// The maximum number of lines for the field
  final int? maxLines;

  /// The minimum number of lines for the field
  final int? minLines;

  /// The maximum length of the text
  final int? maxLength;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether to autofocus the field
  final bool autofocus;

  /// The icon to show before the input field
  final Widget? prefixIcon;

  /// The icon to show after the input field
  final Widget? suffixIcon;

  /// List of input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// The hint text to show when the field is empty
  final String? hintText;

  /// The helper text to show below the field
  final String? helperText;

  /// The error text to show below the field
  final String? errorText;

  /// The border radius of the field
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}
