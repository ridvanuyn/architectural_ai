import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/revenue_cat_service.dart';
import '../theme/app_theme.dart';

/// Two sections exposed by [PurchaseScreen].
enum PurchaseTab { premium, tokens }

/// Purchase screen with two sections:
///   - Go Premium  → RevenueCat subscription packages
///   - Buy Tokens  → RevenueCat non-subscription (consumable) token packs
///
/// Products are pulled via `Purchases.getOfferings()` and split by
/// productCategory (SUBSCRIPTION vs NON_SUBSCRIPTION).
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key, this.initialTab = PurchaseTab.premium});

  final PurchaseTab initialTab;

  static const routeName = '/purchase';

  /// Show the purchase flow as a modal sheet anchored to the bottom.
  static Future<void> showSheet(
    BuildContext context, {
    PurchaseTab initialTab = PurchaseTab.premium,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: PurchaseScreen(initialTab: initialTab),
        ),
      ),
    );
  }

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Package> _subscriptions = const [];
  List<Package> _tokenPacks = const [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _loadOfferings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final split = await RevenueCatService().getSplitPackages();
      if (!mounted) return;
      setState(() {
        _subscriptions = split.subscriptions;
        _tokenPacks = split.tokenPacks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _buy(Package package) async {
    if (_purchasing) return;
    HapticService.mediumImpact();
    setState(() => _purchasing = true);

    final appProvider = context.read<AppProvider>();
    final ok = await RevenueCatService()
        .purchase(package, appProvider: appProvider);

    if (!mounted) return;
    setState(() => _purchasing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? context.tr('purchase_success') : context.tr('purchase_failed'),
        ),
      ),
    );

    if (ok) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _restore() async {
    HapticService.lightImpact();
    final appProvider = context.read<AppProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('restoring_purchases'))),
    );
    final ok = await RevenueCatService()
        .restorePurchases(appProvider: appProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.tr('purchases_restored')
              : context.tr('no_purchases_found'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _SheetHandle(),
            _Header(onRestore: _restore),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: context.tr('go_premium')),
                  Tab(text: context.tr('buy_tokens')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SubscriptionsSection(
                    loading: _loading,
                    error: _error,
                    packages: _subscriptions,
                    purchasing: _purchasing,
                    onBuy: _buy,
                    onRetry: _loadOfferings,
                  ),
                  _TokensSection(
                    loading: _loading,
                    error: _error,
                    packages: _tokenPacks,
                    purchasing: _purchasing,
                    onBuy: _buy,
                    onRetry: _loadOfferings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRestore});
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('upgrade_tokens_title'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('upgrade_tokens_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRestore,
            child: Text(context.tr('restore')),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({
    required this.loading,
    required this.error,
    required this.packages,
    required this.purchasing,
    required this.onBuy,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<Package> packages;
  final bool purchasing;
  final Future<void> Function(Package) onBuy;
  final VoidCallback onRetry;

  /// Heuristic "most popular" selector: prefer an annual/yearly subscription,
  /// otherwise the highest-priced one, otherwise none.
  String? _popularProductId(List<Package> pkgs) {
    if (pkgs.isEmpty) return null;
    final annual = pkgs.where((p) {
      final id = p.storeProduct.identifier.toLowerCase();
      return id.contains('year') || id.contains('annual');
    }).toList();
    if (annual.isNotEmpty) return annual.first.storeProduct.identifier;
    pkgs.sort(
      (a, b) => b.storeProduct.price.compareTo(a.storeProduct.price),
    );
    return pkgs.first.storeProduct.identifier;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRetry);
    }
    if (packages.isEmpty) {
      return _EmptyState(
        title: context.tr('no_subscriptions'),
        subtitle: context.tr('check_store_config'),
      );
    }
    final popularId = _popularProductId([...packages]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const _BenefitsBanner(),
        const SizedBox(height: 16),
        ...packages.map(
          (pkg) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PackageTile(
              package: pkg,
              isPopular:
                  pkg.storeProduct.identifier == popularId && packages.length > 1,
              subtitle: _subscriptionSubtitle(context, pkg),
              bonusLabel: context.tr('bonus_100_tokens_month'),
              ctaLabel: context.tr('subscribe'),
              enabled: !purchasing,
              onTap: () => onBuy(pkg),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('subscriptions_renew_notice'),
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _subscriptionSubtitle(BuildContext context, Package pkg) {
    final id = pkg.storeProduct.identifier.toLowerCase();
    if (id.contains('year') || id.contains('annual')) {
      return context.tr('billed_yearly');
    }
    if (id.contains('month')) return context.tr('billed_monthly');
    if (id.contains('week')) return context.tr('billed_weekly');
    return pkg.storeProduct.description;
  }
}

class _TokensSection extends StatelessWidget {
  const _TokensSection({
    required this.loading,
    required this.error,
    required this.packages,
    required this.purchasing,
    required this.onBuy,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final List<Package> packages;
  final bool purchasing;
  final Future<void> Function(Package) onBuy;
  final VoidCallback onRetry;

  static const _productIdToTokens = <String, int>{
    'tokens_10_pack': 10,
    'tokens_25_pack': 25,
    'tokens_50_pack': 50,
    'tokens_100_pack': 100,
    'tokens_200_pack': 200,
    'tokens_500_pack': 500,
    'tokens_1000_pack': 1000,
  };

  /// "Most Popular" is the 200-pack when available, else the median pack.
  String? _popularProductId(List<Package> pkgs) {
    if (pkgs.isEmpty) return null;
    final hit = pkgs.firstWhere(
      (p) => p.storeProduct.identifier == 'tokens_200_pack',
      orElse: () => pkgs[pkgs.length ~/ 2],
    );
    return hit.storeProduct.identifier;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRetry);
    }
    if (packages.isEmpty) {
      return _EmptyState(
        title: context.tr('no_token_packs'),
        subtitle: context.tr('check_store_config'),
      );
    }
    final popularId = _popularProductId(packages);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        ...packages.map(
          (pkg) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PackageTile(
              package: pkg,
              isPopular: pkg.storeProduct.identifier == popularId &&
                  packages.length > 1,
              subtitle: _tokensSubtitle(context, pkg),
              bonusLabel: null,
              ctaLabel: context.tr('buy'),
              enabled: !purchasing,
              onTap: () => onBuy(pkg),
            ),
          ),
        ),
      ],
    );
  }

  String _tokensSubtitle(BuildContext context, Package pkg) {
    final tokens = _productIdToTokens[pkg.storeProduct.identifier];
    if (tokens != null) {
      return context.tr('tokens_count').replaceFirst('%s', '$tokens');
    }
    return pkg.storeProduct.description;
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.isPopular,
    required this.subtitle,
    required this.bonusLabel,
    required this.ctaLabel,
    required this.enabled,
    required this.onTap,
  });

  final Package package;
  final bool isPopular;
  final String subtitle;
  final String? bonusLabel;
  final String ctaLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPopular
                      ? AppColors.primary
                      : AppColors.cardBorder,
                  width: isPopular ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title.isNotEmpty
                              ? product.title
                              : product.identifier,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (bonusLabel != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bonusLabel!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.priceString,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: -10,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('most_popular'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenefitsBanner extends StatelessWidget {
  const _BenefitsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('premium_benefits'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BenefitRow(icon: Icons.token_outlined, text: context.tr('benefit_monthly_tokens')),
          const SizedBox(height: 6),
          _BenefitRow(icon: Icons.auto_awesome, text: context.tr('benefit_all_styles')),
          const SizedBox(height: 6),
          _BenefitRow(icon: Icons.bolt_outlined, text: context.tr('benefit_best_quality')),
          const SizedBox(height: 6),
          _BenefitRow(icon: Icons.block_outlined, text: context.tr('benefit_no_ads')),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              context.tr('failed_load_packages'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kDebugMode ? message : context.tr('try_again_moment'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
