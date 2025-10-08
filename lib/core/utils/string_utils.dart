/// Utility class for string manipulation and formatting
class StringUtils {
  /// Capitalizes the first letter of a string
  static String capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Capitalizes the first letter of each word in a string
  static String titleCase(String str) {
    if (str.isEmpty) return str;
    return str.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncates a string to a maximum length and adds an ellipsis if needed
  static String truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }

  /// Formats a currency amount (assumes AED)
  static String formatCurrency(double amount) {
    return 'AED ${amount.toStringAsFixed(2)}';
  }

  /// Removes special characters from a string
  static String removeSpecialCharacters(String str) {
    return str.replaceAll(RegExp(r'[^\w\s]+'), '');
  }

  /// Formats a phone number in UAE format
  static String formatUAEPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a UAE number
    if (digits.length == 9) {
      return '+971$digits';
    } else if (digits.length == 12 && digits.startsWith('971')) {
      return '+$digits';
    }

    // Return original if not in expected format
    return phone;
  }

  /// Generates initials from a full name
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '';

    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }

    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  /// Checks if a string is null, empty, or contains only whitespace
  static bool isNullOrEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }
}
