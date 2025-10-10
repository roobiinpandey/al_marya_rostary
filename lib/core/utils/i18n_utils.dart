import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

/// Extension to easily access localization and language provider in any widget
extension LocalizationExtension on BuildContext {
  /// Get the current app localizations
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Get the current language provider
  LanguageProvider get language => read<LanguageProvider>();
  
  /// Get the current language provider with listener
  LanguageProvider get watchLanguage => watch<LanguageProvider>();
  
  /// Check if current language is Arabic
  bool get isArabic => read<LanguageProvider>().isArabic;
  
  /// Check if current language is English  
  bool get isEnglish => read<LanguageProvider>().isEnglish;
  
  /// Check if current text direction is RTL
  bool get isRTL => read<LanguageProvider>().isRTL;
  
  /// Get current text direction
  TextDirection get textDirection => read<LanguageProvider>().textDirection;
}

/// Extension for RTL-aware positioning and alignment
extension RTLExtension on BuildContext {
  /// Get start alignment (left for LTR, right for RTL)
  Alignment get startAlignment => 
      read<LanguageProvider>().getStartAlignment();
  
  /// Get end alignment (right for LTR, left for RTL)
  Alignment get endAlignment => 
      read<LanguageProvider>().getEndAlignment();
  
  /// Get start text alignment (left for LTR, right for RTL)
  TextAlign get startTextAlign => 
      read<LanguageProvider>().getStartTextAlign();
  
  /// Get end text alignment (right for LTR, left for RTL)
  TextAlign get endTextAlign => 
      read<LanguageProvider>().getEndTextAlign();
  
  /// Get start cross axis alignment for Flex widgets
  CrossAxisAlignment get startCrossAxisAlignment => 
      read<LanguageProvider>().getStartCrossAxisAlignment();
  
  /// Get end cross axis alignment for Flex widgets
  CrossAxisAlignment get endCrossAxisAlignment => 
      read<LanguageProvider>().getEndCrossAxisAlignment();
  
  /// Get start main axis alignment for Flex widgets
  MainAxisAlignment get startMainAxisAlignment => 
      read<LanguageProvider>().getStartMainAxisAlignment();
  
  /// Get end main axis alignment for Flex widgets
  MainAxisAlignment get endMainAxisAlignment => 
      read<LanguageProvider>().getEndMainAxisAlignment();
  
  /// Get asymmetric padding for RTL/LTR
  EdgeInsets asymmetricPadding({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) => read<LanguageProvider>().getAsymmetricPadding(
        start: start,
        end: end,
        top: top,
        bottom: bottom,
      );
  
  /// Format currency considering RTL/LTR
  String formatCurrency(num amount, String currencyCode) =>
      read<LanguageProvider>().formatCurrency(amount, currencyCode);
  
  /// Format date considering locale
  String formatDate(DateTime date) =>
      read<LanguageProvider>().formatDate(date);
  
  /// Format number considering locale
  String formatNumber(num number) =>
      read<LanguageProvider>().formatNumber(number);
}

/// Utility functions for internationalization
class I18nUtils {
  /// Get localized text by key with fallback
  static String getText(BuildContext context, String key, [String? fallback]) {
    try {
      final l10n = AppLocalizations.of(context);
      // Use reflection or a map to get the localized text
      // For now, return the key itself as fallback
      return fallback ?? key;
    } catch (e) {
      return fallback ?? key;
    }
  }
  
  /// Check if a string contains Arabic characters
  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
  
  /// Get appropriate text direction for a given text
  static TextDirection getTextDirection(String text) {
    return containsArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Format a phone number for the current locale
  static String formatPhoneNumber(String phoneNumber, {bool isUAE = true}) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (isUAE) {
      // UAE phone number formatting
      if (digits.length == 9) {
        // Local number, add UAE country code
        return '+971 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
      } else if (digits.length == 12 && digits.startsWith('971')) {
        // Already has country code
        final local = digits.substring(3);
        return '+971 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
      }
    }
    
    return phoneNumber; // Return original if can't format
  }
  
  /// Get localized day name (simplified version)
  static String getDayName(BuildContext context, int weekday) {
    final isArabic = context.isArabic;
    switch (weekday) {
      case 1: return isArabic ? 'الإثنين' : 'Monday';
      case 2: return isArabic ? 'الثلاثاء' : 'Tuesday';
      case 3: return isArabic ? 'الأربعاء' : 'Wednesday';
      case 4: return isArabic ? 'الخميس' : 'Thursday';
      case 5: return isArabic ? 'الجمعة' : 'Friday';
      case 6: return isArabic ? 'السبت' : 'Saturday';
      case 7: return isArabic ? 'الأحد' : 'Sunday';
      default: return '';
    }
  }
  
  /// Get localized month name (simplified version)
  static String getMonthName(BuildContext context, int month) {
    final isArabic = context.isArabic;
    switch (month) {
      case 1: return isArabic ? 'يناير' : 'January';
      case 2: return isArabic ? 'فبراير' : 'February';
      case 3: return isArabic ? 'مارس' : 'March';
      case 4: return isArabic ? 'أبريل' : 'April';
      case 5: return isArabic ? 'مايو' : 'May';
      case 6: return isArabic ? 'يونيو' : 'June';
      case 7: return isArabic ? 'يوليو' : 'July';
      case 8: return isArabic ? 'أغسطس' : 'August';
      case 9: return isArabic ? 'سبتمبر' : 'September';
      case 10: return isArabic ? 'أكتوبر' : 'October';
      case 11: return isArabic ? 'نوفمبر' : 'November';
      case 12: return isArabic ? 'ديسمبر' : 'December';
      default: return '';
    }
  }
}
