import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/screens/dog_detail_screen.dart';
import 'package:breedly/screens/add_dog_screen.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/modern_widgets.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class DogsScreen extends StatefulWidget {
  final bool showAppBar;

  const DogsScreen({super.key, this.showAppBar = true});

  @override
  State<DogsScreen> createState() => _DogsScreenState();
}

class _DogsScreenState extends State<DogsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatAge(Dog dog) {
    final years = dog.getAgeInYears();
    final months = dog.getAgeInMonths() % 12;

    if (years == 0) {
      return months == 1 ? '1 måned' : '$months måneder';
    } else if (months == 0) {
      return years == 1 ? '1 år' : '$years år';
    } else {
      return '$years år, $months mnd';
    }
  }

  List<Dog> _filterDogs(List<Dog> dogs, String filter) {
    // Filter out pedigree-only dogs
    var filtered = dogs.where((d) => !d.isPedigreeOnly).toList();

    // Filter by gender
    if (filter == 'Female') {
      filtered = filtered.where((d) => d.gender == 'Female').toList();
    } else if (filter == 'Male') {
      filtered = filtered.where((d) => d.gender == 'Male').toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((dog) {
        return dog.name.toLowerCase().contains(_searchQuery) ||
            dog.breed.toLowerCase().contains(_searchQuery) ||
            dog.color.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort alphabetically
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  List<int> _getDogCounts(List<Dog> allDogs) {
    final visibleDogs = allDogs.where((d) => !d.isPedigreeOnly).toList();
    return [
      visibleDogs.length,                                           // Alle
      visibleDogs.where((d) => d.gender == 'Female').length,       // Tisper
      visibleDogs.where((d) => d.gender == 'Male').length,         // Hanner
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: widget.showAppBar ? _buildAppBar(primaryColor, localizations) : null,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Dog>('dogs').listenable(),
        builder: (context, Box<Dog> dogBox, _) {
          final allDogs = dogBox.values.toList();
          final dogCounts = _getDogCounts(allDogs);
          
          return Column(
            children: [
              if (!widget.showAppBar) _buildInlineHeader(primaryColor, localizations),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: ModernSearchBar(
                  controller: _searchController,
                  hintText: localizations?.searchDog ?? 'Søk etter hund...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),

              // Tab bar with counts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ModernTabBar(
                  controller: _tabController,
                  tabs: [
                    localizations?.all ?? 'Alle',
                    localizations?.females ?? 'Tisper',
                    localizations?.males ?? 'Hanner',
                  ],
                  icons: const [
                    FontAwesomeIcons.dog,
                    Icons.female_rounded,
                    Icons.male_rounded,
                  ],
                  badgeCounts: dogCounts,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDogsList('All', primaryColor, localizations),
                    _buildDogsList('Female', primaryColor, localizations),
                    _buildDogsList('Male', primaryColor, localizations),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: Hive.box<Dog>('dogs').listenable(),
        builder: (context, Box<Dog> box, _) {
          if (box.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDogScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(localizations?.newDog ?? 'Ny hund'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, AppLocalizations? localizations) {
    return AppBar(
      title: Text(
        localizations?.dogs ?? 'Mine hunder',
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
          title: PageInfoContent.dogsScreen.title,
          description: PageInfoContent.dogsScreen.description,
          features: PageInfoContent.dogsScreen.features,
          tip: PageInfoContent.dogsScreen.tip,
        ),
      ],
    );
  }

  Widget _buildInlineHeader(Color primaryColor, AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Center(
        child: Text(
          localizations?.myDogs ?? 'Mine hunder',
          style: AppTypography.headlineLarge.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDogsList(String filter, Color primaryColor, AppLocalizations? localizations) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Dog>('dogs').listenable(),
      builder: (context, Box<Dog> box, _) {
        final filteredDogs = _filterDogs(box.values.toList(), filter);

        if (filteredDogs.isEmpty) {
          return _buildEmptyState(filter, primaryColor, localizations);
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
            itemCount: filteredDogs.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final dog = filteredDogs[index];
              return _buildDogCard(dog);
            },
          ),
        );
      },
    );
  }

  Widget _buildDogCard(Dog dog) {
    final nextHeat = dog.gender == 'Female'
        ? dog.getNextEstimatedHeatCycle()
        : null;

    List<Widget>? badges;
    
    // Add deceased badge if dog has death date
    if (dog.deathDate != null) {
      badges = [
        StatusBadge(
          text: 'Avdød',
          color: context.colors.neutral500,
          icon: Icons.pets,
        ),
      ];
    } else if (nextHeat != null) {
      final daysUntilHeat = nextHeat.difference(DateTime.now()).inDays;
      if (daysUntilHeat <= 30 && daysUntilHeat > 0) {
        badges = [
          StatusBadge(
            text: 'Løpetid om $daysUntilHeat d',
            color: Theme.of(context).primaryColor,
            icon: Icons.warning_rounded,
          ),
        ];
      }
    }

    return DogCard(
      name: dog.name,
      breed: dog.breed,
      gender: dog.gender,
      age: _formatAge(dog),
      badges: badges,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DogDetailScreen(dog: dog)),
      ),
    );
  }

  Widget _buildEmptyState(String filter, Color primaryColor, AppLocalizations? localizations) {
    final color = filter == 'Male'
        ? AppColors.male
        : filter == 'Female'
        ? AppColors.female
        : context.colors.neutral400;

    String title;
    String subtitle;

    if (_searchQuery.isNotEmpty) {
      title = localizations?.noResults ?? 'Ingen treff';
      subtitle = localizations?.tryDifferentSearch ?? 'Prøv et annet søkeord';
    } else {
      switch (filter) {
        case 'Female':
          title = localizations?.noFemalesRegistered ?? 'Ingen tisper registrert';
          subtitle = localizations?.addFirstFemale ?? 'Legg til din første tispe';
          break;
        case 'Male':
          title = localizations?.noMalesRegistered ?? 'Ingen hannhunder registrert';
          subtitle = localizations?.addFirstMale ?? 'Legg til din første hannhund';
          break;
        default:
          title = localizations?.noDogsRegistered ?? 'Ingen hunder registrert';
          subtitle = localizations?.getStartedAddDog ?? 'Kom i gang ved å legge til din første hund';
      }
    }

    return EmptyState(
      icon: FontAwesomeIcons.dog,
      title: title,
      subtitle: subtitle,
      iconColor: color,
      actionText: _searchQuery.isEmpty ? (localizations?.addDog ?? 'Legg til hund') : null,
      onAction: _searchQuery.isEmpty
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDogScreen()),
            )
          : null,
    );
  }
}
