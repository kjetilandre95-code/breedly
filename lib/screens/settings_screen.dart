import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:breedly/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/data_sync_service.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/services/reminder_manager.dart';
import 'package:breedly/screens/statistics_screen.dart';
import 'package:breedly/screens/annual_report_screen.dart';
import 'package:breedly/screens/pedigree_scanner_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Language Section
          _buildSectionCard(
            title: localizations.language,
            subtitle: localizations.selectTheme,
            icon: Icons.language_rounded,
            child: _buildLanguageOptions(context, localizations),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Theme Section
          _buildSectionCard(
            title: localizations.colorTheme,
            subtitle: localizations.selectTheme,
            icon: Icons.palette_rounded,
            child: _buildThemeColorGrid(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Dark Mode Section
          _buildSectionCard(
            title: localizations.darkMode,
            subtitle: localizations.darkModeDescription,
            icon: Icons.dark_mode_rounded,
            child: _buildDarkModeSection(localizations),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Account Section
          _buildSectionCard(
            title: localizations.account,
            subtitle: AuthService().currentUserEmail ?? localizations.notLoggedIn,
            icon: Icons.person_rounded,
            child: _buildAccountSection(localizations),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Notifications Section
          _buildSectionCard(
            title: localizations.notifications,
            subtitle: localizations.manageReminders,
            icon: Icons.notifications_rounded,
            child: _buildNotificationsSection(localizations),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Statistics Section
          _buildStatisticsCard(localizations),

          const SizedBox(height: AppSpacing.lg),
          
          // Developer/Test Section
          _buildDeveloperSection(localizations),

          const SizedBox(height: AppSpacing.lg),

          // App Info
          _buildAppInfoCard(localizations),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: ThemeOpacity.low(context)),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
        ],
      ),
    );
  }

  Widget _buildLanguageOptions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final languages = [
      {'code': 'no', 'name': 'Norsk', 'flag': '🇳🇴'},
      {'code': 'sv', 'name': 'Svenska', 'flag': '🇸🇪'},
      {'code': 'da', 'name': 'Dansk', 'flag': '🇩🇰'},
      {'code': 'fi', 'name': 'Suomi', 'flag': '🇫🇮'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    final currentLanguage = context.read<LanguageProvider>().currentLocale.languageCode;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: languages.map((lang) {
        final isSelected = currentLanguage == lang['code'];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await context.read<LanguageProvider>().setLanguage(lang['code']!);
                setState(() {});
              },
              borderRadius: AppRadius.mdAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: ThemeOpacity.medium(context))
                      : AppColors.surfaceVariant,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        lang['name']!,
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected
                              ? primaryColor
                              : AppColors.neutral800,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeColorGrid() {
    final themes = ThemeProvider.availableThemes;
    final selectedIndex = context.read<ThemeProvider>().selectedThemeIndex;
    final localizations = AppLocalizations.of(context);
    final isEnglish = context.read<LanguageProvider>().currentLocale.languageCode == 'en';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = index == selectedIndex;
        
        // Get localized theme name based on language
        String themeName;
        switch (index) {
          case 0: themeName = localizations?.themeForestGreen ?? theme.name; break;
          case 1: themeName = localizations?.themeOceanBlue ?? theme.name; break;
          case 2: themeName = localizations?.themeTerracotta ?? theme.name; break;
          case 3: themeName = localizations?.themePlum ?? theme.name; break;
          case 4: themeName = localizations?.themeSlate ?? theme.name; break;
          case 5: themeName = localizations?.themeRose ?? theme.name; break;
          case 6: themeName = localizations?.themeTeal ?? theme.name; break;
          case 7: themeName = localizations?.themeAmber ?? theme.name; break;
          default: themeName = isEnglish ? theme.nameEn : theme.name;
        }

        return GestureDetector(
          onTap: () async {
            await context.read<ThemeProvider>().setTheme(index);
            setState(() {});
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neutral900
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? AppShadows.colored(theme.primaryColor)
                      : AppShadows.sm,
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : theme.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                themeName,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? theme.primaryColor : AppColors.neutral600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDarkModeSection(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;
    final useSystemTheme = context.read<ThemeProvider>().useSystemTheme;
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    return Column(
      children: [
        // Use system theme toggle
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await context.read<ThemeProvider>().setUseSystemTheme(!useSystemTheme);
              setState(() {});
            },
            borderRadius: AppRadius.mdAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: useSystemTheme
                    ? primaryColor.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: useSystemTheme ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.brightness_auto_rounded,
                    color: useSystemTheme ? primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.useSystemTheme,
                          style: AppTypography.titleSmall.copyWith(
                            color: useSystemTheme
                                ? primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: useSystemTheme
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          localizations.useSystemThemeDescription,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: useSystemTheme,
                    onChanged: (value) async {
                      await context.read<ThemeProvider>().setUseSystemTheme(value);
                      setState(() {});
                    },
                    activeThumbColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),

        // Manual dark mode toggle (disabled when using system theme)
        AnimatedOpacity(
          opacity: useSystemTheme ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: useSystemTheme,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await context.read<ThemeProvider>().setDarkMode(!isDarkMode);
                  setState(() {});
                },
                borderRadius: AppRadius.mdAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: (!useSystemTheme && isDarkMode)
                        ? primaryColor.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                      color: (!useSystemTheme && isDarkMode) 
                          ? primaryColor 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDarkMode 
                            ? Icons.dark_mode_rounded 
                            : Icons.light_mode_rounded,
                        color: (!useSystemTheme && isDarkMode)
                            ? primaryColor
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          isDarkMode 
                              ? localizations.darkModeOn 
                              : localizations.darkModeOff,
                          style: AppTypography.titleSmall.copyWith(
                            color: (!useSystemTheme && isDarkMode)
                                ? primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: (!useSystemTheme && isDarkMode)
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: useSystemTheme 
                            ? null 
                            : (value) async {
                                await context.read<ThemeProvider>().setDarkMode(value);
                                setState(() {});
                              },
                        activeThumbColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Column(
      children: [
        // Sync to cloud button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _syncDataToCloud(localizations),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text(localizations.syncToCloud),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Sync from cloud button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _syncDataFromCloud(localizations),
            icon: const Icon(Icons.cloud_download_rounded),
            label: Text(localizations.syncFromCloud),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              side: BorderSide(color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  localizations.syncInfo,
                  style: AppTypography.caption.copyWith(
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Logout button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context, localizations),
            icon: const Icon(Icons.logout_rounded),
            label: Text(localizations.logOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _syncDataToCloud(AppLocalizations localizations) async {
    final authService = AuthService();
    if (!authService.isAuthenticated || authService.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.notLoggedIn)),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.syncingData),
        duration: const Duration(seconds: 2),
      ),
    );
    
    try {
      final dataSyncService = DataSyncService();
      await dataSyncService.uploadAllDataToFirebase(authService.currentUserId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.dataSynced),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.syncFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _syncDataFromCloud(AppLocalizations localizations) async {
    final authService = AuthService();
    if (!authService.isAuthenticated || authService.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.notLoggedIn)),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.syncingData),
        duration: const Duration(seconds: 2),
      ),
    );
    
    try {
      final dataSyncService = DataSyncService();
      await dataSyncService.syncAllDataFromFirebase(authService.currentUserId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.dataSynced),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.syncFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNotificationsSection(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // Refresh all reminders button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.updatingReminders)),
              );
              await ReminderManager().refreshAllReminders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.remindersUpdated),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text(localizations.updateAllReminders),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Info text
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  localizations.notificationsInfo,
                  style: AppTypography.caption.copyWith(
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Cancel all notifications button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(localizations.turnOffNotificationsTitle),
                  content: Text(localizations.turnOffNotificationsMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(localizations.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(dialogContext);
                        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                        await NotificationService().cancelAllNotifications();
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(localizations.allNotificationsTurnedOff),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(localizations.turnOff),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.notifications_off_outlined),
            label: Text(localizations.turnOffAllNotifications),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(AppLocalizations localizations) {
    final dogBox = Hive.box<Dog>('dogs');
    final litterBox = Hive.box<Litter>('litters');
    final buyerBox = Hive.box<Buyer>('buyers');
    final puppyBox = Hive.box<Puppy>('puppies');
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.neutral200),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  Icons.storage_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                localizations.dataInApp,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStatRow(
            FontAwesomeIcons.dog,
            localizations.dogs,
            dogBox.values.where((d) => !d.isPedigreeOnly).length.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            FontAwesomeIcons.paw,
            localizations.litters,
            litterBox.length.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            FontAwesomeIcons.bone,
            localizations.puppies,
            puppyBox.length.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            Icons.people_rounded,
            localizations.buyers,
            buyerBox.length.toString(),
            Theme.of(context).primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded),
              label: Text(localizations.viewDetailedStatistics),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnualReportScreen()),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(localizations.annualReport),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.neutral200),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                localizations.aboutApp,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow(localizations.version, '1.0.0'),
          _buildInfoRow(localizations.developer, 'Exentri Team'),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizations.welcomeMessage,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          title: Text(
            localizations.logOut,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          content: Text(
            localizations.logOutConfirm,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                localizations.cancel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              child: Text(localizations.confirm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeveloperSection(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(Icons.science_outlined, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utvikler & Testing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Test nye funksjoner',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: AppRadius.smAll,
              ),
              child: const Icon(Icons.document_scanner, color: Colors.blue, size: 20),
            ),
            title: const Text(
              'Test stamtavle-skanner',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Google ML Kit OCR - Skann stamtavler med AI',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Text(
                'NY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PedigreeScannerTestScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
