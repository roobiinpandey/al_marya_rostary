import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Extension to easily access Almaryah theme colors through Material theme
extension AlmaryahColors on ColorScheme {
  // Primary brand colors
  Color get primaryOliveGold => primary;
  Color get secondaryLightGold => secondary;

  // Background colors
  Color get backgroundWarmBeige => surface;

  // Text colors
  Color get textPrimaryDarkCharcoal => onSurface;
  Color get textSecondaryMutedGray => onSurface.withValues(alpha: 0.7);

  // Accent colors
  Color get accentAmber => secondary;

  // Legacy compatibility (for gradual migration)
  Color get primaryBrown => primary; // Maps to olive gold
  Color get textDark => onSurface;
  Color get textMedium => onSurface.withValues(alpha: 0.8);
  Color get textLight => onSurface.withValues(alpha: 0.6);
  Color get surfaceWhite => surface;
  Color get primaryLightBrown => secondary;
}

/// Helper to access theme colors easily
extension ThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  // Language and localization helpers
  bool get isArabic =>
      Provider.of<LanguageProvider>(this, listen: false).isArabic;
  bool get isEnglish =>
      Provider.of<LanguageProvider>(this, listen: false).isEnglish;
  bool get isRTL => Provider.of<LanguageProvider>(this, listen: false).isRTL;
  TextDirection get textDirection =>
      Provider.of<LanguageProvider>(this, listen: false).textDirection;
}
