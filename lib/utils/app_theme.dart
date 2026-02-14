import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern, cohesive design system for Breedly
/// Provides consistent styling across the entire app

// =============================================================================
// COLORS
// =============================================================================

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF4A6741); // Forest green
  static const Color primaryLight = Color(0xFF6B8B63);
  static const Color primaryDark = Color(0xFF2D4228);

  // Secondary palette
  static const Color secondary = Color(0xFFD4A574); // Warm gold
  static const Color secondaryLight = Color(0xFFE8C9A8);
  static const Color secondaryDark = Color(0xFFB8895A);

  // Accent colors for data visualization
  static const Color accent1 = Color(0xFF5B9BD5); // Blue
  static const Color accent2 = Color(0xFF70C1B3); // Teal
  static const Color accent3 = Color(0xFFF4A261); // Orange
  static const Color accent4 = Color(0xFFE07A5F); // Coral
  static const Color accent5 = Color(0xFF9B72CF); // Purple

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color neutral900 = Color(0xFF1A1A2E);
  static const Color neutral800 = Color(0xFF2D2D44);
  static const Color neutral700 = Color(0xFF4A4A5A);
  static const Color neutral600 = Color(0xFF6B6B7B);
  static const Color neutral500 = Color(0xFF8E8E9E);
  static const Color neutral400 = Color(0xFFB0B0BC);
  static const Color neutral300 = Color(0xFFD1D1D9);
  static const Color neutral200 = Color(0xFFE8E8EC);
  static const Color neutral100 = Color(0xFFF5F5F7);
  static const Color neutral50 = Color(0xFFFAFAFB);

  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Gender colors for dogs
  static const Color male = Color(0xFF5B9BD5);
  static const Color female = Color(0xFFE07A8A);

  // Status colors for litters/puppies
  static const Color available = Color(0xFF4CAF50);
  static const Color reserved = Color(0xFFFF9800);
  static const Color sold = Color(0xFF9E9E9E);

  // ==========================================================================
  // DARK MODE COLORS
  // ==========================================================================
  
  // Dark mode backgrounds
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E26);
  static const Color darkSurfaceVariant = Color(0xFF2A2A34);
  
  // Dark mode neutrals
  static const Color darkNeutral900 = Color(0xFFF5F5F7);
  static const Color darkNeutral800 = Color(0xFFE8E8EC);
  static const Color darkNeutral700 = Color(0xFFD1D1D9);
  static const Color darkNeutral600 = Color(0xFFB0B0BC);
  static const Color darkNeutral500 = Color(0xFF8E8E9E);
  static const Color darkNeutral400 = Color(0xFF6B6B7B);
  static const Color darkNeutral300 = Color(0xFF4A4A5A);
  static const Color darkNeutral200 = Color(0xFF3A3A46);
  static const Color darkNeutral100 = Color(0xFF2D2D38);
  static const Color darkNeutral50 = Color(0xFF242430);
}

// =============================================================================
// SPACING
// =============================================================================

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double massive = 64;
}

// =============================================================================
// RADIUS
// =============================================================================

class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
}

// =============================================================================
// SHADOWS
// =============================================================================

class AppShadows {
  static List<BoxShadow> get none => [];

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================

class AppTypography {
  static const String fontFamily = 'System';

  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.45,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.neutral500,
  );
}

// =============================================================================
// THEME BUILDER
// =============================================================================

class AppTheme {
  static ThemeData buildLightTheme({
    Color? primaryColor,
    Color? accentColor,
    Color? scaffoldColor,
  }) {
    final primary = primaryColor ?? AppColors.primary;
    final accent = accentColor ?? AppColors.secondary;
    final scaffold = scaffoldColor ?? AppColors.background;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withValues(alpha: 0.12),
        onPrimaryContainer: primary,
        secondary: accent,
        onSecondary: AppColors.neutral900,
        secondaryContainer: accent.withValues(alpha: 0.15),
        onSecondaryContainer: AppColors.neutral800,
        surface: AppColors.surface,
        onSurface: AppColors.neutral900,
        surfaceContainerHighest: AppColors.surfaceVariant,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.neutral300,
        outlineVariant: AppColors.neutral200,
      ),

      // Scaffold
      scaffoldBackgroundColor: scaffold,

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.neutral900,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.neutral900,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.neutral900,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.neutral900,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.neutral900,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.neutral900,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.neutral800,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.neutral800,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.neutral600,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.neutral700,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.neutral600,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.neutral500,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.neutral900,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
        iconTheme: const IconThemeData(color: AppColors.neutral700, size: 24),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.neutral500,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
        showUnselectedLabels: true,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(color: AppColors.neutral500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: AppColors.neutral500, size: 24);
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: AppColors.neutral200),
        ),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.neutral200,
          disabledForegroundColor: AppColors.neutral500,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: primary),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral600,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.neutral500,
        suffixIconColor: AppColors.neutral500,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: primary.withValues(alpha: 0.15),
        disabledColor: AppColors.neutral200,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: const BorderSide(color: Colors.transparent),
        ),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.neutral500,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.neutral200,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.neutral300,
        dragHandleSize: Size(40, 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral800,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.neutral900,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.neutral600,
        ),
        leadingAndTrailingTextStyle: AppTypography.labelMedium,
        iconColor: AppColors.neutral600,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.neutral600, size: 24),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppColors.neutral200,
        circularTrackColor: AppColors.neutral200,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.4);
          }
          return AppColors.neutral300;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.neutral400, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.neutral400;
        }),
      ),
    );
  }

  /// Build dark theme with the same color palette
  static ThemeData buildDarkTheme({
    Color? primaryColor,
    Color? accentColor,
  }) {
    final primary = primaryColor ?? AppColors.primary;
    final accent = accentColor ?? AppColors.secondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withValues(alpha: 0.2),
        onPrimaryContainer: primary,
        secondary: accent,
        onSecondary: AppColors.darkNeutral900,
        secondaryContainer: accent.withValues(alpha: 0.2),
        onSecondaryContainer: accent,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkNeutral900,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkNeutral300,
        outlineVariant: AppColors.darkNeutral200,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.darkNeutral900,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.darkNeutral900,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.darkNeutral900,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.darkNeutral900,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkNeutral900,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkNeutral900,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.darkNeutral900,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.darkNeutral900,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.darkNeutral800,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkNeutral800,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkNeutral700,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkNeutral600,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkNeutral700,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkNeutral600,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.darkNeutral500,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkNeutral900,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkNeutral900,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkNeutral700, size: 24),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.darkNeutral500,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
        showUnselectedLabels: true,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(color: AppColors.darkNeutral500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: AppColors.darkNeutral500, size: 24);
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: AppColors.darkNeutral200),
        ),
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.darkNeutral200,
          disabledForegroundColor: AppColors.darkNeutral500,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: primary),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.darkNeutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.darkNeutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkNeutral600,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkNeutral400,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.darkNeutral500,
        suffixIconColor: AppColors.darkNeutral500,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: primary.withValues(alpha: 0.25),
        disabledColor: AppColors.darkNeutral200,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkNeutral800,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: const BorderSide(color: Colors.transparent),
        ),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.darkNeutral500,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.darkNeutral200,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkNeutral200,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkNeutral900,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkNeutral700,
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkNeutral300,
        dragHandleSize: Size(40, 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkNeutral100,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkNeutral900,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.darkNeutral900,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.darkNeutral600,
        ),
        leadingAndTrailingTextStyle: AppTypography.labelMedium,
        iconColor: AppColors.darkNeutral600,
        tileColor: Colors.transparent,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.darkNeutral600, size: 24),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppColors.darkNeutral200,
        circularTrackColor: AppColors.darkNeutral200,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.darkNeutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.4);
          }
          return AppColors.darkNeutral300;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.darkNeutral400, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.darkNeutral400;
        }),
      ),
    );
  }
}
