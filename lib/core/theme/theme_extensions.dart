import 'package:flutter/material.dart';

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
}
