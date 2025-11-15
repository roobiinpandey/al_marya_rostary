import 'package:flutter/material.dart';

class AppTheme {
  // Driver App Theme - Olive Gold (matching customer app)
  static const Color primaryOliveGold = Color(0xFFA89A6A);
  static const Color darkOliveGold = Color(0xFF8B7D5A);
  static const Color lightOliveGold = Color(0xFFC4B896);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color backgroundCream = Color(0xFFEDE9E1);

  // Status Colors
  static const Color statusPending = Color(0xFFFF9800); // Orange
  static const Color statusInProgress = Color(0xFF2196F3); // Blue
  static const Color statusCompleted = Color(0xFF4CAF50); // Green
  static const Color statusCancelled = Color(0xFFF44336); // Red

  // Text Colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  static ThemeData get driverTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryOliveGold,
      colorScheme: ColorScheme.light(
        primary: primaryOliveGold,
        secondary: accentGold,
        surface: surface,
        error: statusCancelled,
      ),
      scaffoldBackgroundColor: backgroundCream,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOliveGold,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOliveGold,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOliveGold,
          side: const BorderSide(color: primaryOliveGold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOliveGold, width: 2),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200]!,
        selectedColor: primaryOliveGold,
        labelStyle: const TextStyle(color: textDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
