import 'package:flutter/material.dart';
import 'package:breedly/utils/constants.dart';

class AppWidgets {
  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largeSpacing),
        child: Column(
          children: [
            Container(
              width: AppConstants.largeIconSize,
              height: AppConstants.largeIconSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: AppConstants.mediumOpacity),
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppConstants.mediumIconSize,
              ),
            ),
            const SizedBox(height: AppConstants.mediumSpacing),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppConstants.extraLargeFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: AppConstants.smallFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largeSpacing),
          child: Column(
            children: [
              Container(
                width: AppConstants.largeIconSize,
                height: AppConstants.largeIconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppConstants.mediumOpacity),
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppConstants.mediumIconSize,
                ),
              ),
              const SizedBox(height: AppConstants.mediumSpacing),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.mediumFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: AppConstants.mediumSpacing),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
