import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Text(
              context.tr('profile'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Language Selection
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _LanguageSelector(),
            ),
            const SizedBox(height: 16),
            
            // Help & Support
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: context.tr('help_support'),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.mail_outline,
                    title: context.tr('contact_us'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Legal
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    title: context.tr('terms_of_service'),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: context.tr('privacy_policy'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Rate App
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _SettingsItem(
                icon: Icons.star_outline,
                title: context.tr('rate_app'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 16),
            
            // Reset Onboarding (Dev)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _SettingsItem(
                icon: Icons.refresh,
                title: 'Reset Onboarding',
                subtitle: 'Start fresh (for testing)',
                onTap: () async {
                  HapticService.mediumImpact();
                  await context.read<AppProvider>().resetOnboarding();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/', 
                      (route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
            
            // Version
            Center(
              child: Text(
                '${context.tr('version')} 1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentLanguage = appProvider.currentLanguage;
    
    return InkWell(
      onTap: () => _showLanguageSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              size: 22,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('language'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currentLanguage.flag} ${currentLanguage.nativeName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    HapticService.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LanguageBottomSheet(),
    );
  }
}

class _LanguageBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentCode = appProvider.locale.languageCode;
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              context.tr('select_language'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: SupportedLanguage.all.length,
              itemBuilder: (context, index) {
                final language = SupportedLanguage.all[index];
                final isSelected = language.code == currentCode;
                
                return InkWell(
                  onTap: () {
                    HapticService.selectionClick();
                    appProvider.changeLanguage(language.code);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                    child: Row(
                      children: [
                        Text(
                          language.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                language.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
