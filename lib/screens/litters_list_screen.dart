import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/screens/add_litter_screen.dart';
import 'package:breedly/screens/litter_detail_screen.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/modern_widgets.dart';
import 'package:breedly/utils/page_info_helper.dart';

class LittersListScreen extends StatefulWidget {
  final bool showAppBar;

  const LittersListScreen({super.key, this.showAppBar = true});

  @override
  State<LittersListScreen> createState() => _LittersListScreenState();
}

class _LittersListScreenState extends State<LittersListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'newest';
  
  // Filter keys (used internally)
  static const List<String> _filterKeys = ['all', 'planned', 'active', 'weaning', 'older'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  List<String> _getLocalizedTabs(AppLocalizations? localizations) {
    return [
      localizations?.all ?? 'Alle',
      'Planlagt',
      localizations?.active ?? 'Diende',
      localizations?.weaning ?? 'Avvenning',
      localizations?.older ?? 'Arkiv',
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Litter> _filterLitters(List<Litter> litters, String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'planned':
        return litters.where((l) => l.dateOfBirth.isAfter(now)).toList();
      case 'active':
        return litters.where((l) => !l.dateOfBirth.isAfter(now) && l.getAgeInWeeks() < 8).toList();
      case 'weaning':
        return litters.where((l) {
          if (l.dateOfBirth.isAfter(now)) return false;
          final weeks = l.getAgeInWeeks();
          return weeks >= 8 && weeks < 12;
        }).toList();
      case 'older':
        return litters.where((l) => !l.dateOfBirth.isAfter(now) && l.getAgeInWeeks() >= 12).toList();
      default:
        return litters;
    }
  }

  List<Litter> _sortLitters(List<Litter> litters) {
    switch (_sortBy) {
      case 'oldest':
        litters.sort((a, b) => a.dateOfBirth.compareTo(b.dateOfBirth));
        break;
      case 'puppies':
        litters.sort((a, b) => b.numberOfPuppies.compareTo(a.numberOfPuppies));
        break;
      default:
        litters.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
    }
    return litters;
  }

  int _getAvailablePuppiesCount(String litterId) {
    try {
      final puppyBox = Hive.box<Puppy>('puppies');
      return puppyBox.values
          .where((p) => p.litterId == litterId && p.status == 'available')
          .length;
    } catch (e) {
      return 0;
    }
  }

  List<int> _getLitterCounts(List<Litter> allLitters) {
    final now = DateTime.now();
    final bornLitters = allLitters.where((l) => !l.dateOfBirth.isAfter(now)).toList();
    return [
      allLitters.length,                                                    // Alle
      allLitters.where((l) => l.dateOfBirth.isAfter(now)).length,          // Planlagt
      bornLitters.where((l) => l.getAgeInWeeks() < 8).length,              // Diende
      bornLitters.where((l) {
        final weeks = l.getAgeInWeeks();
        return weeks >= 8 && weeks < 12;
      }).length,                                                            // Avvenning
      bornLitters.where((l) => l.getAgeInWeeks() >= 12).length,            // Arkiv
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: widget.showAppBar ? _buildAppBar(primaryColor) : null,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Litter>('litters').listenable(),
        builder: (context, Box<Litter> litterBox, _) {
          final allLitters = litterBox.values.toList();
          final litterCounts = _getLitterCounts(allLitters);
          
          return Column(
            children: [
              if (!widget.showAppBar)
                _buildInlineHeader(localizations, primaryColor),

              // Filter tabs with counts
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ModernTabBar(
                  controller: _tabController,
                  tabs: _getLocalizedTabs(localizations),
                  badgeCounts: litterCounts,
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLittersList(_filterKeys[0], primaryColor, localizations),
                    _buildLittersList(_filterKeys[1], primaryColor, localizations),
                    _buildLittersList(_filterKeys[2], primaryColor, localizations),
                    _buildLittersList(_filterKeys[3], primaryColor, localizations),
                    _buildLittersList(_filterKeys[4], primaryColor, localizations),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: Hive.box<Litter>('litters').listenable(),
        builder: (context, Box<Litter> box, _) {
          if (box.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddLitterScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(localizations.newLitter),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      title: Text(
        'Kull',
        style: AppTypography.headlineLarge.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: context.colors.textPrimary,
      actions: [
        PageInfoHelper.buildInfoButton(
          context,
          title: PageInfoContent.littersScreen.title,
          description: PageInfoContent.littersScreen.description,
          features: PageInfoContent.littersScreen.features,
          tip: PageInfoContent.littersScreen.tip,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.sort_rounded, color: context.colors.textMuted),
          tooltip: 'Sorter',
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          itemBuilder: (context) => [
            _buildSortMenuItem(
              'newest',
              'Nyeste først',
              Icons.arrow_downward_rounded,
            ),
            _buildSortMenuItem(
              'oldest',
              'Eldste først',
              Icons.arrow_upward_rounded,
            ),
            _buildSortMenuItem('puppies', 'Flest valper', Icons.pets_rounded),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String text,
    IconData icon,
  ) {
    final isSelected = _sortBy == value;
    final primaryColor = Theme.of(context).primaryColor;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? primaryColor : context.colors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? primaryColor : context.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineHeader(
    AppLocalizations localizations,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                localizations.litters,
                style: AppTypography.headlineLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_rounded, color: context.colors.textMuted),
            tooltip: 'Sorter',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            itemBuilder: (context) => [
              _buildSortMenuItem(
                'newest',
                'Nyeste først',
                Icons.arrow_downward_rounded,
              ),
              _buildSortMenuItem(
                'oldest',
                'Eldste først',
                Icons.arrow_upward_rounded,
              ),
              _buildSortMenuItem('puppies', 'Flest valper', Icons.pets_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLittersList(
    String filter,
    Color primaryColor,
    AppLocalizations localizations,
  ) {
    return ValueListenableBuilder<Box<Litter>>(
      valueListenable: Hive.box<Litter>('litters').listenable(),
      builder: (context, Box<Litter> box, _) {
        if (box.isEmpty) {
          return _buildEmptyState(localizations, primaryColor);
        }

        var litters = box.values.toList();
        litters = _filterLitters(litters, filter);
        litters = _sortLitters(litters);

        if (litters.isEmpty) {
          return _buildFilterEmptyState(filter, localizations);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.huge + 60, // Extra space for FAB
            ),
            itemCount: litters.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final litter = litters[index];
              return LitterCard(
                damName: litter.damName,
                sireName: litter.sireName,
                breed: litter.breed,
                birthDate: litter.dateOfBirth,
                puppyCount: litter.numberOfPuppies,
                availableCount: _getAvailablePuppiesCount(litter.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LitterDetailScreen(litter: litter),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, Color primaryColor) {
    return EmptyState(
      icon: FontAwesomeIcons.paw,
      title: localizations.noLittersRegistered,
      subtitle: localizations.registerFirstLitter,
      actionText: localizations.addLitter,
      iconColor: primaryColor,
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddLitterScreen()),
      ),
    );
  }

  Widget _buildFilterEmptyState(String filter, AppLocalizations localizations) {
    String title;
    switch (filter) {
      case 'active':
        title = localizations.noActiveLitters;
        break;
      case 'weaning':
        title = localizations.noWeaningLitters;
        break;
      case 'older':
        title = localizations.noOlderLitters;
        break;
      default:
        title = localizations.noLittersInCategory;
    }

    return EmptyState(
      icon: Icons.filter_list_off_rounded,
      title: title,
      subtitle: localizations.tryAnotherCategory,
      iconColor: context.colors.textDisabled,
    );
  }
}
