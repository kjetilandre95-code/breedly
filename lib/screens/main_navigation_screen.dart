import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/screens/litters_list_screen.dart';
import 'package:breedly/screens/dogs_screen.dart';
import 'package:breedly/screens/buyers_screen.dart';
import 'package:breedly/screens/finance_screen.dart';
import 'package:breedly/screens/settings_screen.dart';
import 'package:breedly/screens/kennel_management_screen.dart';
import 'package:breedly/screens/add_dog_screen.dart';
import 'package:breedly/screens/add_litter_screen.dart';
import 'package:breedly/screens/statistics_screen.dart';
import 'package:breedly/screens/dog_show_results_screen.dart';
import 'package:breedly/screens/global_search_screen.dart';
import 'package:breedly/screens/export_screen.dart';
import 'package:breedly/screens/calendar_screen.dart';
import 'package:breedly/screens/waitlist_screen.dart';
import 'package:breedly/screens/all_contracts_screen.dart';
import 'package:breedly/screens/annual_report_screen.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:breedly/providers/theme_provider.dart';
import 'package:breedly/providers/kennel_provider.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/sync_helper.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/modern_widgets.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/puppy.dart';

import 'package:breedly/models/progesterone_measurement.dart';

class MainNavigationScreen extends StatefulWidget {
  final LanguageProvider languageProvider;
  final ThemeProvider themeProvider;
  final KennelProvider kennelProvider;
  final OfflineModeManager offlineModeManager;

  const MainNavigationScreen({
    super.key,
    required this.languageProvider,
    required this.themeProvider,
    required this.kennelProvider,
    required this.offlineModeManager,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;
  StreamSubscription<bool>? _onlineStatusSubscription;
  final PageController _pageController = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    _onlineStatusSubscription = widget.offlineModeManager.onlineStatusStream
        .listen(_onOnlineStatusChanged);
    // Listen to kennel provider changes
    widget.kennelProvider.addListener(_onKennelChanged);
    // Perform initial data sync from Firebase on app start
    _performInitialSync();
  }

  Future<void> _performInitialSync() async {
    try {
      await SyncHelper.performSilentSync();
      if (mounted) setState(() {});
    } catch (e) {
      // Sync failure is non-fatal, data will sync on next connectivity change
    }
  }

  @override
  void dispose() {
    _onlineStatusSubscription?.cancel();
    _pageController.dispose();
    widget.kennelProvider.removeListener(_onKennelChanged);
    super.dispose();
  }

  void _onKennelChanged() {
    if (mounted) setState(() {});
  }

  void _onOnlineStatusChanged(bool isOnline) {
    if (isOnline) SyncHelper.performSilentSync();
  }

  Future<void> _syncDataManually() async {
    await SyncHelper.performSyncWithFeedback(context);
  }

  int _getBoxLength<T>(String boxName) {
    try {
      final box = Hive.box<T>(boxName);
      // For dogs, exclude pedigree-only entries from visible count
      if (T == Dog) {
        return (box as Box<Dog>).values.where((d) => !d.isPedigreeOnly).length;
      }
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  String? _getKennelName() {
    return widget.kennelProvider.activeKennel?.name ?? 
           (widget.kennelProvider.kennels.isNotEmpty 
               ? widget.kennelProvider.kennels.first.name 
               : null);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe for better UX
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          const DogsScreen(showAppBar: true),
          const LittersListScreen(showAppBar: true),
          _buildDashboard(),
          const FinanceScreen(showAppBar: true),
          const BuyersScreen(showAppBar: true),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    // Hent system padding for å håndtere Samsung og andre enheter med software-navigasjon
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm + bottomPadding, // Legg til ekstra padding for navigasjonsknapper
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              FontAwesomeIcons.dog,
              FontAwesomeIcons.dog,
              AppLocalizations.of(context)?.dogs ?? 'Hunder',
            ),
            _buildNavItem(
              1,
              FontAwesomeIcons.paw,
              FontAwesomeIcons.paw,
              AppLocalizations.of(context)?.litters ?? 'Kull',
            ),
            _buildNavItem(
              2,
              Icons.dashboard_rounded,
              Icons.dashboard_outlined,
              AppLocalizations.of(context)?.overview ?? 'Hjem',
            ),
            _buildNavItem(
              3,
              FontAwesomeIcons.coins,
              FontAwesomeIcons.coins,
              AppLocalizations.of(context)?.finance ?? 'Økonomi',
            ),
            _buildNavItem(
              4,
              Icons.people_rounded,
              Icons.people_outlined,
              AppLocalizations.of(context)?.buyers ?? 'Kjøpere',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppSpacing.lg : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: ThemeOpacity.low(context))
              : Colors.transparent,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryColor : AppColors.neutral500,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final localizations = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;

    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            title: Text(
              _getKennelName() ?? (localizations?.appTitle ?? 'Breedly'),
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor.withValues(alpha: 0.12), AppColors.surface],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _syncDataManually,
              icon: const Icon(Icons.sync_rounded),
              tooltip: localizations?.sync ?? 'Sync',
              color: AppColors.neutral600,
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    languageProvider: widget.languageProvider,
                    themeProvider: widget.themeProvider,
                  ),
                ),
              ),
              icon: const Icon(Icons.settings_rounded),
              tooltip: localizations?.settings ?? 'Settings',
              color: AppColors.neutral600,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Card
              _buildWelcomeCard(localizations, primaryColor),

              const SizedBox(height: AppSpacing.xxl),

              // Search Section
              _buildSearchBar(localizations),

              const SizedBox(height: AppSpacing.xxl),

              // Statistics Section
              SectionHeader(
                title: localizations?.statistics ?? 'Statistikk',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStatisticsGrid(),

              const SizedBox(height: AppSpacing.xxl),

              // Upcoming Events Calendar Section
              SectionHeader(
                title: localizations?.upcomingEvents ?? 'Kommende hendelser',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildUpcomingEventsSection(),

              const SizedBox(height: AppSpacing.xxl),

              // Quick Actions Section
              SectionHeader(
                title: localizations?.quickActions ?? 'Hurtighandlinger',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildQuickActions(localizations, primaryColor),

              // Bottom padding for nav bar
              const SizedBox(height: AppSpacing.huge),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations? localizations) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.neutral300),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.neutral500,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                localizations?.searchDogsLittersBuyers ?? 'Søk etter hunder, kull, kjøpere...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.neutral400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    AppLocalizations? localizations,
    Color primaryColor,
  ) {
    // Always show "Welcome to Breedly" in welcome card
    final welcomeText = localizations?.welcomeToBreedly ?? 'Velkommen til Breedly!';
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.colored(primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  welcomeText,
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localizations?.welcomeMessage ?? 'Din digitale kennelassistent',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.lgAll,
            ),
            child: const FaIcon(
              FontAwesomeIcons.dog,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactStatItem(
                  title: AppLocalizations.of(context)?.dogs ?? 'Hunder',
                  value: _getBoxLength<Dog>('dogs').toString(),
                  icon: FontAwesomeIcons.dog,
                  color: Theme.of(context).primaryColor,
                  onTap: () => _onItemTapped(0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildCompactStatItem(
                  title: AppLocalizations.of(context)?.activeLitters ?? 'Aktive kull',
                  value: _getActiveLittersCount().toString(),
                  icon: FontAwesomeIcons.paw,
                  color: Theme.of(context).primaryColor,
                  onTap: () => _onItemTapped(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatItem(
                  title: AppLocalizations.of(context)?.buyers ?? 'Kjøpere',
                  value: _getBoxLength<Buyer>('buyers').toString(),
                  icon: Icons.people_rounded,
                  color: Theme.of(context).primaryColor,
                  onTap: () => _onItemTapped(4),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildCompactStatItem(
                  title: AppLocalizations.of(context)?.puppies ?? 'Valper',
                  value: _getBoxLength<Puppy>('puppies').toString(),
                  icon: FontAwesomeIcons.bone,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    // Check if it's a FontAwesome icon (they have codepoints >= 0xf000)
    final isFontAwesome = icon.fontFamily == 'FontAwesomeSolid' || 
                          icon.fontFamily == 'FontAwesomeRegular' ||
                          icon.fontFamily == 'FontAwesomeBrands';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: ThemeOpacity.medium(context)),
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: ThemeOpacity.medium(context)),
                borderRadius: AppRadius.smAll,
              ),
              child: Center(
                child: isFontAwesome 
                    ? FaIcon(icon, color: color, size: 16)
                    : Icon(icon, color: color, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getActiveLittersCount() {
    try {
      return Hive.box<Litter>(
        'litters',
      ).values.where((l) => l.getAgeInWeeks() < 10).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all upcoming events sorted by date
  List<Map<String, dynamic>> _getUpcomingEvents() {
    final events = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 90));

    try {
      // 0. Check for active progesterone-based mating windows (HIGH PRIORITY)
      final progesteroneBox = Hive.box<ProgesteroneMeasurement>('progesterone_measurements');
      final dogBox = Hive.box<Dog>('dogs');
      
      for (final dog in dogBox.values) {
        if (dog.isPedigreeOnly) continue;
        if (dog.gender == 'Female') {
          // Get recent progesterone measurements for this dog
          final recentMeasurements = progesteroneBox.values
              .where((m) => m.dogId == dog.id && 
                  m.dateMeasured.isAfter(now.subtract(const Duration(days: 14))))
              .toList()
            ..sort((a, b) => b.dateMeasured.compareTo(a.dateMeasured));
          
          if (recentMeasurements.isNotEmpty) {
            final latest = recentMeasurements.first;
            final status = latest.getStatus();
            
            // If progesterone indicates active or upcoming mating window
            if (status != ProgesteroneStatus.basal && status != ProgesteroneStatus.tooLate) {
              Color statusColor;
              
              switch (status) {
                case ProgesteroneStatus.lhPeak:
                  statusColor = const Color(0xFFFF9800);
                  break;
                case ProgesteroneStatus.ovulation:
                  statusColor = const Color(0xFF8BC34A);
                  break;
                case ProgesteroneStatus.fertileWindow:
                  statusColor = const Color(0xFF4CAF50);
                  break;
                case ProgesteroneStatus.lateWindow:
                  statusColor = const Color(0xFF2196F3);
                  break;
                default:
                  statusColor = Colors.grey;
              }
              
              events.add({
                'type': 'progesterone',
                'date': now, // Show at top since it's urgent
                'title': 'Parringsvindu: ${dog.name}',
                'subtitle': status.description,
                'color': statusColor,
                'icon': FontAwesomeIcons.heartPulse,
                'progesteroneValue': latest.valueInNgMl,
                'progesteroneDisplay': latest.displayValue,
                'statusLabel': status.label,
                'recommendation': status.recommendation,
                'isUrgent': status.isUrgent,
                'canMate': status.canMate,
              });
            }
          }
        }
      }

      // 1. Upcoming heat cycles from female dogs (only if no active progesterone)
      for (final dog in dogBox.values) {
        if (dog.gender == 'Female') {
          // Skip if already has active progesterone event
          final hasProgesteroneEvent = events.any((e) => 
              e['type'] == 'progesterone' && e['title'].toString().contains(dog.name));
          
          if (!hasProgesteroneEvent) {
            final nextHeat = dog.getNextEstimatedHeatCycle();
            if (nextHeat != null && nextHeat.isAfter(now) && nextHeat.isBefore(futureLimit)) {
              events.add({
                'type': 'heat',
                'date': nextHeat,
                'title': 'Løpetid: ${dog.name}',
                'subtitle': 'Estimert løpetid starter',
                'color': const Color(0xFFE91E63),
                'icon': FontAwesomeIcons.heart,
                'dogName': dog.name,
                'matingWindowStart': nextHeat.add(const Duration(days: 11)),
                'matingWindowEnd': nextHeat.add(const Duration(days: 14)),
              });
            }
          }
        }
      }

      // 2. Expected birth dates (pregnancies)
      final litterBox = Hive.box<Litter>('litters');
      for (final litter in litterBox.values) {
        if (litter.estimatedDueDate != null && 
            litter.estimatedDueDate!.isAfter(now) && 
            litter.estimatedDueDate!.isBefore(futureLimit)) {
          final daysUntil = litter.estimatedDueDate!.difference(now).inDays;
          events.add({
            'type': 'birth',
            'date': litter.estimatedDueDate!,
            'title': 'Termin: ${litter.damName}',
            'subtitle': '$daysUntil dager til estimert fødsel',
            'color': const Color(0xFF4CAF50),
            'icon': FontAwesomeIcons.dog,
          });
        }
      }

      // 3. Puppy deliveries (puppies marked as sold but not delivered)
      final puppyBox = Hive.box<Puppy>('puppies');
      for (final puppy in puppyBox.values) {
        // Check for puppies that are sold/reserved and old enough for delivery (8+ weeks)
        if ((puppy.status == 'Sold' || puppy.status == 'Reserved') && 
            puppy.status != 'Delivered' &&
            puppy.deliveredDate == null) {
          final weeksOld = puppy.getAgeInWeeks();
          if (weeksOld >= 6 && weeksOld <= 12) {
            // Estimate delivery around 8 weeks
            final estimatedDelivery = puppy.dateOfBirth.add(const Duration(days: 56));
            if (estimatedDelivery.isAfter(now.subtract(const Duration(days: 7)))) {
              events.add({
                'type': 'delivery',
                'date': estimatedDelivery,
                'title': 'Levering: ${puppy.name}',
                'subtitle': puppy.buyerName != null ? 'Til ${puppy.buyerName}' : 'Klar for levering',
                'color': const Color(0xFF2196F3),
                'icon': FontAwesomeIcons.handHoldingHeart,
              });
            }
          }
        }
      }

    } catch (e) {
      // Return empty list on error
    }

    // Sort by date
    events.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Return only first 5 events
    return events.take(5).toList();
  }

  Widget _buildUpcomingEventsSection() {
    final events = _getUpcomingEvents();
    
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(color: AppColors.neutral200),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)?.noUpcomingEvents ?? 'No upcoming events',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context)?.registerHeatOrMating ?? 'Register heat cycle or mating to see events here',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: events.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == events.length - 1;
          
          return _buildEventItem(event, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event, bool isLast) {
    final date = event['date'] as DateTime;
    final daysUntil = date.difference(DateTime.now()).inDays;
    final color = event['color'] as Color;
    final icon = event['icon'] as IconData;
    final type = event['type'] as String;
    
    final l10n = AppLocalizations.of(context);
    String timeText;
    if (daysUntil == 0) {
      timeText = l10n?.today ?? 'Today';
    } else if (daysUntil == 1) {
      timeText = l10n?.tomorrow ?? 'Tomorrow';
    } else if (daysUntil < 0) {
      timeText = l10n?.daysAgo(-daysUntil) ?? '${-daysUntil} days ago';
    } else if (daysUntil < 7) {
      timeText = l10n?.daysRemaining(daysUntil) ?? '$daysUntil days';
    } else {
      timeText = l10n?.weeksRemaining((daysUntil / 7).floor()) ?? '${(daysUntil / 7).floor()} weeks';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ThemeOpacity.low(context)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(date),
                      style: AppTypography.titleLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'nb_NO').format(date).toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Event icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ThemeOpacity.medium(context)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Center(
                  child: FaIcon(icon, color: color, size: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event['title'] as String,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.neutral900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Show urgent indicator for progesterone events
                        if (type == 'progesterone' && event['isUrgent'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.urgent ?? 'URGENT',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['subtitle'] as String,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    // Show progesterone info for progesterone events
                    if (type == 'progesterone') ...[
                      const SizedBox(height: 4),
                      // Show progesterone value and status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.science, size: 10, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  event['progesteroneDisplay'] as String? ?? 
                                    '${(event['progesteroneValue'] as double).toStringAsFixed(1)} ng/mL',
                                  style: AppTypography.caption.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              event['statusLabel'] as String? ?? '',
                              style: AppTypography.caption.copyWith(
                                color: color,
                                fontWeight: FontWeight.w500,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Show recommendation
                      if (event['recommendation'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: event['canMate'] == true 
                                ? color.withValues(alpha: 0.15)
                                : AppColors.neutral100,
                            borderRadius: AppRadius.xsAll,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event['canMate'] == true ? Icons.check_circle : Icons.info_outline,
                                size: 10,
                                color: event['canMate'] == true ? color : AppColors.neutral600,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  event['recommendation'] as String,
                                  style: AppTypography.caption.copyWith(
                                    color: event['canMate'] == true ? color : AppColors.neutral700,
                                    fontWeight: event['isUrgent'] == true ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    // Show mating window for heat events
                    if (type == 'heat') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: AppRadius.xsAll,
                        ),
                        child: Text(
                          'Parringsvindu: ${DateFormat('dd.MM').format(event['matingWindowStart'])} - ${DateFormat('dd.MM').format(event['matingWindowEnd'])}',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFFFF9800),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Time indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: daysUntil <= 7 
                      ? color.withValues(alpha: 0.1)
                      : AppColors.neutral100,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  type == 'progesterone' ? 'NÅ' : timeText,
                  style: AppTypography.caption.copyWith(
                    color: daysUntil <= 7 || type == 'progesterone' ? color : AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.neutral200,
          ),
      ],
    );
  }

  Widget _buildQuickActions(
    AppLocalizations? localizations,
    Color primaryColor,
  ) {
    final themeColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        _buildQuickActionBar(
          title: localizations?.newDog ?? 'Ny hund',
          icon: FontAwesomeIcons.dog,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDogScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.newLitter ?? 'Nytt kull',
          icon: FontAwesomeIcons.paw,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLitterScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.kennel ?? 'Kennel',
          icon: Icons.home_work_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KennelManagementScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: 'Kontrakter',
          icon: Icons.description_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllContractsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.statistics ?? 'Statistics',
          icon: Icons.bar_chart_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.showResults ?? 'Utstillingsresultater',
          icon: Icons.emoji_events_rounded,
          color: themeColor,
          onTap: () => _showDogPickerForShowResults(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: 'Eksporter',
          icon: Icons.file_download_outlined,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.calendar ?? 'Kalender',
          icon: Icons.calendar_month_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.waitlist ?? 'Venteliste',
          icon: Icons.list_alt_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaitlistScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickActionBar(
          title: localizations?.annualReport ?? 'Årsrapport',
          icon: Icons.summarize_rounded,
          color: themeColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnnualReportScreen()),
          ),
        ),
      ],
    );
  }

  void _showDogPickerForShowResults() {
    final dogs = Hive.box<Dog>('dogs').values.where((d) => !d.isPedigreeOnly).toList();
    final themeColor = Theme.of(context).primaryColor;
    
    if (dogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.noDogsRegistered ?? 'No dogs registered'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: themeColor),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.selectDog ?? 'Select dog',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dogs.length,
                itemBuilder: (context, index) {
                  final dog = dogs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: dog.gender == 'Male'
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.pink.withValues(alpha: 0.15),
                      child: Icon(
                        dog.gender == 'Male' ? Icons.male : Icons.female,
                        color: dog.gender == 'Male' ? Colors.blue : Colors.pink,
                      ),
                    ),
                    title: Text(
                      dog.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${dog.breed} \u2022 ${dog.getAgeInYears()} år'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DogShowResultsScreen(dog: dog),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBar({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isFontAwesome = icon.fontFamily == 'FontAwesomeSolid' || 
                          icon.fontFamily == 'FontAwesomeRegular' ||
                          icon.fontFamily == 'FontAwesomeBrands';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Center(
                  child: isFontAwesome
                      ? FaIcon(icon, color: color, size: 18)
                      : Icon(icon, color: color, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.neutral800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
