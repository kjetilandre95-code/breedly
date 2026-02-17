import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a promo code
class PromoCode {
  final String code;
  final int discountPercent; // 100 = free
  final String type; // 'lifetime', 'months'
  final int? durationMonths;
  final int maxUses;
  final int usedCount;
  final List<String> usedBy;
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;

  PromoCode({
    required this.code,
    required this.discountPercent,
    required this.type,
    this.durationMonths,
    required this.maxUses,
    required this.usedCount,
    required this.usedBy,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isValid {
    if (usedCount >= maxUses) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  bool get isFree => discountPercent >= 100;

  bool isUsedBy(String userId) => usedBy.contains(userId);

  factory PromoCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCode(
      code: data['code'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      type: data['type'] ?? 'months',
      durationMonths: data['durationMonths'],
      maxUses: data['maxUses'] ?? 1,
      usedCount: data['usedCount'] ?? 0,
      usedBy: List<String>.from(data['usedBy'] ?? []),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Result of applying a promo code
class PromoCodeResult {
  final bool success;
  final String message;
  final PromoCode? promoCode;

  PromoCodeResult({
    required this.success,
    required this.message,
    this.promoCode,
  });
}

/// Service for managing promo codes via Firestore
class PromoCodeService {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate and apply a promo code for the current user
  Future<PromoCodeResult> redeemCode(String code) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return PromoCodeResult(
        success: false,
        message: 'Du må være logget inn.',
      );
    }

    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      return PromoCodeResult(
        success: false,
        message: 'Vennligst skriv inn en kode.',
      );
    }

    try {
      // Look up the promo code
      final doc = await _firestore
          .collection('promo_codes')
          .doc(normalizedCode)
          .get();

      if (!doc.exists) {
        return PromoCodeResult(
          success: false,
          message: 'Ugyldig kode.',
        );
      }

      final promoCode = PromoCode.fromFirestore(doc);

      // Check if expired
      if (promoCode.expiresAt != null &&
          DateTime.now().isAfter(promoCode.expiresAt!)) {
        return PromoCodeResult(
          success: false,
          message: 'Denne koden har utløpt.',
        );
      }

      // Check if max uses reached
      if (promoCode.usedCount >= promoCode.maxUses) {
        return PromoCodeResult(
          success: false,
          message: 'Denne koden er brukt opp.',
        );
      }

      // Check if user already used this code
      if (promoCode.isUsedBy(userId)) {
        return PromoCodeResult(
          success: false,
          message: 'Du har allerede brukt denne koden.',
        );
      }

      // Apply the code — update Firestore
      final batch = _firestore.batch();

      // Update promo code usage
      batch.update(doc.reference, {
        'usedCount': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([userId]),
      });

      // Calculate expiration for user's premium access
      DateTime? premiumExpires;
      if (promoCode.type == 'months' && promoCode.durationMonths != null) {
        premiumExpires = DateTime.now().add(
          Duration(days: promoCode.durationMonths! * 30),
        );
      }
      // type == 'lifetime' → premiumExpires stays null (= permanent)

      // Grant premium access to user
      batch.set(
        _firestore.collection('user_subscriptions').doc(userId),
        {
          'isPremium': true,
          'source': 'promo_code',
          'promoCode': normalizedCode,
          'discountPercent': promoCode.discountPercent,
          'grantedAt': FieldValue.serverTimestamp(),
          'expiresAt': premiumExpires != null
              ? Timestamp.fromDate(premiumExpires)
              : null,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      final durationText = promoCode.type == 'lifetime'
          ? 'permanent'
          : '${promoCode.durationMonths} måneder';
      final discountText = promoCode.isFree
          ? 'Gratis tilgang'
          : '${promoCode.discountPercent}% rabatt';

      return PromoCodeResult(
        success: true,
        message: '$discountText aktivert ($durationText)! 🎉',
        promoCode: promoCode,
      );
    } catch (e) {
      debugPrint('Promo code error: $e');
      return PromoCodeResult(
        success: false,
        message: 'Noe gikk galt. Prøv igjen.',
      );
    }
  }

  /// Check if the current user has an active promo-based subscription
  Future<bool> hasActivePromoSubscription() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('user_subscriptions')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final isPremium = data['isPremium'] == true;
      if (!isPremium) return false;

      // Check if it has an expiration
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        // Expired — update Firestore
        await doc.reference.update({'isPremium': false});
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Check promo subscription error: $e');
      return false;
    }
  }

  /// Get user's subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('user_subscriptions')
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Get subscription details error: $e');
      return null;
    }
  }
}
