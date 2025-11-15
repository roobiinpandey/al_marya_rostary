import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLanguage = 'en'; // 'en' or 'ar'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = prefs.getString('app_language') ?? 'en';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading language preference: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLanguagePreference(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language);
      setState(() {
        _selectedLanguage = language;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              language == 'en'
                  ? 'Language updated to English'
                  : 'تم تحديث اللغة إلى العربية',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show restart message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryBrown),
                  const SizedBox(width: 8),
                  Text(
                    language == 'en'
                        ? 'Restart Required'
                        : 'إعادة تشغيل مطلوبة',
                  ),
                ],
              ),
              content: Text(
                language == 'en'
                    ? 'Please restart the app to apply the language changes.'
                    : 'يرجى إعادة تشغيل التطبيق لتطبيق تغييرات اللغة.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(language == 'en' ? 'OK' : 'حسناً'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Language Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choose your preferred language',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D5D5D),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLanguageOption(
                  title: 'English',
                  subtitle: 'Use the app in English',
                  flag: '🇬🇧',
                  value: 'en',
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  title: 'العربية',
                  subtitle: 'استخدم التطبيق باللغة العربية',
                  flag: '🇦🇪',
                  value: 'ar',
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBrown,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedLanguage == 'en'
                              ? 'The app will need to restart to fully apply the language changes. All text, menus, and content will be displayed in your selected language.'
                              : 'سيحتاج التطبيق إلى إعادة التشغيل لتطبيق تغييرات اللغة بالكامل. سيتم عرض جميع النصوص والقوائم والمحتوى باللغة المحددة.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBrown.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String flag,
    required String value,
  }) {
    final isSelected = _selectedLanguage == value;

    return InkWell(
      onTap: () => _saveLanguagePreference(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBrown.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBrown
                    : AppTheme.primaryBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(flag, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryBrown
                          : const Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryBrown,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
