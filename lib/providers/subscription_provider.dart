import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:breedly/services/subscription_service.dart';
import 'package:breedly/services/promo_code_service.dart';

/// Provider that manages subscription state across the app
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PromoCodeService _promoCodeService = PromoCodeService();

  bool _isPremium = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  List<Package> _packages = [];
  DateTime? _expirationDate;
  String? _subscriptionSource; // 'revenuecat', 'promo_code'
  bool _isTrialActive = false;

  // Getters
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  List<Package> get packages => _packages;
  DateTime? get expirationDate => _expirationDate;
  String? get subscriptionSource => _subscriptionSource;
  bool get isTrialActive => _isTrialActive;
  bool get isFreeUser => !_isPremium && !_isTrialActive;

  /// Initialize subscription state
  Future<void> initialize(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // When RevenueCat is disabled, grant everyone premium access
      if (!SubscriptionService.enabled) {
        _isPremium = true;
        _subscriptionSource = 'disabled';
        _subscriptionService.setExternalSubscriptionState(true);
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Initialize RevenueCat
      await _subscriptionService.initialize();
      await _subscriptionService.setUserId(userId);

      // Check premium status from multiple sources
      await refreshStatus();

      // Load available packages
      await loadPackages();
    } catch (e) {
      _error = 'Error loading subscription: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Refresh the premium status from RevenueCat + Firestore promo codes
  Future<void> refreshStatus() async {
    try {
      // Check RevenueCat subscription
      final rcPremium = await _subscriptionService.isPremium();
      if (rcPremium) {
        _isPremium = true;
        _subscriptionSource = 'revenuecat';
        _expirationDate = await _subscriptionService.getExpirationDate();
        _subscriptionService.setExternalSubscriptionState(true);
        notifyListeners();
        return;
      }

      // Check Firestore promo code subscription
      final promoPremium = await _promoCodeService.hasActivePromoSubscription();
      if (promoPremium) {
        _isPremium = true;
        _subscriptionSource = 'promo_code';
        final details = await _promoCodeService.getSubscriptionDetails();
        if (details != null && details['expiresAt'] != null) {
          _expirationDate = (details['expiresAt'] as dynamic).toDate();
        }
        _subscriptionService.setExternalSubscriptionState(true);
        notifyListeners();
        return;
      }

      // No active subscription
      _isPremium = false;
      _subscriptionSource = null;
      _expirationDate = null;
      _subscriptionService.setExternalSubscriptionState(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh subscription status error: $e');
    }
  }

  /// Load available packages from RevenueCat
  Future<void> loadPackages() async {
    try {
      _packages = await _subscriptionService.getPackages();
      notifyListeners();
    } catch (e) {
      debugPrint('Load packages error: $e');
    }
  }

  /// Purchase a subscription package
  Future<bool> purchase(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _subscriptionService.purchasePackage(package);
      if (success) {
        _isPremium = true;
        _subscriptionSource = 'revenuecat';
        _expirationDate = await _subscriptionService.getExpirationDate();
      }
      return success;
    } catch (e) {
      _error = 'Purchase failed: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _subscriptionService.restorePurchases();
      if (success) {
        _isPremium = true;
        _subscriptionSource = 'revenuecat';
        _expirationDate = await _subscriptionService.getExpirationDate();
      }
      return success;
    } catch (e) {
      _error = 'Restore failed: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Redeem a promo code
  Future<PromoCodeResult> redeemPromoCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _promoCodeService.redeemCode(code);
      if (result.success) {
        await refreshStatus();
      }
      return result;
    } catch (e) {
      _error = 'Error redeeming code: $e';
      debugPrint(_error);
      return PromoCodeResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log out — reset state
  Future<void> logout() async {
    await _subscriptionService.logout();
    _isPremium = false;
    _subscriptionSource = null;
    _expirationDate = null;
    _packages = [];
    _isTrialActive = false;
    notifyListeners();
  }
}
