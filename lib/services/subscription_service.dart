import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'dart:io' show Platform;

/// Service for managing RevenueCat subscriptions
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;

  // RevenueCat API keys
  static const String _androidApiKey = 'test_BvGLLzGJKLxWELbbsqPPMGWgRDn';
  static const String _iosApiKey = 'test_BvGLLzGJKLxWELbbsqPPMGWgRDn';

  // Product identifiers - must match what you create in App Store Connect / Google Play Console
  static const String monthlyProductId = 'breedly_monthly_69';
  static const String yearlyProductId = 'breedly_yearly_690';

  // Entitlement identifier - must match RevenueCat dashboard
  static const String entitlementId = 'Breedly Pro';

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      late PurchasesConfiguration configuration;

      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_androidApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_iosApiKey);
      } else {
        debugPrint('RevenueCat: Platform not supported for purchases');
        return;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  /// Set the user ID for RevenueCat (call after Firebase Auth login)
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;
    try {
      await Purchases.logIn(userId);
      debugPrint('RevenueCat: User logged in: $userId');
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  /// Log out from RevenueCat (call on Firebase Auth logout)
  Future<void> logout() async {
    if (!_isInitialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isPremium() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('RevenueCat check premium error: $e');
      return false;
    }
  }

  /// Get customer info with subscription details
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat get customer info error: $e');
      return null;
    }
  }

  /// Get available packages (monthly + yearly)
  Future<List<Package>> getPackages() async {
    if (!_isInitialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('RevenueCat get packages error: $e');
      return [];
    }
  }

  /// Get the monthly package
  Future<Package?> getMonthlyPackage() async {
    if (!_isInitialized) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.monthly;
    } catch (e) {
      debugPrint('RevenueCat get monthly error: $e');
      return null;
    }
  }

  /// Get the annual package
  Future<Package?> getAnnualPackage() async {
    if (!_isInitialized) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.annual;
    } catch (e) {
      debugPrint('RevenueCat get annual error: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('RevenueCat purchase error: $e');
      return false;
    }
  }

  /// Restore purchases (e.g. after reinstall)
  Future<bool> restorePurchases() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('RevenueCat restore error: $e');
      return false;
    }
  }

  /// Get subscription expiration date
  Future<DateTime?> getExpirationDate() async {
    if (!_isInitialized) return null;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active[entitlementId];
      if (entitlement == null) return null;
      final expirationDate = entitlement.expirationDate;
      if (expirationDate == null) return null;
      return DateTime.tryParse(expirationDate);
    } catch (e) {
      debugPrint('RevenueCat get expiration error: $e');
      return null;
    }
  }

  /// Check if subscription will renew
  Future<bool> willRenew() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active[entitlementId];
      return entitlement?.willRenew ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Present RevenueCat's built-in paywall UI
  /// Returns true if the user successfully purchased
  Future<bool> presentPaywall() async {
    if (!_isInitialized) return false;
    try {
      final result = await RevenueCatUI.presentPaywall();
      debugPrint('RevenueCat paywall result: $result');
      // Check if user now has active entitlement
      return await isPremium();
    } catch (e) {
      debugPrint('RevenueCat presentPaywall error: $e');
      return false;
    }
  }
}
