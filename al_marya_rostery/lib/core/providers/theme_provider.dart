import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey) ?? 'system';

      await setThemeMode(themeModeString, notify: false);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback to system theme if there's an error
      _themeMode = ThemeMode.system;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String mode, {bool notify = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update theme mode
      switch (mode.toLowerCase()) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }

      // Save to preferences
      await prefs.setString(_themeModeKey, mode.toLowerCase());

      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
