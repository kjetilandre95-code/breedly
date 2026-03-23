import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:peddex/generated_l10n/app_localizations.dart';
import 'package:peddex/providers/language_provider.dart';
import 'package:peddex/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:peddex/services/auth_service.dart';
import 'package:peddex/services/cloud_sync_service.dart';
import 'package:peddex/utils/app_theme.dart';
import 'package:peddex/utils/theme_colors.dart';
import 'package:peddex/utils/constants.dart';
import 'package:peddex/screens/statistics_screen.dart';
import 'package:peddex/screens/annual_report_screen.dart';
import 'package:peddex/screens/custom_terms_screen.dart';
import 'package:peddex/screens/trash_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:peddex/providers/progesterone_unit_provider.dart';
import 'package:peddex/repositories/peddex_repository.dart';
import 'package:peddex/utils/performance_telemetry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();

  void _showDebugInfo() {
    final perf = PerformanceTelemetry.allLastExecutionMs();
    final exportMs = perf['showResultExportMs'];
    final statsMs = perf['showStatsMemoizedMs'];
    final message = StringBuffer()
      ..writeln('Debug Info')
      ..writeln('Cache entries: ${PeddexRepository.activeCacheEntries}')
      ..writeln('Firestore reads: ${PeddexRepository.firestoreReadCount}')
      ..writeln('Last export: ${exportMs != null ? '${exportMs}ms' : '-'}')
      ..writeln('Last stats calc: ${statsMs != null ? '${statsMs}ms' : '-'}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.toString().trim()),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<({int dogs, int litters, int puppies, int buyers})> _loadStats() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      return (dogs: 0, litters: 0, puppies: 0, buyers: 0);
    }

    final sync = FirestoreService();
    final dogs = await sync.baseQuery('dogs', userId).get();
    final litters = await sync.baseQuery('litters', userId).get();
    final puppies = await sync.baseQuery('puppies', userId).get();
    final buyers = await sync.baseQuery('buyers', userId).get();

    return (
      dogs: dogs.docs.where((d) => d.data()['isPedigreeOnly'] != true).length,
      litters: litters.docs.length,
      puppies: puppies.docs.length,
      buyers: buyers.docs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 900 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
            // Language Section
            _buildSectionCard(
              title: localizations.language,
            subtitle: localizations.selectTheme,
            icon: LucideIcons.languages,
            child: _buildLanguageOptions(context, localizations),
          ),

          const Gap(AppSpacing.lg),

          // Theme Section
          _buildSectionCard(
            title: localizations.colorTheme,
            subtitle: localizations.selectTheme,
            icon: LucideIcons.palette,
            child: _buildThemeColorGrid(),
          ),

          const Gap(AppSpacing.lg),

          // Progesterone Unit Section
          _buildSectionCard(
            title: localizations.progesteroneUnitSetting,
            subtitle: localizations.progesteroneUnitSettingDesc,
            icon: LucideIcons.flaskConical,
            child: _buildProgesteroneUnitSection(localizations),
          ),

          const Gap(AppSpacing.lg),

          // Custom Contract Terms Section
          _buildCustomTermsCard(localizations),

          const Gap(AppSpacing.lg),

          // Statistics Section
          _buildStatisticsCard(localizations),

          const Gap(AppSpacing.lg),

          // App Info
          _buildAppInfoCard(localizations),

          const Gap(AppSpacing.xxxl),
          ],
        ),
          ),
        ),
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
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.border),
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
                          color: context.colors.textPrimary,
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
      // Swedish, Danish and Finnish on hold for now
      // {'code': 'sv', 'name': 'Svenska', 'flag': '🇸🇪'},
      // {'code': 'da', 'name': 'Dansk', 'flag': '🇩🇰'},
      // {'code': 'fi', 'name': 'Suomi', 'flag': '🇫🇮'},
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
                      : context.colors.surfaceVariant,
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
                              : context.colors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        LucideIcons.checkCircle,
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

    final isWideScreen = kIsWeb && MediaQuery.of(context).size.width > 768;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 8 : 4,
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
                        ? context.colors.textPrimary
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? AppShadows.colored(theme.primaryColor)
                      : AppShadows.sm,
                ),
                child: Icon(
                  isSelected ? LucideIcons.check : theme.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                themeName,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? theme.primaryColor : context.colors.textMuted,
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

  Widget _buildProgesteroneUnitSection(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;
    final unitProvider = context.watch<ProgesteroneUnitProvider>();
    final units = [
      {'value': 'ng/mL', 'label': 'ng/mL', 'desc': localizations.progesteroneUnitNgMlDesc},
      {'value': 'nmol/L', 'label': 'nmol/L', 'desc': localizations.progesteroneUnitNmolDesc},
    ];

    return Column(
      children: units.map((unit) {
        final isSelected = unitProvider.preferredUnit == unit['value'];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await unitProvider.setUnit(unit['value']!);
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
                      : context.colors.surfaceVariant,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? primaryColor : context.colors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit['label']!,
                            style: AppTypography.titleSmall.copyWith(
                              color: isSelected
                                  ? primaryColor
                                  : context.colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            unit['desc']!,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
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

  Widget _buildCustomTermsCard(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: context.colors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlAll,
        child: InkWell(
          borderRadius: AppRadius.xlAll,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomTermsScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(
                    LucideIcons.fileText,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.customTerms,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(AppSpacing.xxs),
                      Text(
                        localizations.customTermsDesc,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: context.colors.textCaption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(AppLocalizations localizations) {
    final primaryColor = Theme.of(context).primaryColor;

    return FutureBuilder<({int dogs, int litters, int puppies, int buyers})>(
      future: _loadStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? (dogs: 0, litters: 0, puppies: 0, buyers: 0);
        return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.border),
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
                  LucideIcons.database,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                localizations.dataInApp,
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          _buildStatRow(
            LucideIcons.dog,
            localizations.dogs,
            stats.dogs.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            LucideIcons.footprints,
            localizations.litters,
            stats.litters.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            LucideIcons.bone,
            localizations.puppies,
            stats.puppies.toString(),
            Theme.of(context).primaryColor,
          ),
          _buildStatRow(
            LucideIcons.users,
            localizations.buyers,
            stats.buyers.toString(),
            Theme.of(context).primaryColor,
          ),
          const Gap(AppSpacing.md),
          const Divider(),
          const Gap(AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
              icon: const Icon(LucideIcons.barChart3),
              label: Text(localizations.viewDetailedStatistics),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnualReportScreen()),
                );
              },
              icon: const Icon(LucideIcons.fileDown),
              label: Text(localizations.annualReport),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              },
              icon: const Icon(LucideIcons.trash2),
              label: const Text('Trash'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
        );
      },
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
                color: context.colors.textTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: _showDebugInfo,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.asset(
                      'assets/Peddex app logo ny 1024x1024.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Peddex',
                    style: AppTypography.titleSmall.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  LucideIcons.info,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                localizations.aboutApp,
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          _buildInfoRow(localizations.version, '1.0.0'),
          _buildInfoRow(localizations.developer, 'Exentri Team'),
          const Gap(AppSpacing.md),
          Text(
            localizations.welcomeMessage,
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const Gap(AppSpacing.lg),
          const Divider(height: 1),
          const Gap(AppSpacing.md),
          InkWell(
            onTap: () {
              launchUrl(
                Uri.parse('https://peddex.app/privacy-policy.html'),
                mode: LaunchMode.externalApplication,
              );
            },
            borderRadius: AppRadius.mdAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 18, color: context.colors.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.privacyPolicy,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          localizations.privacyPolicyDescription,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.externalLink, size: 16, color: context.colors.textMuted),
                ],
              ),
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
              color: context.colors.textMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

}
