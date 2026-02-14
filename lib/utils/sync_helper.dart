import 'package:flutter/material.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/data_sync_service.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class SyncHelper {
  static Future<void> performSyncWithFeedback(BuildContext context) async {
    try {
      final authService = AuthService();
      if (authService.isAuthenticated && authService.currentUserId != null) {
        // Show sync indicator
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.syncingData ?? 'Synkroniserer data...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final dataSyncService = DataSyncService();
        await dataSyncService.performFullSync(authService.currentUserId!);

        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.dataSynced ?? 'Data synkronisert')),
          );
        }
      }
    } catch (e) {
      AppLogger.debug('Error syncing data: $e');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.syncFailed ?? 'Synkronisering feilet')),
        );
      }
    }
  }

  static Future<void> performSilentSync() async {
    try {
      final authService = AuthService();
      if (authService.isAuthenticated && authService.currentUserId != null) {
        final dataSyncService = DataSyncService();
        await dataSyncService.performFullSync(authService.currentUserId!);
        AppLogger.debug('Silent sync completed successfully');
      }
    } catch (e) {
      AppLogger.debug('Error during silent sync: $e');
    }
  }
}
