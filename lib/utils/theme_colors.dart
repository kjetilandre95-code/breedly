import 'package:flutter/material.dart';
import 'package:breedly/utils/app_theme.dart';

/// Theme-aware color resolver — use via `context.colors`
/// Automatically returns light or dark mode colors based on current theme.
///
/// Example:
///   color: context.colors.textPrimary    // instead of AppColors.neutral900
///   color: context.colors.surface        // instead of AppColors.surface
///   color: context.colors.border         // instead of AppColors.neutral200
extension ThemeColors on BuildContext {
  ResolvedColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return ResolvedColors(isDark);
  }

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class ResolvedColors {
  final bool _isDark;
  const ResolvedColors(this._isDark);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  Color get background => _isDark ? AppColors.darkBackground : AppColors.background;
  Color get surface => _isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfaceVariant => _isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

  // ── Text colors (neutral scale) ──────────────────────────────────────────
  /// Primary text — headings, titles, body text
  Color get textPrimary => _isDark ? AppColors.darkNeutral900 : AppColors.neutral900;
  /// Secondary text — subtitles, descriptions
  Color get textSecondary => _isDark ? AppColors.darkNeutral800 : AppColors.neutral800;
  /// Tertiary text — less prominent labels
  Color get textTertiary => _isDark ? AppColors.darkNeutral700 : AppColors.neutral700;
  /// Muted text — helper text, secondary info
  Color get textMuted => _isDark ? AppColors.darkNeutral600 : AppColors.neutral600;
  /// Caption text — timestamps, footnotes
  Color get textCaption => _isDark ? AppColors.darkNeutral500 : AppColors.neutral500;
  /// Disabled/placeholder text
  Color get textDisabled => _isDark ? AppColors.darkNeutral400 : AppColors.neutral400;

  // ── Borders & dividers ───────────────────────────────────────────────────
  /// Standard border
  Color get border => _isDark ? AppColors.darkNeutral200 : AppColors.neutral200;
  /// Subtle/light border
  Color get borderSubtle => _isDark ? AppColors.darkNeutral100 : AppColors.neutral100;
  /// Divider line
  Color get divider => _isDark ? AppColors.darkNeutral300 : AppColors.neutral300;

  // ── Neutral backgrounds ──────────────────────────────────────────────────
  /// Subtle background for cards, sections
  Color get neutral50 => _isDark ? AppColors.darkNeutral50 : AppColors.neutral50;
  Color get neutral100 => _isDark ? AppColors.darkNeutral100 : AppColors.neutral100;
  Color get neutral200 => _isDark ? AppColors.darkNeutral200 : AppColors.neutral200;
  Color get neutral300 => _isDark ? AppColors.darkNeutral300 : AppColors.neutral300;
  Color get neutral400 => _isDark ? AppColors.darkNeutral400 : AppColors.neutral400;
  Color get neutral500 => _isDark ? AppColors.darkNeutral500 : AppColors.neutral500;
  Color get neutral600 => _isDark ? AppColors.darkNeutral600 : AppColors.neutral600;
  Color get neutral700 => _isDark ? AppColors.darkNeutral700 : AppColors.neutral700;
  Color get neutral800 => _isDark ? AppColors.darkNeutral800 : AppColors.neutral800;
  Color get neutral900 => _isDark ? AppColors.darkNeutral900 : AppColors.neutral900;

  // ── Icon colors ──────────────────────────────────────────────────────────
  /// Primary icon color
  Color get iconPrimary => _isDark ? AppColors.darkNeutral800 : AppColors.neutral700;
  /// Muted icon color
  Color get iconMuted => _isDark ? AppColors.darkNeutral500 : AppColors.neutral500;
}
