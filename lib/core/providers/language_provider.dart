import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _directionKey = 'app_direction';

  Locale _locale = const Locale('en');
  TextDirection _textDirection = TextDirection.ltr;
  bool _isRTL = false;
  bool _isLoading = true;

  Locale get locale => _locale;
  TextDirection get textDirection => _textDirection;
  bool get isRTL => _isRTL;
  bool get isLoading => _isLoading;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ar', 'AE'), // Arabic (UAE)
  ];

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';

      await setLanguage(languageCode, notify: false);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback to English if there's an error
      _locale = const Locale('en');
      _textDirection = TextDirection.ltr;
      _isRTL = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode, {bool notify = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update locale
      _locale = Locale(languageCode);

      // Update text direction based on language
      _isRTL = languageCode == 'ar';
      _textDirection = _isRTL ? TextDirection.rtl : TextDirection.ltr;

      // Save to preferences
      await prefs.setString(_languageKey, languageCode);
      await prefs.setBool(_directionKey, _isRTL);

      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguageCode = _locale.languageCode == 'en' ? 'ar' : 'en';
    await setLanguage(newLanguageCode);
  }

  // Get the appropriate locale for the system
  static Locale getSystemLocale() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;

    // Check if system locale is supported
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == systemLocale.languageCode) {
        return supportedLocale;
      }
    }

    // Default to English if system locale is not supported
    return const Locale('en', 'US');
  }

  // Resolve locale for the app
  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return const Locale('en', 'US');
    }

    // Try to find exact match
    for (final supportedLocale in supportedLocales) {
      if (locale.languageCode == supportedLocale.languageCode &&
          locale.countryCode == supportedLocale.countryCode) {
        return supportedLocale;
      }
    }

    // Try to find language match
    for (final supportedLocale in supportedLocales) {
      if (locale.languageCode == supportedLocale.languageCode) {
        return supportedLocale;
      }
    }

    // Default to English
    return const Locale('en', 'US');
  }

  // Helper methods for RTL-aware layouts
  EdgeInsets getHorizontalPadding(double value) {
    return EdgeInsets.symmetric(horizontal: value);
  }

  EdgeInsets getAsymmetricPadding({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) {
    if (_isRTL) {
      return EdgeInsets.only(left: end, right: start, top: top, bottom: bottom);
    } else {
      return EdgeInsets.only(left: start, right: end, top: top, bottom: bottom);
    }
  }

  // Get appropriate alignment for RTL/LTR
  Alignment getStartAlignment() {
    return _isRTL ? Alignment.centerRight : Alignment.centerLeft;
  }

  Alignment getEndAlignment() {
    return _isRTL ? Alignment.centerLeft : Alignment.centerRight;
  }

  // Get appropriate text alignment
  TextAlign getStartTextAlign() {
    return _isRTL ? TextAlign.right : TextAlign.left;
  }

  TextAlign getEndTextAlign() {
    return _isRTL ? TextAlign.left : TextAlign.right;
  }

  // Get appropriate cross-axis alignment for Flex widgets
  CrossAxisAlignment getStartCrossAxisAlignment() {
    return _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  CrossAxisAlignment getEndCrossAxisAlignment() {
    return _isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
  }

  // Get appropriate main-axis alignment for Flex widgets
  MainAxisAlignment getStartMainAxisAlignment() {
    return _isRTL ? MainAxisAlignment.end : MainAxisAlignment.start;
  }

  MainAxisAlignment getEndMainAxisAlignment() {
    return _isRTL ? MainAxisAlignment.start : MainAxisAlignment.end;
  }

  // Font family selection for Arabic support
  String? getFontFamily() {
    return _isRTL ? 'Noto Sans Arabic' : null; // Use system default for English
  }

  // Number formatting for RTL languages
  String formatNumber(num number) {
    if (_isRTL) {
      // For Arabic, you might want to use Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
      // For now, we'll keep Western digits as they're commonly used in UAE
      return number.toString();
    }
    return number.toString();
  }

  // Currency formatting considering RTL
  String formatCurrency(num amount, String currencyCode) {
    final formattedAmount = amount.toStringAsFixed(2);

    if (_isRTL) {
      // In Arabic, currency typically comes after the amount
      return '$formattedAmount $currencyCode';
    } else {
      // In English, currency comes before the amount
      return '$currencyCode $formattedAmount';
    }
  }

  // Date formatting considering RTL and locale
  String formatDate(DateTime date) {
    // This is a simplified version - you might want to use intl package for proper formatting
    if (_isRTL) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
