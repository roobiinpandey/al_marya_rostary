import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageToggleWidget extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const LanguageToggleWidget({
    super.key,
    this.showLabel = true,
    this.iconSize = 24,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          padding: padding ?? const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => languageProvider.toggleLanguage(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: iconSize,
                    color: iconColor ?? Theme.of(context).primaryColor,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Text(
                      languageProvider.isArabic ? 'English' : 'العربية',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: iconColor ?? Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LanguageToggleButton extends StatelessWidget {
  final bool outlined;
  final double? width;
  final double? height;

  const LanguageToggleButton({
    super.key,
    this.outlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return SizedBox(
          width: width,
          height: height ?? 48,
          child: outlined
              ? OutlinedButton.icon(
                  onPressed: languageProvider.toggleLanguage,
                  icon: const Icon(Icons.language),
                  label: Text(
                    languageProvider.isArabic ? 'English' : 'العربية',
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: languageProvider.toggleLanguage,
                  icon: const Icon(Icons.language),
                  label: Text(
                    languageProvider.isArabic ? 'English' : 'العربية',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class LanguageDropdown extends StatelessWidget {
  final bool showFlags;
  final double? width;

  const LanguageDropdown({super.key, this.showFlags = true, this.width});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: languageProvider.locale.languageCode,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLanguage(newValue);
                }
              },
              items: [
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Row(
                    children: [
                      if (showFlags) ...[
                        Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.blue.shade100,
                          ),
                          child: Center(
                            child: Text('🇺🇸', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text('English'),
                    ],
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'ar',
                  child: Row(
                    children: [
                      if (showFlags) ...[
                        Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.green.shade100,
                          ),
                          child: Center(
                            child: Text('🇦🇪', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text('العربية'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Floating Action Button for quick language switching
class LanguageFAB extends StatelessWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LanguageFAB({super.key, this.backgroundColor, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FloatingActionButton.small(
          onPressed: languageProvider.toggleLanguage,
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
          child: const Icon(Icons.language),
        );
      },
    );
  }
}

// Language selection dialog
class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final l10n = AppLocalizations.of(context);

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 8),
              Text(l10n?.selectLanguage ?? 'Select Language'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.blue.shade50,
                  ),
                  child: const Center(
                    child: Text('🇺🇸', style: TextStyle(fontSize: 16)),
                  ),
                ),
                title: const Text('English'),
                subtitle: const Text('English (United States)'),
                trailing: languageProvider.isEnglish
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  languageProvider.setLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.green.shade50,
                  ),
                  child: const Center(
                    child: Text('🇦🇪', style: TextStyle(fontSize: 16)),
                  ),
                ),
                title: const Text('العربية'),
                subtitle: const Text('Arabic (United Arab Emirates)'),
                trailing: languageProvider.isArabic
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  languageProvider.setLanguage('ar');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
          ],
        );
      },
    );
  }
}
