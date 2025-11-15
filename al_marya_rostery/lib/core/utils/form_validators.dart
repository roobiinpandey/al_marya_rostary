import 'package:flutter/services.dart';

/// Comprehensive form validation utilities for Al Marya Rostery app
/// Provides robust validation for user inputs to prevent crashes and errors
class FormValidators {
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }

    return null;
  }

  /// Phone number validation (UAE format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // UAE phone number patterns
    if (digitsOnly.length < 9 || digitsOnly.length > 12) {
      return 'Please enter a valid phone number';
    }

    // Common UAE patterns
    final uaePatterns = [
      RegExp(r'^(971)?[0-9]{9}$'), // Country code + 9 digits
      RegExp(r'^05[0-9]{8}$'), // Mobile format
      RegExp(r'^04[0-9]{7}$'), // Dubai landline
    ];

    if (!uaePatterns.any((pattern) => pattern.hasMatch(digitsOnly))) {
      return 'Please enter a valid UAE phone number';
    }

    return null;
  }

  /// Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Number validation
  static String? validateNumber(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = allowDecimals
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim())?.toDouble();

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  /// Price validation (AED)
  static String? validatePrice(String? value) {
    return validateNumber(
      value,
      fieldName: 'Price',
      min: 0.01,
      max: 10000.0,
      allowDecimals: true,
    );
  }

  /// Quantity validation
  static String? validateQuantity(String? value) {
    return validateNumber(
      value,
      fieldName: 'Quantity',
      min: 1,
      max: 999,
      allowDecimals: false,
    );
  }

  /// URL validation
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }

    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Please enter a valid URL';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }

    return null;
  }

  /// Product name validation
  static String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }

    if (value.trim().length < 3) {
      return 'Product name must be at least 3 characters long';
    }

    if (value.trim().length > 100) {
      return 'Product name must not exceed 100 characters';
    }

    return null;
  }

  /// Description validation
  static String? validateDescription(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Description is required' : null;
    }

    if (required && value.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }

    if (value.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Credit card number validation (basic)
  static String? validateCreditCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Please enter a valid card number';
    }

    // Luhn algorithm check
    if (!_isValidLuhn(digitsOnly)) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  /// CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 3 || digitsOnly.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }

    return null;
  }

  /// Expiry date validation (MM/YY)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    final dateRegex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!dateRegex.hasMatch(value.trim())) {
      return 'Please enter date in MM/YY format';
    }

    final parts = value.trim().split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');

    final now = DateTime.now();
    final expiryDate = DateTime(year, month);

    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }

    return null;
  }

  /// Luhn algorithm for credit card validation
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  /// Combine multiple validators
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

/// Input formatters for preventing invalid input
class SafeInputFormatters {
  /// Phone number formatter
  static List<TextInputFormatter> phoneNumber() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(12),
      _PhoneNumberFormatter(),
    ];
  }

  /// Currency formatter (AED)
  static List<TextInputFormatter> currency() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      LengthLimitingTextInputFormatter(10),
    ];
  }

  /// Name formatter (letters, spaces, hyphens, apostrophes only)
  static List<TextInputFormatter> name() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
      LengthLimitingTextInputFormatter(50),
    ];
  }

  /// Email formatter
  static List<TextInputFormatter> email() {
    return [
      FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      LengthLimitingTextInputFormatter(100),
    ];
  }

  /// Credit card formatter
  static List<TextInputFormatter> creditCard() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(19),
      _CreditCardFormatter(),
    ];
  }

  /// CVV formatter
  static List<TextInputFormatter> cvv() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ];
  }

  /// Expiry date formatter (MM/YY)
  static List<TextInputFormatter> expiryDate() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
      _ExpiryDateFormatter(),
    ];
  }
}

/// Custom phone number formatter
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length <= 3) {
      return newValue;
    }

    String formatted;
    if (text.length <= 6) {
      formatted = '${text.substring(0, 3)} ${text.substring(3)}';
    } else if (text.length <= 9) {
      formatted =
          '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
    } else {
      formatted =
          '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6, 9)} ${text.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Custom credit card formatter
class _CreditCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Custom expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2 ? text.substring(2) : '';
      final formatted = year.isEmpty ? month : '$month/$year';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}
