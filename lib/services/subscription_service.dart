import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Service for managing RevenueCat subscriptions
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;
  final StreamController<bool> _isSubscribedController =
      StreamController<bool>.broadcast();
  bool _isSubscribed = false;

  // ── Toggle this to true when you're ready to enable RevenueCat payments ──
  static const bool enabled = true;

  // RevenueCat API keys
  static const String _androidApiKey = 'test_BvGLLzGJKLxWELbbsqPPMGWgRDn';
  static const String _iosApiKey = 'test_BvGLLzGJKLxWELbbsqPPMGWgRDn';

  // Product identifiers - must match what you create in App Store Connect / Google Play Console
  static const String monthlyProductId = 'peddex_monthly_69';
  static const String yearlyProductId = 'peddex_yearly_690';

  // Entitlement identifier - must match RevenueCat dashboard
  static const String entitlementId = 'Peddex Pro';

  Stream<bool> get isSubscribed => _isSubscribedController.stream;
  bool get currentIsSubscribed => _isSubscribed;

  void _emitSubscriptionState(bool value) {
    _isSubscribed = value;
    _isSubscribedController.add(value);
  }

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (!enabled) {
      debugPrint('RevenueCat: payments paused (SubscriptionService.enabled = false)');
      return;
    }
    if (_isInitialized) return;

    try {
      // RevenueCat only supports Android and iOS
      if (kIsWeb) {
        debugPrint('RevenueCat: Web platform not supported');
        return;
      }

      late PurchasesConfiguration configuration;

      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_androidApiKey);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_iosApiKey);
      } else {
        debugPrint('RevenueCat: Platform not supported for purchases');
        return;
      }

      await Purchases.configure(configuration);
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _emitSubscriptionState(
          customerInfo.entitlements.active.containsKey(entitlementId),
        );
      });
      final info = await Purchases.getCustomerInfo();
      _emitSubscriptionState(info.entitlements.active.containsKey(entitlementId));
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
      final info = await Purchases.getCustomerInfo();
      _emitSubscriptionState(info.entitlements.active.containsKey(entitlementId));
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
      _emitSubscriptionState(false);
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isPremium() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.active.containsKey(entitlementId);
      _emitSubscriptionState(premium);
      return premium;
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
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final premium =
          result.customerInfo.entitlements.active.containsKey(entitlementId);
      _emitSubscriptionState(premium);
      return premium;
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
      final premium = customerInfo.entitlements.active.containsKey(entitlementId);
      _emitSubscriptionState(premium);
      return premium;
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
