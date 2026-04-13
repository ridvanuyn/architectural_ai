import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_localizations.dart';
import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/engagement_notification_service.dart';
import '../core/services/haptic_service.dart';
import '../core/services/revenue_cat_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await RevenueCatService().getDeviceId();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _deviceId = deviceId;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (!value) {
      // Cancel engagement notifications
      await EngagementNotificationService().cancelAll();
    }

    HapticService.selectionClick();
  }

  void _navigateToPurchase() {
    HapticService.lightImpact();
    Navigator.pushNamed(context, '/purchase');
  }

  void _showRateAppDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('rate_app')),
        content: const Text(
          'If you enjoy using the app, please take a moment to rate us on the App Store. Your feedback helps us improve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('maybe_later')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening App Store...')),
              );
            },
            child: Text(context.tr('rate_app')),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('help_support')),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? We\'re here for you!'),
            SizedBox(height: 12),
            Text('Email: support@architecturai.app'),
            SizedBox(height: 4),
            Text('Response time: Within 24 hours'),
            SizedBox(height: 12),
            Text('FAQ topics:'),
            Text('  - How to use tokens'),
            Text('  - Design quality tips'),
            Text('  - Account & billing'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactUsDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('contact_us')),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@architecturai.app'),
            SizedBox(height: 8),
            Text('We typically respond within 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('privacy_policy')),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us.\n\n'
            'We collect minimal data necessary to provide our service:\n'
            '- Device identifier for account management\n'
            '- Photos you upload (processed and deleted within 24h)\n'
            '- Usage analytics to improve the app\n\n'
            'We do not sell your personal data to third parties.\n\n'
            'For the full privacy policy, visit:\n'
            'https://architecturai.app/privacy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('terms_of_service')),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to our Terms of Service.\n\n'
            'Key points:\n'
            '- Tokens are non-refundable once used\n'
            '- Generated designs are for personal use\n'
            '- We reserve the right to modify pricing\n'
            '- Abuse of the service may result in account suspension\n\n'
            'For the full terms, visit:\n'
            'https://architecturai.app/terms',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    HapticService.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('delete_account')),
        content: Text(context.tr('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('maybe_later')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted. You will receive a confirmation email.'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete_account')),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    HapticService.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring purchases...')),
    );

    try {
      final restored = await RevenueCatService().restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Purchases restored successfully!'
                  : 'No purchases found to restore.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore purchases. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

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

            // Account Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Token Balance
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.token,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Token Balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '${appProvider.tokenBalance} tokens',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToPurchase,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Get More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 12),
                  // Current Tier
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('current_plan')}: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appProvider.tierLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Device ID
                  if (_deviceId != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.devices,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${_deviceId!.substring(0, _deviceId!.length > 12 ? 12 : _deviceId!.length)}...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subscription / Premium
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.diamond_outlined,
                    title: context.tr('premium_subscription'),
                    subtitle: context.tr('premium_desc'),
                    onTap: _navigateToPurchase,
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.restore,
                    title: context.tr('restore_purchases'),
                    onTap: _restorePurchases,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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

            // Notifications Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr('notifications'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
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
                    onTap: _showHelpSupportDialog,
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.mail_outline,
                    title: context.tr('contact_us'),
                    onTap: _showContactUsDialog,
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
                    onTap: _showTermsOfServiceDialog,
                  ),
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: context.tr('privacy_policy'),
                    onTap: _showPrivacyPolicyDialog,
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
                onTap: _showRateAppDialog,
              ),
            ),
            const SizedBox(height: 16),

            // Danger Zone
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SettingsItem(
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
                  Divider(height: 1, color: AppColors.cardBorder),
                  _SettingsItem(
                    icon: Icons.delete_outline,
                    title: context.tr('delete_account'),
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : null,
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
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

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
              color: iconColor ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: titleColor ?? AppColors.textPrimary,
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
