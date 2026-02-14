import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/app_theme.dart';

/// Theme configuration for the app
/// Provides multiple color themes while maintaining consistent design language

class AppThemeColor {
  final String name;
  final String nameEn;
  final Color primaryColor;
  final Color accentColor;
  final Color scaffoldColor;
  final IconData icon;

  const AppThemeColor({
    required this.name,
    required this.nameEn,
    required this.primaryColor,
    required this.accentColor,
    required this.scaffoldColor,
    required this.icon,
  });
}

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'app_settings';
  static const String _themeKey = 'selected_theme';
  static const String _darkModeKey = 'dark_mode';
  static const String _systemThemeKey = 'use_system_theme';

  // Modern, carefully crafted color themes
  static final List<AppThemeColor> availableThemes = [
    // Default - Forest Green (Professional, nature-inspired)
    const AppThemeColor(
      name: 'Skoggrønn',
      nameEn: 'Forest Green',
      primaryColor: Color(0xFF4A6741),
      accentColor: Color(0xFFD4A574),
      scaffoldColor: Color(0xFFF8F9FA),
      icon: Icons.forest_rounded,
    ),

    // Ocean Blue (Calm, trustworthy)
    const AppThemeColor(
      name: 'Havblå',
      nameEn: 'Ocean Blue',
      primaryColor: Color(0xFF2563EB),
      accentColor: Color(0xFF60A5FA),
      scaffoldColor: Color(0xFFF8FAFC),
      icon: Icons.water_rounded,
    ),

    // Warm Terracotta (Earthy, welcoming)
    const AppThemeColor(
      name: 'Terrakotta',
      nameEn: 'Terracotta',
      primaryColor: Color(0xFFB45309),
      accentColor: Color(0xFFFBBF24),
      scaffoldColor: Color(0xFFFFFBEB),
      icon: Icons.wb_sunny_rounded,
    ),

    // Plum Purple (Elegant, modern)
    const AppThemeColor(
      name: 'Plomme',
      nameEn: 'Plum',
      primaryColor: Color(0xFF7C3AED),
      accentColor: Color(0xFFA78BFA),
      scaffoldColor: Color(0xFFFAF5FF),
      icon: Icons.spa_rounded,
    ),

    // Slate Gray (Minimal, professional)
    const AppThemeColor(
      name: 'Skifer',
      nameEn: 'Slate',
      primaryColor: Color(0xFF475569),
      accentColor: Color(0xFF94A3B8),
      scaffoldColor: Color(0xFFF8FAFC),
      icon: Icons.auto_awesome_rounded,
    ),

    // Rose Pink (Soft, friendly)
    const AppThemeColor(
      name: 'Rose',
      nameEn: 'Rose',
      primaryColor: Color(0xFFDB2777),
      accentColor: Color(0xFFF472B6),
      scaffoldColor: Color(0xFFFDF2F8),
      icon: Icons.favorite_rounded,
    ),

    // Teal (Fresh, modern)
    const AppThemeColor(
      name: 'Havgrønn',
      nameEn: 'Teal',
      primaryColor: Color(0xFF0D9488),
      accentColor: Color(0xFF5EEAD4),
      scaffoldColor: Color(0xFFF0FDFA),
      icon: Icons.eco_rounded,
    ),

    // Amber (Warm, energetic)
    const AppThemeColor(
      name: 'Amber',
      nameEn: 'Amber',
      primaryColor: Color(0xFFD97706),
      accentColor: Color(0xFFFCD34D),
      scaffoldColor: Color(0xFFFFFBEB),
      icon: Icons.light_mode_rounded,
    ),
  ];

  int _selectedThemeIndex = 0;
  bool _isInitialized = false;
  bool _isDarkMode = false;
  bool _useSystemTheme = true;

  ThemeProvider();

  int get selectedThemeIndex => _selectedThemeIndex;
  AppThemeColor get currentTheme => availableThemes[_selectedThemeIndex];
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  /// Initialize theme from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final box = await Hive.openBox(_boxName);
      final storedIndex = box.get(_themeKey, defaultValue: 0);
      if (storedIndex is int &&
          storedIndex >= 0 &&
          storedIndex < availableThemes.length) {
        _selectedThemeIndex = storedIndex;
      } else {
        _selectedThemeIndex = 0;
      }
      _isDarkMode = box.get(_darkModeKey, defaultValue: false);
      _useSystemTheme = box.get(_systemThemeKey, defaultValue: true);
    } catch (e) {
      _selectedThemeIndex = 0;
      _isDarkMode = false;
      _useSystemTheme = true;
    }
    _isInitialized = true;
  }

  Future<void> setTheme(int index) async {
    if (index >= 0 && index < availableThemes.length) {
      _selectedThemeIndex = index;
      try {
        final box = await Hive.openBox(_boxName);
        await box.put(_themeKey, index);
      } catch (e) {
        // Ignore storage errors
      }
      notifyListeners();
    }
  }

  /// Toggle dark mode on/off
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_darkModeKey, value);
    } catch (e) {
      // Ignore storage errors
    }
    notifyListeners();
  }

  /// Toggle system theme preference
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_systemThemeKey, value);
    } catch (e) {
      // Ignore storage errors
    }
    notifyListeners();
  }

  /// Check if dark mode should be active based on settings and system preference
  bool shouldUseDarkMode(BuildContext context) {
    if (_useSystemTheme) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _isDarkMode;
  }

  /// Build the complete theme data using the design system
  ThemeData buildTheme() {
    final theme = currentTheme;
    return AppTheme.buildLightTheme(
      primaryColor: theme.primaryColor,
      accentColor: theme.accentColor,
      scaffoldColor: theme.scaffoldColor,
    );
  }

  /// Build the dark theme data
  ThemeData buildDarkTheme() {
    final theme = currentTheme;
    return AppTheme.buildDarkTheme(
      primaryColor: theme.primaryColor,
      accentColor: theme.accentColor,
    );
  }

  /// Build appropriate theme based on dark mode setting
  ThemeData buildThemeForContext(BuildContext context) {
    if (shouldUseDarkMode(context)) {
      return buildDarkTheme();
    }
    return buildTheme();
  }

  /// Get system UI overlay style for status bar
  SystemUiOverlayStyle getSystemUiStyle({bool isDark = false}) {
    if (isDark) {
      return SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.darkSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  /// Get system UI style based on current dark mode setting
  SystemUiOverlayStyle getSystemUiStyleForContext(BuildContext context) {
    return getSystemUiStyle(isDark: shouldUseDarkMode(context));
  }
}
