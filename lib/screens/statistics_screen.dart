import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/puppy_weight_log.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: localizations?.statisticsAndReports ?? 'Statistikk & Rapporter',
        context: context,
        actions: [
          PageInfoHelper.buildInfoButton(
            context,
            title: localizations?.statistics ?? 'Statistikk',
            description: localizations?.statisticsTip ?? 
                'Her finner du detaljert statistikk og rapporter for din oppdrettsvirksomhet.',
            features: [
              PageInfoItem(
                icon: Icons.pets,
                title: localizations?.litterStatistics ?? 'Kullstatistikk',
                description: localizations?.litterStatisticsDesc ??
                    'Gjennomsnittlig kullstørrelse, kjønnsfordeling og mer.',
                color: Colors.blue,
              ),
              PageInfoItem(
                icon: Icons.show_chart,
                title: localizations?.weightDevelopment ?? 'Vektutvikling',
                description: localizations?.weightDevelopmentDesc ??
                    'Sammenlign vektutvikling mellom valper og kull.',
                color: Colors.green,
              ),
              PageInfoItem(
                icon: Icons.attach_money,
                title: localizations?.economyStats ?? 'Økonomi',
                description: localizations?.economyStatsDesc ??
                    'Inntektsrapporter per år og rase.',
                color: Colors.orange,
              ),
              PageInfoItem(
                icon: Icons.science,
                title: localizations?.breedingStatistics ?? 'Avlsstatistikk',
                description: localizations?.breedingStatisticsDesc ??
                    'Se hvilke foreldrekombinasjoner som gir best resultat.',
                color: Colors.purple,
              ),
            ],
            tip: localizations?.statisticsTip ??
                'Statistikken oppdateres automatisk basert på dine registrerte data.',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.pets), text: localizations?.litters ?? 'Kull'),
            Tab(icon: const Icon(Icons.show_chart), text: localizations?.weightDevelopment ?? 'Vekt'),
            Tab(icon: const Icon(Icons.attach_money), text: localizations?.economyStats ?? 'Økonomi'),
            Tab(icon: const Icon(Icons.science), text: localizations?.breedingStatistics ?? 'Avl'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLitterStatisticsTab(),
          _buildWeightStatisticsTab(),
          _buildFinanceStatisticsTab(),
          _buildBreedingStatisticsTab(),
        ],
      ),
    );
  }

  // ============ KULLSTATISTIKK ============
  Widget _buildLitterStatisticsTab() {
    final localizations = AppLocalizations.of(context);
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');
    final litters = litterBox.values.toList();

    if (litters.isEmpty) {
      return _buildEmptyState(
        localizations?.noLittersRegistered ?? 'Ingen kull registrert',
        localizations?.registerFirstLitter ?? 'Legg til kull for å se statistikk',
        Icons.pets_outlined,
      );
    }

    // Beregn statistikk
    final litterStats = _calculateLitterStatistics(litters, puppyBox);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Oversiktskort
          _buildOverviewCard(localizations?.litterOverview ?? 'Kulloversikt', Icons.pets, Colors.blue, [
            _StatItem(localizations?.totalLitters ?? 'Totalt kull', '${litters.length}'),
            _StatItem(
              localizations?.averageLitterSize ?? 'Gjennomsnittlig kullstørrelse',
              litterStats['avgLitterSize']?.toStringAsFixed(1) ?? '0',
            ),
            _StatItem(localizations?.totalPuppies ?? 'Totalt valper', '${litterStats['totalPuppies']}'),
            _StatItem(localizations?.largestLitter ?? 'Største kull', '${litterStats['largestLitter']} ${localizations?.puppies ?? 'valper'}'),
            _StatItem(localizations?.smallestLitter ?? 'Minste kull', '${litterStats['smallestLitter']} ${localizations?.puppies ?? 'valper'}'),
          ]),

          const SizedBox(height: 16),

          // Kjønnsfordeling
          _buildGenderDistributionCard(litterStats),

          const SizedBox(height: 16),

          // Kullstørrelse per rase
          _buildLitterSizeByBreedCard(litters, puppyBox),

          const SizedBox(height: 16),

          // Kull per år graf
          _buildLittersPerYearChart(litters),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateLitterStatistics(
    List<Litter> litters,
    Box<Puppy> puppyBox,
  ) {
    int totalPuppies = 0;
    int totalMales = 0;
    int totalFemales = 0;
    int largestLitter = 0;
    int smallestLitter = 999;

    for (final litter in litters) {
      final puppies = puppyBox.values
          .where((p) => p.litterId == litter.id)
          .toList();
      final count = puppies.length;

      if (count > 0) {
        totalPuppies += count;
        totalMales += puppies.where((p) => p.gender == 'Male').length;
        totalFemales += puppies.where((p) => p.gender == 'Female').length;

        if (count > largestLitter) largestLitter = count;
        if (count < smallestLitter) smallestLitter = count;
      }
    }

    if (smallestLitter == 999) smallestLitter = 0;

    final littersWithPuppies = litters.where((l) {
      return puppyBox.values.any((p) => p.litterId == l.id);
    }).length;

    return {
      'totalPuppies': totalPuppies,
      'totalMales': totalMales,
      'totalFemales': totalFemales,
      'avgLitterSize': littersWithPuppies > 0
          ? totalPuppies / littersWithPuppies
          : 0.0,
      'largestLitter': largestLitter,
      'smallestLitter': smallestLitter,
    };
  }

  Widget _buildGenderDistributionCard(Map<String, dynamic> stats) {
    final localizations = AppLocalizations.of(context);
    final males = stats['totalMales'] as int;
    final females = stats['totalFemales'] as int;
    final total = males + females;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.genderDistribution ?? 'Kjønnsfordeling',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: males.toDouble(),
                      title: '${localizations?.males ?? 'Hanner'}\n$males',
                      color: Colors.blue,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                    PieChartSectionData(
                      value: females.toDouble(),
                      title: '${localizations?.females ?? 'Tisper'}\n$females',
                      color: Colors.pink,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  localizations?.males ?? 'Hanner',
                  Colors.blue,
                  '${(males / total * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(width: 24),
                _buildLegendItem(
                  localizations?.females ?? 'Tisper',
                  Colors.pink,
                  '${(females / total * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($percentage)'),
      ],
    );
  }

  Widget _buildLitterSizeByBreedCard(
    List<Litter> litters,
    Box<Puppy> puppyBox,
  ) {
    final localizations = AppLocalizations.of(context);
    final breedStats = <String, List<int>>{};

    for (final litter in litters) {
      final breed = litter.breed.isNotEmpty ? litter.breed : (localizations?.unknown ?? 'Ukjent');
      final puppyCount = puppyBox.values
          .where((p) => p.litterId == litter.id)
          .length;

      if (puppyCount > 0) {
        breedStats.putIfAbsent(breed, () => []);
        breedStats[breed]!.add(puppyCount);
      }
    }

    if (breedStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedBreeds = breedStats.entries.toList()
      ..sort((a, b) {
        final avgA = a.value.reduce((a, b) => a + b) / a.value.length;
        final avgB = b.value.reduce((a, b) => a + b) / b.value.length;
        return avgB.compareTo(avgA);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.litterSizeByBreed ?? 'Kullstørrelse per rase',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedBreeds.map((entry) {
              final avg =
                  entry.value.reduce((a, b) => a + b) / entry.value.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(entry.key)),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: avg / 12, // Maks 12 valper som referanse
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          minHeight: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${localizations?.average ?? 'Snitt'}: ${avg.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLittersPerYearChart(List<Litter> litters) {
    final localizations = AppLocalizations.of(context);
    final yearCounts = <int, int>{};

    for (final litter in litters) {
      final year = litter.dateOfBirth.year;
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    if (yearCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedYears = yearCounts.keys.toList()..sort();
    final maxCount = yearCounts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.littersPerYear ?? 'Kull per år',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxCount.toDouble() + 1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${sortedYears[groupIndex]}\n${rod.toY.toInt()} ${localizations?.litters ?? 'kull'}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedYears.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedYears[index].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedYears.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: yearCounts[sortedYears[index]]!.toDouble(),
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ VEKTSTATISTIKK ============
  Widget _buildWeightStatisticsTab() {
    final localizations = AppLocalizations.of(context);
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');
    final weightBox = Hive.box<PuppyWeightLog>('weight_logs');

    final litters = litterBox.values.toList();

    if (litters.isEmpty) {
      return _buildEmptyState(
        localizations?.noDataAvailable ?? 'Ingen data tilgjengelig',
        localizations?.registerWeightToSeeStats ?? 'Registrer vekt på valpene for å se statistikk',
        Icons.show_chart,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Velg kull for sammenligning
          _buildWeightComparisonCard(litters, puppyBox, weightBox),

          const SizedBox(height: 16),

          // Gjennomsnittlig vektutvikling
          _buildAverageWeightGrowthCard(puppyBox, weightBox),

          const SizedBox(height: 16),

          // Fødselsvekt statistikk
          _buildBirthWeightStatsCard(puppyBox),
        ],
      ),
    );
  }

  Widget _buildWeightComparisonCard(
    List<Litter> litters,
    Box<Puppy> puppyBox,
    Box<PuppyWeightLog> weightBox,
  ) {
    final localizations = AppLocalizations.of(context);
    // Finn kull med vektdata
    final littersWithWeight = litters.where((litter) {
      final puppies = puppyBox.values.where((p) => p.litterId == litter.id);
      return puppies.any(
        (p) =>
            weightBox.values.any((w) => w.puppyId == p.id) ||
            p.birthWeight != null,
      );
    }).toList();

    if (littersWithWeight.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(localizations?.noWeightDataRegistered ?? 'Ingen vektdata registrert ennå'),
              const SizedBox(height: 4),
              Text(
                localizations?.registerWeightToCompare ?? 'Registrer vekt på valpene for å sammenligne',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations?.weightComparisonBetweenLitters ?? 'Vektsammenligning mellom kull',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...littersWithWeight.take(5).map((litter) {
              final puppies = puppyBox.values
                  .where((p) => p.litterId == litter.id)
                  .toList();
              final avgBirthWeight = _calculateAvgBirthWeight(puppies);
              final latestAvgWeight = _calculateLatestAvgWeight(
                puppies,
                weightBox,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${litter.damName} × ${litter.sireName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${litter.breed} • ${puppies.length} ${localizations?.puppies ?? 'valper'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeightStat(
                            localizations?.birthWeightAverage ?? 'Fødselsvekt (snitt)',
                            avgBirthWeight > 0
                                ? '${avgBirthWeight.toStringAsFixed(0)} g'
                                : '-',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildWeightStat(
                            localizations?.latestWeightAverage ?? 'Siste vekt (snitt)',
                            latestAvgWeight > 0
                                ? '${latestAvgWeight.toStringAsFixed(0)} g'
                                : '-',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateAvgBirthWeight(List<Puppy> puppies) {
    final weights = puppies
        .where((p) => p.birthWeight != null && p.birthWeight! > 0)
        .map((p) => p.birthWeight!)
        .toList();
    if (weights.isEmpty) return 0;
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  double _calculateLatestAvgWeight(
    List<Puppy> puppies,
    Box<PuppyWeightLog> weightBox,
  ) {
    final weights = <double>[];
    for (final puppy in puppies) {
      final logs = weightBox.values.where((w) => w.puppyId == puppy.id).toList()
        ..sort((a, b) => b.logDate.compareTo(a.logDate));
      if (logs.isNotEmpty) {
        weights.add(logs.first.weight);
      }
    }
    if (weights.isEmpty) return 0;
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  Widget _buildAverageWeightGrowthCard(
    Box<Puppy> puppyBox,
    Box<PuppyWeightLog> weightBox,
  ) {
    final localizations = AppLocalizations.of(context);
    // Beregn gjennomsnittlig vektøkning per uke
    final weeklyGrowth = <int, List<double>>{};

    for (final puppy in puppyBox.values) {
      if (puppy.birthWeight == null) continue;

      final logs = weightBox.values.where((w) => w.puppyId == puppy.id).toList()
        ..sort((a, b) => a.logDate.compareTo(b.logDate));

      for (final log in logs) {
        final ageInWeeks =
            log.logDate.difference(puppy.dateOfBirth).inDays ~/ 7;
        if (ageInWeeks >= 0 && ageInWeeks <= 12) {
          weeklyGrowth.putIfAbsent(ageInWeeks, () => []);
          weeklyGrowth[ageInWeeks]!.add(log.weight);
        }
      }
    }

    if (weeklyGrowth.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.averageWeightDevelopment ?? 'Gjennomsnittlig vektutvikling',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.basedOnAllWeightMeasurements ?? 'Basert på alle registrerte vektmålinger',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(localizations?.week ?? 'Uke'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(localizations?.gram ?? 'Gram'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyGrowth.entries.map((e) {
                        final avg =
                            e.value.reduce((a, b) => a + b) / e.value.length;
                        return FlSpot(e.key.toDouble(), avg);
                      }).toList()..sort((a, b) => a.x.compareTo(b.x)),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: ThemeOpacity.low(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthWeightStatsCard(Box<Puppy> puppyBox) {
    final localizations = AppLocalizations.of(context);
    final puppiesWithBirthWeight = puppyBox.values
        .where((p) => p.birthWeight != null && p.birthWeight! > 0)
        .toList();

    if (puppiesWithBirthWeight.isEmpty) {
      return const SizedBox.shrink();
    }

    final weights = puppiesWithBirthWeight.map((p) => p.birthWeight!).toList();
    final avg = weights.reduce((a, b) => a + b) / weights.length;
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);

    final maleWeights = puppiesWithBirthWeight
        .where((p) => p.gender == 'Male')
        .map((p) => p.birthWeight!)
        .toList();
    final femaleWeights = puppiesWithBirthWeight
        .where((p) => p.gender == 'Female')
        .map((p) => p.birthWeight!)
        .toList();

    final maleAvg = maleWeights.isNotEmpty
        ? maleWeights.reduce((a, b) => a + b) / maleWeights.length
        : 0.0;
    final femaleAvg = femaleWeights.isNotEmpty
        ? femaleWeights.reduce((a, b) => a + b) / femaleWeights.length
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations?.birthWeightStatistics ?? 'Fødselsvekt statistikk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    localizations?.average ?? 'Snitt',
                    '${avg.toStringAsFixed(0)} g',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    localizations?.min ?? 'Min',
                    '${min.toStringAsFixed(0)} g',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    localizations?.max ?? 'Maks',
                    '${max.toStringAsFixed(0)} g',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    localizations?.malesAverage ?? 'Hanner (snitt)',
                    maleAvg > 0 ? '${maleAvg.toStringAsFixed(0)} g' : '-',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    localizations?.femalesAverage ?? 'Tisper (snitt)',
                    femaleAvg > 0 ? '${femaleAvg.toStringAsFixed(0)} g' : '-',
                    Colors.pink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============ ØKONOMISTATISTIKK ============
  Widget _buildFinanceStatisticsTab() {
    final localizations = AppLocalizations.of(context);
    final contractBox = Hive.box<PurchaseContract>('purchase_contracts');
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');

    final contracts = contractBox.values.toList();

    if (contracts.isEmpty) {
      return _buildEmptyState(
        localizations?.noSalesDataAvailable ?? 'Ingen salgsdata tilgjengelig',
        localizations?.createContractsToSeeStats ?? 'Opprett salgskontrakter for å se økonomistatistikk',
        Icons.attach_money,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total inntekt oversikt
          _buildRevenueOverviewCard(contracts),

          const SizedBox(height: 16),

          // Inntekt per år
          _buildRevenuePerYearCard(contracts),

          const SizedBox(height: 16),

          // Inntekt per rase
          _buildRevenuePerBreedCard(contracts, puppyBox, litterBox),

          const SizedBox(height: 16),

          // Gjennomsnittspris
          _buildAveragePriceCard(contracts),
        ],
      ),
    );
  }

  Widget _buildRevenueOverviewCard(List<PurchaseContract> contracts) {
    final localizations = AppLocalizations.of(context);
    final totalRevenue = contracts.fold(0.0, (sum, c) => sum + c.price);
    final paidContracts = contracts.where((c) => c.status == 'Completed');
    final paidRevenue = paidContracts.fold(0.0, (sum, c) => sum + c.price);
    final pendingRevenue = totalRevenue - paidRevenue;

    final formatter = NumberFormat.currency(locale: 'nb_NO', symbol: 'kr');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations?.revenueOverview ?? 'Inntektsoversikt',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: ThemeOpacity.low(context)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.totalTurnover ?? 'Total omsetning',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        formatter.format(totalRevenue),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinanceStatBox(
                    localizations?.paid ?? 'Betalt',
                    formatter.format(paidRevenue),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFinanceStatBox(
                    localizations?.outstanding ?? 'Utestående',
                    formatter.format(pendingRevenue),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${contracts.length} ${localizations?.contractsTotal ?? 'kontrakter totalt'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceStatBox(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenuePerYearCard(List<PurchaseContract> contracts) {
    final localizations = AppLocalizations.of(context);
    final yearRevenue = <int, double>{};

    for (final contract in contracts) {
      final year = contract.contractDate.year;
      yearRevenue[year] = (yearRevenue[year] ?? 0) + contract.price;
    }

    if (yearRevenue.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedYears = yearRevenue.keys.toList()..sort();
    final maxRevenue = yearRevenue.values.reduce((a, b) => a > b ? a : b);
    final formatter = NumberFormat.currency(
      locale: 'nb_NO',
      symbol: 'kr',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations?.revenuePerYear ?? 'Inntekt per år',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedYears.map((year) {
              final revenue = yearRevenue[year]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$year',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: revenue / maxRevenue,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          minHeight: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: Text(
                        formatter.format(revenue),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenuePerBreedCard(
    List<PurchaseContract> contracts,
    Box<Puppy> puppyBox,
    Box<Litter> litterBox,
  ) {
    final localizations = AppLocalizations.of(context);
    final breedRevenue = <String, double>{};

    for (final contract in contracts) {
      try {
        final puppy = puppyBox.values.firstWhere(
          (p) => p.id == contract.puppyId,
        );
        final litter = litterBox.values.firstWhere(
          (l) => l.id == puppy.litterId,
        );
        final breed = litter.breed.isNotEmpty ? litter.breed : (localizations?.unknown ?? 'Ukjent');
        breedRevenue[breed] = (breedRevenue[breed] ?? 0) + contract.price;
      } catch (e) {
        // Skip if not found
      }
    }

    if (breedRevenue.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedBreeds = breedRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final formatter = NumberFormat.currency(
      locale: 'nb_NO',
      symbol: 'kr',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.revenuePerBreed ?? 'Inntekt per rase',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedBreeds.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(
                      formatter.format(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAveragePriceCard(List<PurchaseContract> contracts) {
    final localizations = AppLocalizations.of(context);
    final contractsWithPrice = contracts.where((c) => c.price > 0).toList();

    if (contractsWithPrice.isEmpty) {
      return const SizedBox.shrink();
    }

    final prices = contractsWithPrice.map((c) => c.price).toList();
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);

    final formatter = NumberFormat.currency(
      locale: 'nb_NO',
      symbol: 'kr',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.price_check, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.priceStatistics ?? 'Prisstatistikk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    localizations?.averagePrice ?? 'Snittpris',
                    formatter.format(avg),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    localizations?.lowest ?? 'Laveste',
                    formatter.format(min),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    localizations?.highest ?? 'Høyeste',
                    formatter.format(max),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ AVLSSTATISTIKK ============
  Widget _buildBreedingStatisticsTab() {
    final localizations = AppLocalizations.of(context);
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');
    final dogBox = Hive.box<Dog>('dogs');

    final litters = litterBox.values.toList();

    if (litters.isEmpty) {
      return _buildEmptyState(
        localizations?.noBreedingDataAvailable ?? 'Ingen avlsdata tilgjengelig',
        localizations?.registerLittersToSeeBreedingStats ?? 'Registrer kull for å se avlsstatistikk',
        Icons.science,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beste foreldrekombinasjoner
          _buildBestCombinationsCard(litters, puppyBox),

          const SizedBox(height: 16),

          // Avlshunder statistikk
          _buildBreedingDogsStatsCard(litters, puppyBox, dogBox),

          const SizedBox(height: 16),

          // Suksessrate
          _buildSuccessRateCard(litters, puppyBox),
        ],
      ),
    );
  }

  Widget _buildBestCombinationsCard(List<Litter> litters, Box<Puppy> puppyBox) {
    final localizations = AppLocalizations.of(context);
    // Grupper kull etter foreldrekombinasjon
    final combinations = <String, List<_CombinationStats>>{};

    for (final litter in litters) {
      final key = '${litter.damName} × ${litter.sireName}';
      final puppies = puppyBox.values
          .where((p) => p.litterId == litter.id)
          .toList();

      combinations.putIfAbsent(key, () => []);
      combinations[key]!.add(
        _CombinationStats(
          litterSize: puppies.length,
          avgBirthWeight: _calculateAvgBirthWeight(puppies),
          breed: litter.breed,
        ),
      );
    }

    // Beregn gjennomsnitt for hver kombinasjon
    final combinationAverages = combinations.entries.map((e) {
      final stats = e.value;
      final avgLitterSize =
          stats.map((s) => s.litterSize).reduce((a, b) => a + b) / stats.length;
      final avgBirthWeight = stats
          .where((s) => s.avgBirthWeight > 0)
          .map((s) => s.avgBirthWeight)
          .fold(0.0, (a, b) => a + b);
      final birthWeightCount = stats.where((s) => s.avgBirthWeight > 0).length;

      return _CombinationAverage(
        combination: e.key,
        litterCount: stats.length,
        avgLitterSize: avgLitterSize,
        avgBirthWeight: birthWeightCount > 0
            ? avgBirthWeight / birthWeightCount
            : 0,
        breed: stats.first.breed,
      );
    }).toList()..sort((a, b) => b.avgLitterSize.compareTo(a.avgLitterSize));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.bestParentCombinations ?? 'Beste foreldrekombinasjoner',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.sortedByAverageLitterSize ?? 'Sortert etter gjennomsnittlig kullstørrelse',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...combinationAverages.take(5).map((combo) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            combo.combination,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: ThemeOpacity.low(context)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${combo.litterCount} ${localizations?.litters ?? 'kull'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      combo.breed,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat(
                          localizations?.avgLitterSize ?? 'Snitt kullstørrelse',
                          combo.avgLitterSize.toStringAsFixed(1),
                          Icons.pets,
                        ),
                        const SizedBox(width: 16),
                        if (combo.avgBirthWeight > 0)
                          _buildMiniStat(
                            localizations?.avgBirthWeight ?? 'Snitt fødselsvekt',
                            '${combo.avgBirthWeight.toStringAsFixed(0)} g',
                            Icons.scale,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBreedingDogsStatsCard(
    List<Litter> litters,
    Box<Puppy> puppyBox,
    Box<Dog> dogBox,
  ) {
    final localizations = AppLocalizations.of(context);
    // Teller kull per avlshund
    final damStats = <String, int>{};
    final sireStats = <String, int>{};

    for (final litter in litters) {
      damStats[litter.damName] = (damStats[litter.damName] ?? 0) + 1;
      sireStats[litter.sireName] = (sireStats[litter.sireName] ?? 0) + 1;
    }

    final topDams = damStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSires = sireStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.mostUsedBreedingDogs ?? 'Mest brukte avlshunder',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.female, color: Colors.pink, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            localizations?.females ?? 'Tisper',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...topDams
                          .take(3)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${e.value} ${localizations?.litters ?? 'kull'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.male, color: Colors.blue, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            localizations?.males ?? 'Hanner',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...topSires
                          .take(3)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${e.value} ${localizations?.litters ?? 'kull'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateCard(List<Litter> litters, Box<Puppy> puppyBox) {
    final localizations = AppLocalizations.of(context);
    int totalPuppies = 0;
    int soldPuppies = 0;
    int reservedPuppies = 0;

    for (final litter in litters) {
      final puppies = puppyBox.values
          .where((p) => p.litterId == litter.id)
          .toList();
      totalPuppies += puppies.length;
      soldPuppies += puppies.where((p) => p.status == 'Sold').length;
      reservedPuppies += puppies.where((p) => p.status == 'Reserved').length;
    }

    if (totalPuppies == 0) {
      return const SizedBox.shrink();
    }

    final soldPercentage = (soldPuppies / totalPuppies * 100);
    final reservedPercentage = (reservedPuppies / totalPuppies * 100);
    final placedPercentage = soldPercentage + reservedPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  localizations?.placementRate ?? 'Plasseringsrate',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: placedPercentage / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          placedPercentage > 80
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${placedPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'plassert',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlacementStat(
                  localizations?.sold ?? 'Solgt',
                  soldPuppies,
                  soldPercentage,
                  Colors.green,
                ),
                _buildPlacementStat(
                  localizations?.reserved ?? 'Reservert',
                  reservedPuppies,
                  reservedPercentage,
                  Colors.orange,
                ),
                _buildPlacementStat(
                  localizations?.available ?? 'Ledig',
                  totalPuppies - soldPuppies - reservedPuppies,
                  100 - placedPercentage,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementStat(
    String label,
    int count,
    double percentage,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

  // ============ HJELPEMETODER ============
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    IconData icon,
    Color color,
    List<_StatItem> stats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stat.label),
                    Text(
                      stat.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

class _CombinationStats {
  final int litterSize;
  final double avgBirthWeight;
  final String breed;

  _CombinationStats({
    required this.litterSize,
    required this.avgBirthWeight,
    required this.breed,
  });
}

class _CombinationAverage {
  final String combination;
  final int litterCount;
  final double avgLitterSize;
  final double avgBirthWeight;
  final String breed;

  _CombinationAverage({
    required this.combination,
    required this.litterCount,
    required this.avgLitterSize,
    required this.avgBirthWeight,
    required this.breed,
  });
}
