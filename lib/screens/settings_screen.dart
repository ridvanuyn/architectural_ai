import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_localizations.dart';
import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/engagement_notification_service.dart';
import '../core/services/haptic_service.dart';
import '../core/services/revenue_cat_service.dart';
import '../theme/app_theme.dart';
import 'purchase_screen.dart';

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

  Future<void> _navigateToPurchase({
    PurchaseTab tab = PurchaseTab.premium,
  }) async {
    HapticService.lightImpact();
    await PurchaseScreen.showSheet(context, initialTab: tab);
  }

  /// Launch the native in-app review flow. Falls back to opening the store
  /// listing if the in-app prompt is unavailable (simulator, unsigned builds,
  /// review quota exhausted, etc.). Marks the review reward pending so the
  /// +5 token bonus can be claimed 1 hour later.
  Future<void> _handleRateApp() async {
    HapticService.lightImpact();
    final appProvider = context.read<AppProvider>();
    final alreadyClaimed = appProvider.reviewRewardClaimed;
    final alreadyPending = appProvider.reviewRewardPending;

    // Start the reward timer as soon as the user opts in (even if the OS
    // suppresses the native dialog — Apple still honors the intent).
    if (!alreadyClaimed && !alreadyPending) {
      await appProvider.markReviewTapped();
    }

    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('In-app review failed: $e');
      // Best-effort fallback to the store page.
      try {
        await inAppReview.openStoreListing();
      } catch (e2) {
        debugPrint('Store listing fallback failed: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('app_store_open_failed')),
            ),
          );
        }
      }
    }
  }

  /// Claim the +5 token reward when it has ripened. Shows a brief confirmation.
  Future<void> _claimReviewReward() async {
    HapticService.lightImpact();
    final appProvider = context.read<AppProvider>();
    final before = appProvider.tokenBalance;
    await appProvider.claimReviewReward();
    if (!mounted) return;
    final granted = appProvider.tokenBalance - before;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted > 0
              ? '+$granted ${context.tr('review_tokens_thanks')}'
              : context.tr('reward_not_available'),
        ),
      ),
    );
  }

  /// Resolve the subtitle + tap handler for the Rate App row based on reward
  /// state (no pending reward / waiting / ready to claim / already claimed).
  ({String? subtitle, VoidCallback onTap}) _rateAppRowState(
    AppProvider appProvider,
  ) {
    final now = DateTime.now();
    if (appProvider.reviewRewardClaimed) {
      // Already redeemed — leave the row active for re-reviews but no CTA.
      return (subtitle: null, onTap: _handleRateApp);
    }
    if (appProvider.reviewRewardEligibleAt(now)) {
      return (
        subtitle: context.tr('review_reward_ready').replaceFirst('%s', '${AppProvider.kReviewRewardAmount}'),
        onTap: _claimReviewReward,
      );
    }
    if (appProvider.reviewRewardPending) {
      return (
        subtitle: context.tr('review_reward_waiting'),
        onTap: _handleRateApp,
      );
    }
    return (
      subtitle:
          context.tr('review_reward_invite').replaceFirst('%s', '${AppProvider.kReviewRewardAmount}'),
      onTap: _handleRateApp,
    );
  }

  void _showHelpSupportDialog() {
    HapticService.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('help_support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('help_line_intro')),
            const SizedBox(height: 12),
            const Text('Email: support@architecturai.app'),
            const SizedBox(height: 4),
            Text(context.tr('help_response_time')),
            const SizedBox(height: 12),
            Text(context.tr('faq_topics')),
            Text(context.tr('faq_how_tokens')),
            Text(context.tr('faq_quality_tips')),
            Text(context.tr('faq_account_billing')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ok')),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email: support@architecturai.app'),
            const SizedBox(height: 8),
            Text(context.tr('contact_response')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ok')),
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
        content: SingleChildScrollView(
          child: Text(context.tr('privacy_policy_body')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ok')),
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
        content: SingleChildScrollView(
          child: Text(context.tr('terms_of_service_body')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ok')),
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
                SnackBar(
                  content: Text(context.tr('account_deletion_submitted')),
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
      SnackBar(content: Text(context.tr('restoring_purchases'))),
    );

    try {
      final appProvider = context.read<AppProvider>();
      final restored = await RevenueCatService()
          .restorePurchases(appProvider: appProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? context.tr('purchases_restored')
                  : context.tr('no_purchases_found'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('restore_purchases_failed')),
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

            // Premium status banner
            _PremiumStatusCard(
              appProvider: appProvider,
              onTap: () => _navigateToPurchase(tab: PurchaseTab.premium),
            ),
            const SizedBox(height: 16),

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
                            Text(
                              context.tr('token_balance'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  context.tr('tokens_count').replaceFirst('%s', '${appProvider.displayedTokenBalance}'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (appProvider.hasPendingDeduction) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      context.tr('pending_deduction').replaceFirst('%s', '${appProvider.pendingDeduction}'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (appProvider.isPremiumSubscriber &&
                                appProvider.premiumMonthlyGrant > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  context.tr('premium_monthly_tokens').replaceFirst('%s', '${appProvider.premiumMonthlyGrant}'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToPurchase(tab: PurchaseTab.tokens),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr('get_more'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await appProvider.addTokens(10);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('+10 test tokens added'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.science_outlined, size: 18),
                        label: const Text('Add 10 test tokens (debug)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    subtitle: appProvider.isPremiumSubscriber
                        ? context.tr('premium_active_subtitle').replaceFirst('%s', '${appProvider.premiumMonthlyGrant}')
                        : context.tr('premium_desc'),
                    onTap: () => _navigateToPurchase(tab: PurchaseTab.premium),
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

            // Rate App (with +5 token review reward CTA)
            Builder(builder: (_) {
              final rateState = _rateAppRowState(appProvider);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: _SettingsItem(
                  icon: Icons.star_outline,
                  title: context.tr('rate_app'),
                  subtitle: rateState.subtitle,
                  onTap: rateState.onTap,
                ),
              );
            }),
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
                    title: context.tr('reset_onboarding'),
                    subtitle: context.tr('reset_onboarding_desc'),
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

/// Header card summarizing the user's current tier (Free / Premium),
/// monthly grant remaining, and a CTA button.
class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({required this.appProvider, required this.onTap});

  final AppProvider appProvider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = appProvider.isPremiumSubscriber;
    final monthlyGrant = appProvider.premiumMonthlyGrant;
    final grantedAt = appProvider.premiumGrantedAt;

    final gradientColors = isPremium
        ? [AppColors.primary, AppColors.primaryDark]
        : [Colors.white, Colors.white];
    final textColor = isPremium ? Colors.white : AppColors.textPrimary;
    final subColor =
        isPremium ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPremium
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPremium ? Icons.diamond : Icons.diamond_outlined,
                color: isPremium ? Colors.white : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? context.tr('premium_member') : context.tr('free_plan'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium
                        ? _premiumSubtitle(context, monthlyGrant, grantedAt)
                        : context.tr('upgrade_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isPremium
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPremium ? context.tr('manage') : context.tr('upgrade'),
                style: TextStyle(
                  color: isPremium ? Colors.white : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _premiumSubtitle(BuildContext context, int monthlyGrant, DateTime? grantedAt) {
    if (monthlyGrant <= 0) return context.tr('premium_benefits_active');
    if (grantedAt == null) {
      return context.tr('includes_monthly_tokens').replaceFirst('%s', '$monthlyGrant');
    }
    final nextGrant = DateTime(
      grantedAt.year,
      grantedAt.month + 1,
      grantedAt.day,
    );
    final daysLeft = nextGrant.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) {
      return context.tr('next_grant_available').replaceFirst('%s', '$monthlyGrant');
    }
    return context.tr('includes_tokens_next_in')
        .replaceFirst('%s', '$monthlyGrant')
        .replaceFirst('%s', '$daysLeft');
  }
}
