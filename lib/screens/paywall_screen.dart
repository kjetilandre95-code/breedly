import 'package:flutter/material.dart';
import 'package:breedly/utils/lucide_icons.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/subscription_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback? onSubscribed;
  final VoidCallback? onDismissed;
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
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.allowDismiss)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      widget.onDismissed?.call();
                    },
                    icon: Icon(
                      LucideIcons.x,
                      color: context.colors.textCaption,
                    ),
                  ),
                ),
              const Spacer(),
              const Icon(
                LucideIcons.crown,
                size: 72,
                color: AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Peddex',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Subscription-only professional breeding management.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildFeatureRow('Unlimited Dogs'),
              _buildFeatureRow('Pro Contracts'),
              _buildFeatureRow('Exhibition Analytics'),
              const Spacer(),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Subscribe for 149,-/mo'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _isProcessing ? null : _restore,
                child: const Text('Restore purchases'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _logOut,
                icon: const Icon(LucideIcons.logOut),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe() async {
    setState(() => _isProcessing = true);
    try {
      final service = SubscriptionService();
      await service.initialize();
      final purchased = await service.presentPaywall();
      if (!mounted) return;
      if (purchased) {
        widget.onSubscribed?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription not completed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isProcessing = true);
    try {
      final restored = await SubscriptionService().restorePurchases();
      if (!mounted) return;
      if (restored) {
        widget.onSubscribed?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchases found')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _logOut() async {
    setState(() => _isProcessing = true);
    try {
      await SubscriptionService().logout();
      await AuthService().signOut();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
