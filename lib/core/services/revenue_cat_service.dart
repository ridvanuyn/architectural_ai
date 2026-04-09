import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  static const _iosApiKey = 'appl_REPLACE_WITH_IOS_KEY';
  static const _androidApiKey = 'goog_REPLACE_WITH_ANDROID_KEY';

  bool _initialized = false;

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

    final deviceId = await getDeviceId();

    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = deviceId;

    await Purchases.configure(configuration);
    _initialized = true;
    debugPrint('RevenueCat initialized with device: $deviceId');
  }

  /// Get available packages (token packs + subscriptions)
  Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return [];
    }
  }

  /// Purchase a package
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      // Check if purchase was successful
      return result.customerInfo.entitlements.active.isNotEmpty ||
             result.customerInfo.nonSubscriptionTransactions.isNotEmpty;
    } catch (e) {
      debugPrint('Purchase failed: $e');
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

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
