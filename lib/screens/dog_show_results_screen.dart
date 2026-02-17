import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/show_result.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/widgets/show_result_card.dart';

class DogShowResultsScreen extends StatefulWidget {
  final Dog dog;

  const DogShowResultsScreen({super.key, required this.dog});

  @override
  State<DogShowResultsScreen> createState() => _DogShowResultsScreenState();
}

class _DogShowResultsScreenState extends State<DogShowResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBarBuilder.buildAppBar(
          title: '${localizations?.exhibitions ?? 'Utstillinger'} - ${widget.dog.name}',
          context: context,
          actions: [
            PageInfoHelper.buildInfoButton(
              context,
              title: localizations?.exhibitionResults ?? 'Utstillingsresultater',
              description: localizations?.exhibitionResultsDesc(widget.dog.name) ?? 'Her kan du registrere og følge med på alle utstillingsresultater for ${widget.dog.name}.',
              features: [
                PageInfoItem(
                  icon: Icons.add_circle_outline,
                  title: localizations?.registerResults ?? 'Registrer resultater',
                  description: localizations?.registerResultsDesc ?? 'Legg til resultater fra utstillinger',
                  color: AppColors.info,
                ),
                PageInfoItem(
                  icon: Icons.bar_chart,
                  title: localizations?.showStatistics ?? 'Statistikk',
                  description: localizations?.showStatisticsDesc ?? 'Se statistikk over BIR, BIM, gruppe- og BIS-resultater',
                  color: AppColors.success,
                ),
                PageInfoItem(
                  icon: Icons.description,
                  title: localizations?.critique ?? 'Kritikk',
                  description: localizations?.critiqueDesc ?? 'Lagre dommerkritikk for hver utstilling',
                  color: AppColors.warning,
                ),
              ],
              tip: localizations?.showResultTip ?? 'Hvis hunden blir BIR, kan du legge til grupperesultat. Vinner den gruppen (BIG1), kan du legge til BIS-resultat.',
            ),
          ],
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: context.colors.textMuted,
            indicatorWeight: 3,
            tabs: [
              Tab(text: localizations?.results ?? 'Resultater'),
              Tab(text: localizations?.statistics ?? 'Statistikk'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildResultsTab(),
              _buildStatisticsTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddResultDialog(context),
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box<ShowResult>('show_results').listenable(),
      builder: (context, Box<ShowResult> box, _) {
        final results = box.values
            .where((r) => r.dogId == widget.dog.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.xlAll,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 72,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  localizations?.noShowResults ?? 'Ingen utstillingsresultater ennå',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localizations?.tapToAdd ?? 'Trykk + for å legge til et resultat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textCaption,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 80),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultCard(result);
          },
        );
      },
    );
  }

  Widget _buildResultCard(ShowResult result) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
      ),
      child: InkWell(
        onTap: () => _showResultDetails(result),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.showName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          dateFormat.format(result.date),
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildResultBadges(result),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _buildChip(result.showClass, AppColors.info),
                  _buildChip(result.quality, _getQualityColor(result.quality)),
                  if (result.classPlacement != null)
                    _buildChip('Kl: ${result.classPlacement}', AppColors.accent2),
                  if (result.hasCK)
                    _buildChip('CK', AppColors.success, icon: Icons.check_circle),
                  if (result.bestOfSexPlacement != null)
                    _buildChip('BH/BT: ${result.bestOfSexPlacement}', AppColors.accent1),
                  if (result.placement != null)
                    _buildChip(result.placement!, _getPlacementColor(result.placement!)),
                  if (result.certificates != null)
                    ...result.certificates!.map((cert) => _buildChip(cert, AppColors.accent5)),
                ],
              ),
              if (result.groupResult != null || result.bisResult != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (result.groupResult != null)
                      _buildChip(result.groupResult!, AppColors.warning, icon: Icons.groups),
                    if (result.bisResult != null)
                      _buildChip(result.bisResult!, AppColors.warning, icon: Icons.emoji_events),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBadges(ShowResult result) {
    final badges = <Widget>[];
    
    if (result.bisResult != null) {
      badges.add(_buildBadge(Icons.emoji_events, AppColors.warning));
    } else if (result.groupResult != null) {
      badges.add(_buildBadge(Icons.groups, AppColors.warning));
    } else if (result.isBIR) {
      badges.add(_buildBadge(Icons.star, Theme.of(context).primaryColor));
    }
    
    return Row(children: badges);
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return AppColors.success;
      case 'Very Good':
        return AppColors.accent2;
      case 'Good':
        return AppColors.info;
      case 'Sufficient':
        return AppColors.warning;
      default:
        return AppColors.neutral500;
    }
  }

  Color _getPlacementColor(String placement) {
    switch (placement) {
      case 'BIR':
        return AppColors.warning;
      case 'BIM':
        return AppColors.neutral600;
      case 'CK':
        return AppColors.success;
      default:
        return AppColors.neutral500;
    }
  }

  Widget _buildStatisticsTab() {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box<ShowResult>('show_results').listenable(),
      builder: (context, Box<ShowResult> box, _) {
        final results = box.values
            .where((r) => r.dogId == widget.dog.id)
            .toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: context.colors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizations?.noStatisticsAvailable ?? 'Ingen statistikk tilgjengelig',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ],
            ),
          );
        }

        final stats = ShowStatistics.fromResults(results);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(stats),
              const SizedBox(height: AppSpacing.lg),
              _buildClassPlacementsCard(stats),
              const SizedBox(height: AppSpacing.lg),
              _buildPlacementCard(stats),
              const SizedBox(height: AppSpacing.lg),
              _buildGroupAndBISCard(stats),
              const SizedBox(height: AppSpacing.lg),
              _buildCertificatesCard(stats),
              const SizedBox(height: AppSpacing.lg),
              _buildJudgesCard(stats, results),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(ShowStatistics stats) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.overview ?? 'Oversikt',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(localizations?.exhibitions ?? 'Utstillinger', stats.totalShows.toString(), Icons.event),
                ),
                Expanded(
                  child: _buildStatItem('CK', stats.ckCount.toString(), Icons.check_circle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              localizations?.quality ?? 'Premiegrader',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildQualityChip('Excellent', stats.excellentCount, Theme.of(context).primaryColor),
                _buildQualityChip('Very Good', stats.veryGoodCount, Theme.of(context).primaryColor),
                _buildQualityChip('Good', stats.goodCount, Theme.of(context).primaryColor),
                _buildQualityChip('Sufficient', stats.sufficientCount, Theme.of(context).primaryColor),
                if (stats.disqualifiedCount > 0)
                  _buildQualityChip('Disqualified', stats.disqualifiedCount, AppColors.neutral500),
                if (stats.cannotBeJudgedCount > 0)
                  _buildQualityChip('Cannot be judged', stats.cannotBeJudgedCount, AppColors.neutral500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPlacementsCard(ShowStatistics stats) {
    final localizations = AppLocalizations.of(context);
    final isMale = widget.dog.gender == 'Male';
    final bestOfSexLabel = isMale 
        ? (localizations?.bestMaleDog ?? 'Beste hannhund (BHK)')
        : (localizations?.bestFemaleDog ?? 'Beste tispe (BTK)');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_numbered, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.classPlacements ?? 'Klasseplasseringer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Text(
              localizations?.classPlacement ?? 'Plassering i klassen',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildMiniStat('1', stats.class1Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('2', stats.class2Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('3', stats.class3Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('4', stats.class4Count, Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              bestOfSexLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildMiniStat('1', stats.bestOfSex1Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('2', stats.bestOfSex2Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('3', stats.bestOfSex3Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('4', stats.bestOfSex4Count, Theme.of(context).primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementCard(ShowStatistics stats) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.breedPlacements ?? 'BIR/BIM',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _buildHighlightStat('BIR', stats.birCount, Theme.of(context).primaryColor),
                ),
                Expanded(
                  child: _buildHighlightStat('BIM', stats.bimCount, Theme.of(context).primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupAndBISCard(ShowStatistics stats) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.groupAndBIS ?? 'Gruppe & BIS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Text(
              localizations?.groupFinals ?? 'Gruppefinaler',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildMiniStat('BIG1', stats.big1Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIG2', stats.big2Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIG3', stats.big3Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIG4', stats.big4Count, Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              localizations?.bestInShow ?? 'Best In Show',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildMiniStat('BIS1', stats.bis1Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIS2', stats.bis2Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIS3', stats.bis3Count, Theme.of(context).primaryColor)),
                Expanded(child: _buildMiniStat('BIS4', stats.bis4Count, Theme.of(context).primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesCard(ShowStatistics stats) {
    // Collect all certificates from results to show actual data
    final results = Hive.box<ShowResult>('show_results')
        .values
        .where((r) => r.dogId == widget.dog.id)
        .toList();
    
    // Count all certificate types dynamically
    final Map<String, int> certCounts = {};
    for (final result in results) {
      if (result.certificates != null) {
        for (final cert in result.certificates!) {
          certCounts[cert] = (certCounts[cert] ?? 0) + 1;
        }
      }
    }
    
    if (certCounts.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_membership, color: Theme.of(context).primaryColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Cert & Cacib',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'Ingen Cert/Cacib ennå',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort certificates by count (highest first)
    final sortedCerts = certCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Cert & Cacib',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            // Display all certificates in a wrap
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: sortedCerts.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgesCard(ShowStatistics stats, List<ShowResult> allResults) {
    final localizations = AppLocalizations.of(context);
    final judges = stats.sortedJudges;
    
    if (judges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.judges ?? 'Dommere',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  localizations?.judgesCount(judges.length) ?? '${judges.length} dommere',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            ...judges.take(10).map((judge) => _buildJudgeItem(judge, allResults)),
            if (judges.length > 10) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => _showAllJudges(judges, allResults),
                  child: Text(localizations?.seeAllJudges(judges.length) ?? 'Se alle ${judges.length} dommere'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJudgeItem(JudgeStatistics judge, List<ShowResult> allResults) {
    final localizations = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _showJudgeResults(judge, allResults),
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
              child: Text(
                judge.name.isNotEmpty ? judge.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judge.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    judge.showCount == 1 
                        ? (localizations?.exhibitionCount(judge.showCount) ?? '${judge.showCount} utstilling')
                        : (localizations?.exhibitionsCount(judge.showCount) ?? '${judge.showCount} utstillinger'),
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (judge.birCount > 0)
              _buildMiniChip('BIR', judge.birCount, Theme.of(context).primaryColor),
            if (judge.bimCount > 0)
              _buildMiniChip('BIM', judge.bimCount, Theme.of(context).primaryColor),
            if (judge.ckCount > 0)
              _buildMiniChip('CK', judge.ckCount, Theme.of(context).primaryColor),
            const Icon(Icons.chevron_right, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showJudgeResults(JudgeStatistics judge, List<ShowResult> allResults) {
    final judgeResults = allResults
        .where((r) => r.judge == judge.name)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final dateFormat = DateFormat('dd.MM.yyyy', 'nb_NO');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      judge.name.isNotEmpty ? judge.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judge.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${judge.showCount} utstilling${judge.showCount != 1 ? 'er' : ''} • ${judge.excellentCount} Excellent • ${judge.ckCount} CK',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Statistikk-rad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildJudgeStatChip('BIR', judge.birCount, Theme.of(context).primaryColor),
                  _buildJudgeStatChip('BIM', judge.bimCount, Theme.of(context).primaryColor),
                  _buildJudgeStatChip('CK', judge.ckCount, Theme.of(context).primaryColor),
                  _buildJudgeStatChip('Excellent', judge.excellentCount, Theme.of(context).primaryColor),
                ],
              ),
            ),
            const Divider(height: AppSpacing.xxl),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: judgeResults.length,
                itemBuilder: (context, index) {
                  final result = judgeResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(result.showName),
                      subtitle: Text(dateFormat.format(result.date)),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (result.placement != null)
                            Chip(
                              label: Text(result.placement!, style: const TextStyle(fontSize: 11)),
                              backgroundColor: _getPlacementColor(result.placement!).withValues(alpha: 0.2),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          Chip(
                            label: Text(result.quality, style: const TextStyle(fontSize: 11)),
                            backgroundColor: _getQualityColor(result.quality).withValues(alpha: 0.2),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showResultDetails(result);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgeStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllJudges(List<JudgeStatistics> judges, List<ShowResult> allResults) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${AppLocalizations.of(context)?.allJudges ?? 'Alle dommere'} (${judges.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: judges.length,
                itemBuilder: (context, index) {
                  final judge = judges[index];
                  return _buildJudgeItem(judge, allResults);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5 ? context.colors.textSecondary : color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.computeLuminance() > 0.5 ? context.colors.textTertiary : color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResultDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddShowResultSheet(
        dogId: widget.dog.id,
        dogGender: widget.dog.gender,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _showResultDetails(ShowResult result) {
    final dateFormat = DateFormat('dd. MMMM yyyy', 'nb_NO');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.showName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined, color: AppColors.info),
                        tooltip: 'Del resultatkort',
                        onPressed: () {
                          final nav = Navigator.of(context, rootNavigator: true);
                          Navigator.pop(context);
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) => ShowResultCardScreen(
                                result: result,
                                dog: widget.dog,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditResultDialog(result);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _deleteResult(result),
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(result.date),
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                  if (result.judge != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppLocalizations.of(context)?.judge ?? 'Dommer'}: ${result.judge}',
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppLocalizations.of(context)?.result ?? 'Resultat',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (result.showType != null)
                        _buildChip(result.showType!, AppColors.accent1),
                      _buildChip(result.showClass, AppColors.info),
                      _buildChip(result.quality, _getQualityColor(result.quality)),
                      if (result.classPlacement != null)
                        _buildChip('Kl: ${result.classPlacement}', AppColors.accent2),
                      if (result.hasCK)
                        _buildChip('CK', AppColors.success, icon: Icons.check_circle),
                      if (result.bestOfSexPlacement != null)
                        _buildChip('${widget.dog.gender == 'Male' ? 'BHK' : 'BTK'}: ${result.bestOfSexPlacement}', AppColors.accent1),
                      if (result.placement != null)
                        _buildChip(result.placement!, _getPlacementColor(result.placement!)),
                      if (result.certificates != null)
                        ...result.certificates!.map((cert) => _buildChip(cert, AppColors.accent5)),
                      if (result.groupResult != null)
                        _buildChip(result.groupResult!, AppColors.warning, icon: Icons.groups),
                      if (result.groupJudge != null && result.groupJudge!.isNotEmpty)
                        _buildChip('Gruppedommer: ${result.groupJudge!}', AppColors.accent3, icon: Icons.person_outline),
                      if (result.bisResult != null)
                        _buildChip(result.bisResult!, AppColors.warning, icon: Icons.emoji_events),
                      if (result.bisJudge != null && result.bisJudge!.isNotEmpty)
                        _buildChip('BIS-dommer: ${result.bisJudge!}', AppColors.warning, icon: Icons.person_outline),
                    ],
                  ),
                  if (result.critique != null && result.critique!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppLocalizations.of(context)?.critique ?? 'Kritikk',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.neutral100,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Text(
                        result.critique!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  if (result.notes != null && result.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppLocalizations.of(context)?.ownNotes ?? 'Notater',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(result.notes!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditResultDialog(ShowResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddShowResultSheet(
        dogId: widget.dog.id,
        dogGender: widget.dog.gender,
        existingResult: result,
        onSaved: () => setState(() {}),
      ),
    );
  }

  Future<void> _deleteResult(ShowResult result) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteResult ?? 'Slett resultat'),
        content: Text(localizations?.confirmDeleteResult(result.showName) ?? 'Er du sikker på at du vil slette resultatet fra ${result.showName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(localizations?.delete ?? 'Slett'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
      
      final box = Hive.box<ShowResult>('show_results');
      final index = box.values.toList().indexWhere((r) => r.id == result.id);
      if (index != -1) {
        await box.deleteAt(index);
        
        // Sync to cloud
        try {
          final userId = AuthService().currentUserId;
          if (userId != null) {
            await CloudSyncService().deleteShowResult(
              userId: userId,
              showResultId: result.id,
            );
          }
        } catch (e) {
          AppLogger.debug('Error syncing show result deletion: $e');
        }
      }
    }
  }
}

class _AddShowResultSheet extends StatefulWidget {
  final String dogId;
  final String dogGender; // 'Male' eller 'Female'
  final ShowResult? existingResult;
  final VoidCallback onSaved;

  const _AddShowResultSheet({
    required this.dogId,
    required this.dogGender,
    this.existingResult,
    required this.onSaved,
  });

  @override
  State<_AddShowResultSheet> createState() => _AddShowResultSheetState();
}

class _AddShowResultSheetState extends State<_AddShowResultSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // TextEditingControllers for tekstfelt
  late TextEditingController _showNameController;
  late TextEditingController _judgeController;
  late TextEditingController _critiqueController;
  late TextEditingController _notesController;
  late TextEditingController _groupJudgeController;
  late TextEditingController _bisJudgeController;
  
  late DateTime _selectedDate;
  late String _showClass;
  late String _quality;
  String? _classPlacement;
  String? _placement;
  List<String> _selectedCertificates = [];
  String? _bestOfSexPlacement;
  String? _groupResult;
  String? _bisResult;
  String? _showType;
  bool _hasCK = false;
  String _selectedCountry = 'Norge'; // Ny: Land-valg

  // Land som støtter CK-systemet (Nordiske land)
  static const List<String> _nordicCountries = ['Norge', 'Sverige', 'Danmark', 'Finland'];
  
  // Alle land
  static const List<String> _countries = [
    'Norge',
    'Sverige', 
    'Danmark',
    'Finland',
    'Tyskland',
    'Storbritannia',
    'Frankrike',
    'Italia',
    'Spania',
    'Nederland',
    'Belgia',
    'Sveits',
    'Østerrike',
    'Polen',
    'Tsjekkia',
    'Ungarn',
    'USA',
    'Annet',
  ];

  final List<String> _showClasses = [
    'Valp 4-6 mnd',
    'Valp 6-9 mnd',
    'Junior',
    'Unghund',
    'Åpen',
    'Bruks',
    'Champion',
    'Veteran',
  ];

  final List<String> _qualities = [
    'Excellent',
    'Very Good',
    'Good',
    'Sufficient',
    'Disqualified',
    'Cannot be judged',
  ];

  final List<String> _puppyQualities = [
    'Særdeles lovende',
    'Meget lovende',
    'Lovende',
    'Kan ikke bedømmes',
  ];

  final List<String> _classPlacements = [
    '1',
    '2',
    '3',
    '4',
    'Uplassert',
  ];

  final List<String> _placements = [
    'BIR',
    'BIM',
  ];

  final List<String> _puppyPlacements = [
    'BIR Valp',
    'BIM Valp',
  ];

  final List<String> _groupResults = [
    'BIG1',
    'BIG2',
    'BIG3',
    'BIG4',
  ];

  final List<String> _bisResults = [
    'BIS1',
    'BIS2',
    'BIS3',
    'BIS4',
  ];

  final List<String> _showTypes = [
    'Valpeshow',
    'Nasjonal',
    'Nordisk',
    'Internasjonal',
    'Rasespesial',
  ];

  final List<String> _bestOfSexPlacements = [
    '1',
    '2',
    '3',
    '4',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialiser TextEditingControllers
    _showNameController = TextEditingController();
    _judgeController = TextEditingController();
    _critiqueController = TextEditingController();
    _notesController = TextEditingController();
    _groupJudgeController = TextEditingController();
    _bisJudgeController = TextEditingController();
    
    if (widget.existingResult != null) {
      _selectedDate = widget.existingResult!.date;
      _showNameController.text = widget.existingResult!.showName;
      _judgeController.text = widget.existingResult!.judge ?? '';
      _showClass = widget.existingResult!.showClass;
      _quality = widget.existingResult!.quality;
      _classPlacement = widget.existingResult!.classPlacement;
      _placement = widget.existingResult!.placement;
      _selectedCertificates = widget.existingResult!.certificates != null 
          ? List<String>.from(widget.existingResult!.certificates!)
          : [];
      _bestOfSexPlacement = widget.existingResult!.bestOfSexPlacement;
      _groupResult = widget.existingResult!.groupResult;
      _bisResult = widget.existingResult!.bisResult;
      _groupJudgeController.text = widget.existingResult!.groupJudge ?? '';
      _bisJudgeController.text = widget.existingResult!.bisJudge ?? '';
      _critiqueController.text = widget.existingResult!.critique ?? '';
      _notesController.text = widget.existingResult!.notes ?? '';
      _showType = widget.existingResult!.showType;
      _hasCK = widget.existingResult!.hasCK;
    } else {
      _selectedDate = DateTime.now();
      _showClass = 'Åpen';
      _quality = 'Excellent';
      _hasCK = false;
    }
  }

  @override
  void dispose() {
    _showNameController.dispose();
    _judgeController.dispose();
    _critiqueController.dispose();
    _notesController.dispose();
    _groupJudgeController.dispose();
    _bisJudgeController.dispose();
    super.dispose();
  }

  bool get _isBIR => _placement == 'BIR' || _placement == 'BIR Valp';
  bool get _isBIG1 => _groupResult == 'BIG1';
  
  /// Sjekker om dette er et valpeshow
  bool get _isPuppyShow => _showType == 'Valpeshow';
  
  /// Sjekker om valgt klasse er en valpeklasse
  bool get _isPuppyClass => _showClass == 'Valp 4-6 mnd' || _showClass == 'Valp 6-9 mnd';
  
  /// Returnerer tilgjengelige klasser basert på utstillingstype
  List<String> get _availableShowClasses {
    if (_isPuppyShow) {
      return ['Valp 4-6 mnd', 'Valp 6-9 mnd'];
    }
    // For vanlige utstillinger, vis alle unntatt valpeklasser
    return _showClasses.where((c) => c != 'Valp 4-6 mnd' && c != 'Valp 6-9 mnd').toList();
  }
  
  /// Returnerer tilgjengelige premiegrader basert på klasse
  List<String> get _availableQualities {
    if (_isPuppyClass) {
      return _puppyQualities;
    }
    return _qualities;
  }
  
  /// Sjekk om valgt land er et nordisk land (støtter CK-systemet)
  bool get _isNordicCountry => _nordicCountries.contains(_selectedCountry);
  
  /// Sjekk om CK er tilgjengelig (kun i nordiske land og med Excellent)
  bool get _isCKAvailable => _isNordicCountry && _quality == 'Excellent';
  
  /// Sjekk om BIR/BIM skal være låst basert på BHK/BTK plassering
  /// I Norden kreves BHK/BTK 1. plass for å kunne vinne BIR/BIM
  bool get _isBIRBIMAvailable {
    if (!_isNordicCountry) return true; // Ingen begrensning utenfor Norden
    return _bestOfSexPlacement == '1';
  }
  
  /// Sjekk om premiegrad er en som låser resten av feltvalgene
  bool get _isQualityLocking {
    // For voksne klasser
    if (_quality == 'Good' || 
        _quality == 'Sufficient' || 
        _quality == 'Cannot be judged' || 
        _quality == 'Disqualified') {
      return true;
    }
    // For valpeklasser
    if (_isPuppyClass && (_quality == 'Lovende' || _quality == 'Kan ikke bedømmes')) {
      return true;
    }
    return false;
  }

  /// Returnerer tilgjengelige sertifikater basert på utstillingstype og klasse
  List<String> _getAvailableCertificates() {
    // Ingen cert ved dårlig premiegrad
    if (_isQualityLocking) return [];
    
    final isJunior = _showClass == 'Junior';
    final isVeteran = _showClass == 'Veteran';
    final isJuniorOrVeteran = isJunior || isVeteran;
    
    switch (_showType) {
      case 'Nasjonal':
      case 'Rasespesial':
        // Alle klasser inkludert Junior/Veteran kan ta Cert og Res.Cert
        return ['Cert', 'Res.Cert'];
        
      case 'Nordisk':
        // Junior/Veteran kan kun ta Cert og Res.Cert (ikke Nordisk Cert)
        if (isJuniorOrVeteran) {
          return ['Cert', 'Res.Cert'];
        }
        // Standard klasser kan ta Nordisk Cert
        return ['Cert', 'Res.Cert', 'Nordisk Cert', 'Res.Nordisk Cert'];
        
      case 'Internasjonal':
        // Junior/Veteran kan kun ta Cert og Res.Cert (ikke Cacib)
        if (isJuniorOrVeteran) {
          return ['Cert', 'Res.Cert'];
        }
        // Standard klasser kan ta Cacib
        return ['Cert', 'Res.Cert', 'Cacib', 'Res.Cacib'];
        
      default:
        // Valpeshow eller ikke valgt - ingen sertifikater
        return [];
    }
  }

  /// Returnerer tilgjengelige Junior/Veteran sertifikater basert på utstillingstype
  List<String> _getAvailableJuniorVeteranCertificates() {
    // Ingen cert ved dårlig premiegrad
    if (_isQualityLocking) return [];
    
    final isJunior = _showClass == 'Junior';
    final isVeteran = _showClass == 'Veteran';
    
    // Kun for Junior eller Veteran klasser
    if (!isJunior && !isVeteran) return [];
    
    if (isJunior) {
      switch (_showType) {
        case 'Nasjonal':
        case 'Rasespesial':
          // Nasjonal/Spesial: Ingen ekstra junior-sertifikater
          return [];
          
        case 'Nordisk':
          // Nordisk: Junior Cert, Nordisk Junior Cert og Reserve
          return ['Junior Cert', 'Res.Junior Cert', 'Nordisk Junior Cert', 'Res.Nordisk Junior Cert'];
          
        case 'Internasjonal':
          // Internasjonal: Junior Cert og Junior Cacib
          return ['Junior Cert', 'Junior Cacib'];
          
        default:
          return [];
      }
    } else {
      // Veteran
      switch (_showType) {
        case 'Nasjonal':
        case 'Rasespesial':
          // Nasjonal/Spesial: Ingen ekstra veteran-sertifikater
          return [];
          
        case 'Nordisk':
          // Nordisk: Veteran Cert, Nordisk Veteran Cert og Reserve
          return ['Veteran Cert', 'Res.Veteran Cert', 'Nordisk Veteran Cert', 'Res.Nordisk Veteran Cert'];
          
        case 'Internasjonal':
          // Internasjonal: Veteran Cert og Veteran Cacib
          return ['Veteran Cert', 'Veteran Cacib'];
          
        default:
          return [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  widget.existingResult != null 
                      ? (localizations?.editResult ?? 'Rediger resultat')
                      : (localizations?.addResult ?? 'Legg til resultat'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                shrinkWrap: true,
                children: [
                  // Dato
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                    title: Text(localizations?.date ?? 'Dato'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Utstillingsnavn
                  TextFormField(
                    controller: _showNameController,
                    decoration: InputDecoration(
                      labelText: '${localizations?.showName ?? 'Utstillingsnavn'} *',
                      hintText: localizations?.showNameHint ?? 'f.eks. NKK Drammen',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? (localizations?.required ?? 'Påkrevd') : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Utstillingstype
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _showType,
                    decoration: InputDecoration(
                      labelText: localizations?.showType ?? 'Type utstilling',
                      border: const OutlineInputBorder(),
                    ),
                    items: _showTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _showType = value;
                        // Reset klasse og premiegrad når utstillingstype endres
                        if (value == 'Valpeshow') {
                          _showClass = 'Valp 4-6 mnd';
                          _quality = 'Særdeles lovende';
                          _hasCK = false;
                          _placement = null;
                          _groupResult = null;
                          _bisResult = null;
                        } else if (_isPuppyClass) {
                          // Hvis vi bytter fra valpeshow til annen type, reset til Åpen
                          _showClass = 'Åpen';
                          _quality = 'Excellent';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Land
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCountry,
                    decoration: InputDecoration(
                      labelText: 'Land',
                      border: const OutlineInputBorder(),
                      helperText: _isNordicCountry 
                          ? 'CK-systemet er tilgjengelig' 
                          : 'CK er kun tilgjengelig i Norden',
                    ),
                    items: _countries.map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCountry = value;
                          // Nullstill CK hvis landet ikke støtter det
                          if (!_nordicCountries.contains(value)) {
                            _hasCK = false;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Dommer
                  TextFormField(
                    controller: _judgeController,
                    decoration: InputDecoration(
                      labelText: localizations?.judge ?? 'Dommer',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Klasse
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey('class_$_showType'), // Force rebuild når showType endres
                    initialValue: _availableShowClasses.contains(_showClass) ? _showClass : _availableShowClasses.first,
                    decoration: InputDecoration(
                      labelText: '${localizations?.showClass ?? 'Klasse'} *',
                      border: const OutlineInputBorder(),
                    ),
                    items: _availableShowClasses.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _showClass = value;
                          // Reset premiegrad når vi bytter mellom valp og vanlig klasse
                          if (_isPuppyClass && !_puppyQualities.contains(_quality)) {
                            _quality = 'Særdeles lovende';
                          } else if (!_isPuppyClass && !_qualities.contains(_quality)) {
                            _quality = 'Excellent';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Premiegrad
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey('quality_$_showClass'), // Force rebuild når klasse endres
                    initialValue: _availableQualities.contains(_quality) ? _quality : _availableQualities.first,
                    decoration: InputDecoration(
                      labelText: '${localizations?.quality ?? 'Premiegrad'} *',
                      border: const OutlineInputBorder(),
                      helperText: _isQualityLocking 
                          ? 'Ingen plassering eller sertifikater tilgjengelig med denne premiegraden' 
                          : null,
                      helperStyle: TextStyle(color: AppColors.warning),
                    ),
                    items: _availableQualities.map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _quality = value;
                          // Reset alt hvis dårlig premiegrad
                          if (_isQualityLocking) {
                            _hasCK = false;
                            _classPlacement = null;
                            _bestOfSexPlacement = null;
                            _placement = null;
                            _groupResult = null;
                            _bisResult = null;
                            _selectedCertificates.clear();
                          } else if (value != 'Excellent' && value != 'Særdeles lovende') {
                            _hasCK = false;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Resten av feltene vises kun hvis premiegrad tillater det
                  if (!_isQualityLocking) ...[
                  // Plassering i klassen
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _classPlacement,
                    decoration: InputDecoration(
                      labelText: localizations?.classPlacement ?? 'Plassering i klassen',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'Ingen')),
                      ..._classPlacements.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p),
                      )),
                    ],
                    onChanged: (value) => setState(() => _classPlacement = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // CK Checkbox (kun tilgjengelig med Excellent OG i nordiske land)
                  // HP Checkbox for valper (kun tilgjengelig med Særdeles lovende)
                  if (_isPuppyClass)
                    Container(
                      decoration: BoxDecoration(
                        color: _quality == 'Særdeles lovende'
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : context.colors.neutral200.withValues(alpha: 0.5),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: _quality == 'Særdeles lovende'
                              ? AppColors.warning.withValues(alpha: 0.4)
                              : context.colors.neutral300.withValues(alpha: 0.5),
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          'HP (Hederspris / Hopeful Puppy)',
                          style: TextStyle(
                            color: _quality == 'Særdeles lovende' ? null : context.colors.textDisabled,
                          ),
                        ),
                        subtitle: _quality != 'Særdeles lovende'
                            ? Text(
                                'Krever Særdeles lovende',
                                style: TextStyle(color: context.colors.textDisabled, fontSize: 12),
                              )
                            : const Text(
                                'Kvalifiserer for beste hannvalp/tispevalp',
                                style: TextStyle(fontSize: 12),
                              ),
                        value: _hasCK, // Gjenbruker _hasCK for HP
                        onChanged: _quality == 'Særdeles lovende'
                            ? (value) => setState(() => _hasCK = value ?? false)
                            : null,
                        activeColor: AppColors.warning,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        dense: true,
                      ),
                    )
                  else if (_isNordicCountry)
                  Container(
                    decoration: BoxDecoration(
                      color: _isCKAvailable 
                          ? AppColors.success.withValues(alpha: 0.15)
                          : context.colors.neutral200.withValues(alpha: 0.5),
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                        color: _isCKAvailable
                            ? AppColors.success.withValues(alpha: 0.4)
                            : context.colors.neutral300.withValues(alpha: 0.5),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        localizations?.ckCertificateQuality ?? 'CK (Certifikat Kvalitet)',
                        style: TextStyle(
                          color: _isCKAvailable ? null : context.colors.textDisabled,
                        ),
                      ),
                      subtitle: !_isCKAvailable
                          ? Text(
                              'Krever Excellent',
                              style: TextStyle(color: context.colors.textDisabled, fontSize: 12),
                            )
                          : null,
                      value: _hasCK,
                      onChanged: _isCKAvailable
                          ? (value) => setState(() => _hasCK = value ?? false)
                          : null,
                      activeColor: AppColors.success,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      dense: true,
                    ),
                  ),
                  if (_isNordicCountry || _isPuppyClass) const SizedBox(height: AppSpacing.lg),
                  
                  // Beste hannhund/tispe plassering (eller beste hannvalp/tispevalp)
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _bestOfSexPlacement,
                    decoration: InputDecoration(
                      labelText: _isPuppyClass
                          ? (widget.dogGender == 'Male' 
                              ? 'Beste hannvalp'
                              : 'Beste tispevalp')
                          : (widget.dogGender == 'Male' 
                              ? (localizations?.bestMalePlacement ?? 'Plassering beste hannhund (BHK)')
                              : (localizations?.bestFemalePlacement ?? 'Plassering beste tispe (BTK)')),
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_hasCK && _classPlacement == '1' ? 'Kvalifisert for BIR/BIM Valp' : 'Krever 1. plass med HP for å delta')
                          : (_isNordicCountry && _bestOfSexPlacement != '1'
                              ? 'BHK/BTK 1 kreves for BIR/BIM i Norden'
                              : null),
                    ),
                    items: _isPuppyClass
                        ? [
                            DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'Ingen')),
                            const DropdownMenuItem(value: '1', child: Text('Ja - Vant')),
                          ]
                        : [
                            DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'Ingen')),
                            ..._bestOfSexPlacements.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            )),
                          ],
                    onChanged: (value) {
                      setState(() {
                        _bestOfSexPlacement = value;
                        // I Norden: Nullstill BIR/BIM hvis ikke 1. plass i BHK/BTK
                        if (_isNordicCountry && value != '1') {
                          _placement = null;
                          _groupResult = null;
                          _bisResult = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // BIR/BIM - låst i Norden hvis ikke BHK/BTK 1
                  // For valper: BIR Valp / BIM Valp
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _placement,
                    decoration: InputDecoration(
                      labelText: _isPuppyClass ? 'BIR/BIM Valp' : 'BIR/BIM',
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_bestOfSexPlacement != '1' ? 'Krever å være beste hannvalp/tispevalp' : null)
                          : (!_isBIRBIMAvailable ? 'Krever BHK/BTK 1. plass i Norden' : null),
                      helperStyle: TextStyle(color: AppColors.warning),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'Ingen')),
                      ...(_isPuppyClass ? _puppyPlacements : _placements).map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p),
                      )),
                    ],
                    onChanged: (_isPuppyClass ? _bestOfSexPlacement == '1' : _isBIRBIMAvailable)
                        ? (value) {
                            setState(() {
                              _placement = value;
                              // Reset gruppe og BIS hvis ikke BIR
                              if (value != 'BIR' && value != 'BIR Valp') {
                                _groupResult = null;
                                _bisResult = null;
                              }
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Sertifikater (checkboxer for flere valg) - kun hvis det finnes tilgjengelige cert
                  if (_getAvailableCertificates().isNotEmpty || 
                      ((_showClass == 'Junior' || _showClass == 'Veteran') && _getAvailableJuniorVeteranCertificates().isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_getAvailableCertificates().isNotEmpty)
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: 0,
                              children: _getAvailableCertificates().map((cert) {
                                final isSelected = _selectedCertificates.contains(cert);
                                return FilterChip(
                                  label: Text(
                                    cert,
                                    style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCertificates.add(cert);
                                    } else {
                                      _selectedCertificates.remove(cert);
                                    }
                                  });
                                },
                                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                checkmarkColor: Theme.of(context).primaryColor,
                                backgroundColor: context.colors.surface,
                                side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                              );
                            }).toList(),
                          ),
                          // Junior/Veteran spesifikke cert
                          if ((_showClass == 'Junior' || _showClass == 'Veteran') && _getAvailableJuniorVeteranCertificates().isNotEmpty) ...[
                            if (_getAvailableCertificates().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              const Divider(),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: 0,
                              children: _getAvailableJuniorVeteranCertificates().map((cert) {
                                final isSelected = _selectedCertificates.contains(cert);
                                return FilterChip(
                                  label: Text(
                                    cert,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCertificates.add(cert);
                                      } else {
                                        _selectedCertificates.remove(cert);
                                      }
                                    });
                                  },
                                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                  checkmarkColor: Theme.of(context).primaryColor,
                                  backgroundColor: context.colors.surface,
                                  side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  
                  // Grupperesultat (kun synlig hvis BIR, ikke for valper)
                  if (_isBIR && !_isPuppyClass) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                localizations?.groupFinal ?? 'Gruppefinale',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _groupResult,
                            decoration: InputDecoration(
                              labelText: localizations?.groupResult ?? 'Grupperesultat',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(localizations?.didNotParticipate ?? 'Deltok ikke / ingen plassering')),
                              ..._groupResults.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _groupResult = value;
                                // Reset BIS hvis ikke BIG1
                                if (value != 'BIG1') {
                                  _bisResult = null;
                                  _bisJudgeController.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _groupJudgeController,
                            decoration: InputDecoration(
                              labelText: 'Gruppedommer',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // BIS-resultat (kun synlig hvis BIG1)
                  if (_isBIG1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                localizations?.bestInShow ?? 'Best In Show',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _bisResult,
                            decoration: InputDecoration(
                              labelText: localizations?.bisResult ?? 'BIS-resultat',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(localizations?.noPlacement ?? 'Ingen plassering')),
                              ..._bisResults.map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              )),
                            ],
                            onChanged: (value) => setState(() => _bisResult = value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _bisJudgeController,
                            decoration: InputDecoration(
                              labelText: 'BIS-dommer',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.xxl),
                  ], // Slutt på if (!_isQualityLocking)
                  
                  // Kritikk
                  TextFormField(
                    controller: _critiqueController,
                    decoration: InputDecoration(
                      labelText: localizations?.judgeCritique ?? 'Dommerkritikk',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Notater
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: localizations?.ownNotes ?? 'Egne notater',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Lagre-knapp
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveResult,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                        ),
                      ),
                      child: Text(widget.existingResult != null 
                          ? (localizations?.update ?? 'Oppdater')
                          : (localizations?.save ?? 'Lagre')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;

    final box = Hive.box<ShowResult>('show_results');
    
    // Hent verdier fra controllers
    final showName = _showNameController.text.trim();
    final judge = _judgeController.text.trim().isEmpty ? null : _judgeController.text.trim();
    final critique = _critiqueController.text.trim().isEmpty ? null : _critiqueController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final groupJudge = _groupJudgeController.text.trim().isEmpty ? null : _groupJudgeController.text.trim();
    final bisJudge = _bisJudgeController.text.trim().isEmpty ? null : _bisJudgeController.text.trim();
    
    final result = ShowResult(
      id: widget.existingResult?.id ?? const Uuid().v4(),
      dogId: widget.dogId,
      date: _selectedDate,
      showName: showName,
      judge: judge,
      showClass: _showClass,
      quality: _quality,
      classPlacement: _classPlacement,
      placement: _placement,
      certificates: _selectedCertificates.isNotEmpty ? _selectedCertificates : null,
      bestOfSexPlacement: _bestOfSexPlacement,
      groupResult: _groupResult,
      bisResult: _bisResult,
      groupJudge: groupJudge,
      bisJudge: bisJudge,
      critique: critique,
      notes: notes,
      showType: _showType,
      hasCK: _hasCK,
    );

    if (widget.existingResult != null) {
      final index = box.values.toList().indexWhere((r) => r.id == result.id);
      if (index != -1) {
        await box.putAt(index, result);
      }
    } else {
      await box.add(result);
    }

    // Sync to cloud
    try {
      final userId = AuthService().currentUserId;
      if (userId != null) {
        await CloudSyncService.syncShowResult(userId, result);
      }
    } catch (e) {
      AppLogger.debug('Error syncing show result: $e');
    }

    if (mounted) {
      // Capture scaffold/navigator before popping (context becomes invalid after pop)
      Dog? shareDog;
      ScaffoldMessengerState? scaffoldMessenger;
      NavigatorState? navigator;
      if (widget.existingResult == null) {
        try {
          final dogsBox = Hive.box<Dog>('dogs');
          shareDog = dogsBox.values.where((d) => d.id == widget.dogId).firstOrNull;
          scaffoldMessenger = ScaffoldMessenger.of(context);
          navigator = Navigator.of(context);
        } catch (_) {}
      }

      Navigator.pop(context);
      widget.onSaved();

      // Prompt to share result card (only for new results)
      if (shareDog != null && scaffoldMessenger != null && navigator != null) {
        final dog = shareDog;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Resultat lagret!'),
            action: SnackBarAction(
              label: 'Del resultatkort',
              onPressed: () {
                navigator!.push(
                  MaterialPageRoute(
                    builder: (_) => ShowResultCardScreen(
                      result: result,
                      dog: dog,
                    ),
                  ),
                );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
