import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LanguageService _languageService = Get.find<LanguageService>();

  void _changeLanguage(String languageCode) {
    _languageService.changeLanguage(languageCode);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _languageService.getLocalizedText('Language'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(_languageService.getLocalizedText('English')),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: _languageService.currentLanguage.value,
                  onChanged: (value) {
                    _changeLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(_languageService.getLocalizedText('Persian')),
                leading: Radio<String>(
                  value: 'fa',
                  groupValue: _languageService.currentLanguage.value,
                  onChanged: (value) {
                    _changeLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _changeLanguage('fa');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdditionalSettings() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('Additional Settings')),
        content: Text(_languageService
            .getLocalizedText('Additional Settings Description')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showControlFile() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('Control File')),
        content:
            Text(_languageService.getLocalizedText('Control File Description')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFAQs() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('FAQs')),
        content: Text(_languageService.getLocalizedText('FAQs Description')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactUs() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('Contact us')),
        content:
            Text(_languageService.getLocalizedText('Contact Us Description')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('About')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _languageService.getLocalizedText('Fairy Bluetooth'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Version: v3.5'),
            const SizedBox(height: 8),
            Text(_languageService.getLocalizedText('About Description')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Get.snackbar(
      _languageService.getLocalizedText('Share'),
      _languageService.getLocalizedText('Share Message'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.onSurface,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  void _rateApp() {
    Get.snackbar(
      _languageService.getLocalizedText('Rate'),
      'Rate functionality will be implemented here',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.onSurface,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  void _supportUs() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_languageService.getLocalizedText('SUPPORT US')),
        content:
            Text(_languageService.getLocalizedText('Support Us Description')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_languageService.getLocalizedText('Settings')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Settings Items
                _buildSettingsItem(
                  icon: Icons.settings_rounded,
                  title:
                      _languageService.getLocalizedText('Additional Settings'),
                  onTap: _showAdditionalSettings,
                  theme: theme,
                ),
                _buildSettingsItem(
                  icon: Icons.description_rounded,
                  title: _languageService.getLocalizedText('Control File'),
                  onTap: _showControlFile,
                  theme: theme,
                ),
                _buildSettingsItem(
                  icon: Icons.question_answer_rounded,
                  title: _languageService.getLocalizedText('FAQs'),
                  onTap: _showFAQs,
                  theme: theme,
                ),
                _buildSettingsItem(
                  icon: Icons.contact_support_rounded,
                  title: _languageService.getLocalizedText('Contact us'),
                  onTap: _showContactUs,
                  theme: theme,
                ),
                _buildSettingsItem(
                  icon: Icons.info_rounded,
                  title: _languageService.getLocalizedText('About'),
                  onTap: _showAbout,
                  theme: theme,
                ),
                _buildSettingsItem(
                  icon: Icons.language_rounded,
                  title: _languageService.getLocalizedText('Language'),
                  subtitle: _languageService.currentLanguage.value == 'fa'
                      ? _languageService.getLocalizedText('Persian')
                      : _languageService.getLocalizedText('English'),
                  onTap: _showLanguageDialog,
                  theme: theme,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                // Row(
                //   children: [
                //     Expanded(
                //       child: _buildActionButton(
                //         icon: Icons.share_rounded,
                //         title: _languageService.getLocalizedText('Share'),
                //         onTap: _shareApp,
                //         theme: theme,
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     Expanded(
                //       child: _buildActionButton(
                //         icon: Icons.star_rounded,
                //         title: _languageService.getLocalizedText('Rate'),
                //         onTap: _rateApp,
                //         theme: theme,
                //       ),
                //     ),
                //   ],
                // ),

                //   const SizedBox(height: 32),

                // App Version
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                //   decoration: BoxDecoration(
                //     color: theme.colorScheme.surface,
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(
                //       color: theme.colorScheme.outline.withOpacity(0.2),
                //     ),
                //   ),
                //   child: Text(
                //     'v3.5',
                //     style: theme.textTheme.bodyMedium?.copyWith(
                //       color: theme.colorScheme.outline,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: theme.colorScheme.primary),
      label: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
