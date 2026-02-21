import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:breedly/providers/subscription_provider.dart';
import 'package:breedly/utils/app_theme.dart';

/// Paywall screen using RevenueCat's built-in PaywallView + custom promo code input
class PaywallScreen extends StatefulWidget {
  /// Called when the user successfully subscribes or redeems a promo code
  final VoidCallback? onSubscribed;

  /// Called when the user dismisses/skips the paywall
  final VoidCallback? onDismissed;

  /// Whether to show a close/skip button (false = mandatory paywall)
  final bool allowDismiss;

  const PaywallScreen({
    super.key,
    this.onSubscribed,
    this.onDismissed,
    this.allowDismiss = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isProcessing = false;
  String? _promoMessage;
  bool _promoSuccess = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            if (widget.allowDismiss)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (widget.onDismissed != null) {
                        widget.onDismissed!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkNeutral600
                          : AppColors.neutral600,
                    ),
                  ),
                ),
              ),

            // RevenueCat PaywallView — handles plan display, purchasing & restore
            Expanded(
              flex: 3,
              child: PaywallView(
                onDismiss: () async {
                  // Check if the user became premium after interacting with the paywall
                  await subProvider.refreshStatus();
                  if (subProvider.isPremium && mounted) {
                    _showSuccessAndDismiss();
                  }
                },
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppColors.darkNeutral300
                          : AppColors.neutral300,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text(
                      'eller',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkNeutral500
                            : AppColors.neutral500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppColors.darkNeutral300
                          : AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),

            // Promo code section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Har du en kampanjekode?',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkNeutral900
                          : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Skriv inn kode',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkNeutral500
                                  : AppColors.neutral400,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdAll,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _handlePromoCode(subProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdAll,
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Løs inn'),
                        ),
                      ),
                    ],
                  ),
                  if (_promoMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _promoMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: _promoSuccess
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePromoCode(SubscriptionProvider subProvider) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoMessage = 'Vennligst skriv inn en kode.';
        _promoSuccess = false;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _promoMessage = null;
    });

    try {
      final result = await subProvider.redeemPromoCode(code);
      if (mounted) {
        setState(() {
          _promoMessage = result.message;
          _promoSuccess = result.success;
        });
        if (result.success) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _showSuccessAndDismiss();
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessAndDismiss() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Velkommen til Breedly Premium!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
    widget.onSubscribed?.call();
    if (widget.allowDismiss) {
      Navigator.of(context).pop(true);
    }
  }
}
