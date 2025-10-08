import 'package:intl/intl.dart';

/// Utility class for date formatting and manipulation
class AppDateUtils {
  static final DateFormat _standardDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _standardDateTimeFormat = DateFormat(
    'yyyy-MM-dd HH:mm:ss',
  );
  static final DateFormat _friendlyDateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _friendlyDateTimeFormat = DateFormat(
    'MMM dd, yyyy HH:mm',
  );

  /// Format a date to standard ISO format (yyyy-MM-dd)
  static String formatStandardDate(DateTime date) {
    return _standardDateFormat.format(date);
  }

  /// Format a date to standard ISO format with time (yyyy-MM-dd HH:mm:ss)
  static String formatStandardDateTime(DateTime date) {
    return _standardDateTimeFormat.format(date);
  }

  /// Format a date to friendly format (MMM dd, yyyy)
  static String formatFriendlyDate(DateTime date) {
    return _friendlyDateFormat.format(date);
  }

  /// Format a date to friendly format with time (MMM dd, yyyy HH:mm)
  static String formatFriendlyDateTime(DateTime date) {
    return _friendlyDateTimeFormat.format(date);
  }

  /// Parse a date string in standard ISO format (yyyy-MM-dd)
  static DateTime? parseStandardDate(String date) {
    try {
      return _standardDateFormat.parse(date);
    } catch (e) {
      return null;
    }
  }

  /// Parse a date string in standard ISO format with time (yyyy-MM-dd HH:mm:ss)
  static DateTime? parseStandardDateTime(String date) {
    try {
      return _standardDateTimeFormat.parse(date);
    } catch (e) {
      return null;
    }
  }

  /// Get a friendly relative time string (e.g., "2 hours ago", "5 days ago")
  static String getRelativeTimeString(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
