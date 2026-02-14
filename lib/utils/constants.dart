import 'package:flutter/material.dart';

class AppConstants {
  // Animation durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 2);

  // Opacity values - Light mode
  static const double lowOpacity = 0.08;
  static const double mediumOpacity = 0.15;
  static const double highOpacity = 0.2;

  // Opacity values - Dark mode (higher for visibility)
  static const double lowOpacityDark = 0.20;
  static const double mediumOpacityDark = 0.30;
  static const double highOpacityDark = 0.40;

  // Border radius
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;
  static const double hugeSpacing = 32.0;

  // Icon sizes
  static const double smallIconSize = 20.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 48.0;

  // Font sizes
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 24.0;

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.green;
  static const Color accentColor = Colors.orange;
  static const Color errorColor = Colors.red;

  // Heat cycle colors
  static const Color heatCycleColor = Color(0xFFE91E63);
  static const Color nextHeatCycleColor = Color(0xFF4CAF50);

  // Litter age threshold (weeks)
  static const int activeLitterThresholdWeeks = 10;

  // Date limits
  static const int minDogAgeYears = 1900;
  static const int maxFutureYears = 10;
}

/// Helper class for theme-aware opacity values
class ThemeOpacity {
  /// Returns appropriate low opacity based on theme brightness
  static double low(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppConstants.lowOpacityDark
        : AppConstants.lowOpacity;
  }

  /// Returns appropriate medium opacity based on theme brightness
  static double medium(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppConstants.mediumOpacityDark
        : AppConstants.mediumOpacity;
  }

  /// Returns appropriate high opacity based on theme brightness
  static double high(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppConstants.highOpacityDark
        : AppConstants.highOpacity;
  }

  /// Checks if dark mode is active
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
