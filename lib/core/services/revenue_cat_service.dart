import 'dart:io';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../providers/app_provider.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Pass via --dart-define=REVENUECAT_IOS_KEY=appl_xxx --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
  static const _iosApiKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const _androidApiKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  bool _initialized = false;
  bool get isReady => _initialized;

  /// Get or create a persistent unique device ID
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_unique_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_unique_id', deviceId);
    }
    return deviceId;
  }

  /// Initialize RevenueCat
  Future<void> init() async {
    if (_initialized) return;

    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    if (apiKey.isEmpty) {
      debugPrint('RevenueCat API key not configured (use --dart-define)');
      return;
    }

    final deviceId = await getDeviceId();
    final configuration = PurchasesConfiguration(apiKey)..appUserID = deviceId;

    await Purchases.configure(configuration);
    _initialized = true;
    debugPrint('RevenueCat initialized with device: $deviceId');
  }

  /// Get available packages (token packs + subscriptions)
  Future<List<Package>> getPackages() async {
    if (!_initialized) {
      debugPrint('Purchases.getOfferings skipped — RevenueCat not initialized');
      return [];
    }
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return [];
    }
  }

  /// Split available packages into subscriptions and one-time token packs.
  /// `productCategory` on StoreProduct distinguishes the two (SUBSCRIPTION vs
  /// NON_SUBSCRIPTION). Falls back to identifier heuristic for SDK versions
  /// that don't populate the category.
  Future<({List<Package> subscriptions, List<Package> tokenPacks})>
      getSplitPackages() async {
    final packages = await getPackages();
    final subs = <Package>[];
    final tokens = <Package>[];
    for (final p in packages) {
      final category = p.storeProduct.productCategory;
      if (category == ProductCategory.subscription) {
        subs.add(p);
      } else if (category == ProductCategory.nonSubscription) {
        tokens.add(p);
      } else {
        // Fallback: identifier contains "token" or explicit package type heuristic.
        final id = p.storeProduct.identifier.toLowerCase();
        if (id.contains('token') || id.contains('pack')) {
          tokens.add(p);
        } else {
          subs.add(p);
        }
      }
    }
    return (subscriptions: subs, tokenPacks: tokens);
  }

  /// Purchase a package and grant tokens for consumables, or activate premium
  /// (plus monthly bonus tokens) for subscriptions.
  Future<bool> purchase(Package package, {AppProvider? appProvider}) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final productId = package.storeProduct.identifier;
      final hasEntitlement = result.customerInfo.entitlements.active.isNotEmpty;
      final hasConsumable = result.customerInfo.nonSubscriptionTransactions.isNotEmpty;

      if (appProvider != null && hasConsumable) {
        await appProvider.grantTokensFromPurchase(productId);
      }
      if (appProvider != null && hasEntitlement) {
        await appProvider.activatePremium();
      }
      return hasEntitlement || hasConsumable;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  /// Present the RevenueCat-hosted paywall. Returns true if the user
  /// completed a purchase or restored a subscription.
  Future<bool> presentPaywall(BuildContext context, {AppProvider? appProvider}) async {
    if (!_initialized) {
      debugPrint('RevenueCat not initialized, cannot present paywall');
      return false;
    }
    try {
      final result = await RevenueCatUI.presentPaywall();
      final purchased = result == PaywallResult.purchased ||
          result == PaywallResult.restored;
      if (purchased && appProvider != null) {
        // Sync the latest customer info so consumables map to tokens and
        // premium entitlement flips the subscriber flag (granting bonus tokens).
        final info = await Purchases.getCustomerInfo();
        for (final tx in info.nonSubscriptionTransactions) {
          await appProvider.grantTokensFromPurchase(tx.productIdentifier);
        }
        if (info.entitlements.active.isNotEmpty) {
          await appProvider.activatePremium();
        }
      }
      return purchased;
    } catch (e) {
      debugPrint('Failed to present paywall: $e');
      return false;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro_access');
    } catch (e) {
      return false;
    }
  }

  /// Restore purchases. If `appProvider` is supplied and any active
  /// entitlement is found, premium is activated locally (no bonus grant on
  /// restore — the bonus was granted at original purchase time).
  Future<bool> restorePurchases({AppProvider? appProvider}) async {
    try {
      final info = await Purchases.restorePurchases();
      final hasEntitlement = info.entitlements.active.isNotEmpty;
      if (appProvider != null && hasEntitlement) {
        await appProvider.activatePremium(grantNow: false);
      }
      return hasEntitlement;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
