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
import 'package:breedly/services/feed_service.dart';
import 'package:breedly/services/kennel_service.dart';
import 'package:breedly/models/feed_post.dart';
import 'package:breedly/models/kennel.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/widgets/show_result_card.dart';
import 'package:breedly/services/show_data_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DogShowResultsScreen extends StatefulWidget {
  final Dog dog;

  const DogShowResultsScreen({super.key, required this.dog});

  @override
  State<DogShowResultsScreen> createState() => _DogShowResultsScreenState();
}

class _DogShowResultsScreenState extends State<DogShowResultsScreen> {
  // Filter state
  int? _filterYear;
  String? _filterShowType;
  String? _filterJudge;
  String? _filterQuality;

  List<int> _getAvailableYears() {
    final box = Hive.box<ShowResult>('show_results');
    final years = box.values
        .where((r) => r.dogId == widget.dog.id)
        .map((r) => r.date.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<ShowResult> _applyFilters(List<ShowResult> results) {
    return results.where((r) {
      if (_filterYear != null && r.date.year != _filterYear) return false;
      if (_filterShowType != null && r.showType != _filterShowType) return false;
      if (_filterJudge != null && r.judge != _filterJudge) return false;
      if (_filterQuality != null && r.quality != _filterQuality) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _filterYear != null || _filterShowType != null || _filterJudge != null || _filterQuality != null;

  void _clearFilters() {
    setState(() {
      _filterYear = null;
      _filterShowType = null;
      _filterJudge = null;
      _filterQuality = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBarBuilder.buildAppBar(
          title: '${localizations?.exhibitions ?? 'Utstillinger'} - ${widget.dog.name}',
          context: context,
          actions: [
            // PDF Export button
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Eksporter utstillings-CV',
              onPressed: () => _exportShowCV(context),
            ),
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
              Tab(text: 'Titler'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildResultsTab(),
              _buildStatisticsTab(),
              _buildTitleProgressionTab(),
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
        final allResults = box.values
            .where((r) => r.dogId == widget.dog.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (allResults.isEmpty) {
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

        final results = _applyFilters(allResults);

        return Column(
          children: [
            // Filter bar
            _buildFilterBar(allResults),
            // Results list
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_list_off, size: 48, color: context.colors.textDisabled),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Ingen resultater matcher filteret',
                            style: TextStyle(color: context.colors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Fjern filter'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.sm, bottom: 80),
                      itemCount: results.length,
                      itemBuilder: (context, index) => _buildResultCard(results[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<ShowResult> allResults) {
    final years = _getAvailableYears();
    final judges = allResults
        .where((r) => r.judge != null && r.judge!.isNotEmpty)
        .map((r) => r.judge!)
        .toSet()
        .toList()
      ..sort();
    final showTypes = allResults
        .where((r) => r.showType != null)
        .map((r) => r.showType!)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: _hasActiveFilters
            ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: context.colors.divider),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 18, color: context.colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            // Year filter
            _buildFilterDropdown<int?>(
              label: _filterYear?.toString() ?? 'År',
              isActive: _filterYear != null,
              items: [null, ...years],
              itemLabel: (v) => v?.toString() ?? 'Alle år',
              onSelected: (v) => setState(() => _filterYear = v),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Show type filter
            if (showTypes.isNotEmpty)
              _buildFilterDropdown<String?>(
                label: _filterShowType ?? 'Type',
                isActive: _filterShowType != null,
                items: [null, ...showTypes],
                itemLabel: (v) => v ?? 'Alle typer',
                onSelected: (v) => setState(() => _filterShowType = v),
              ),
            const SizedBox(width: AppSpacing.sm),
            // Judge filter
            if (judges.isNotEmpty)
              _buildFilterDropdown<String?>(
                label: _filterJudge ?? 'Dommer',
                isActive: _filterJudge != null,
                items: [null, ...judges],
                itemLabel: (v) => v ?? 'Alle dommere',
                onSelected: (v) => setState(() => _filterJudge = v),
              ),
            if (_hasActiveFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text('Nullstill', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required bool isActive,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T) onSelected,
  }) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<T>(
          value: item,
          child: Text(itemLabel(item)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : context.colors.neutral200,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                : context.colors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.length > 15 ? '${label.substring(0, 15)}...' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Theme.of(context).primaryColor : context.colors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? Theme.of(context).primaryColor : context.colors.textMuted,
            ),
          ],
        ),
      ),
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
                    _buildChip('${AppLocalizations.of(context)?.classAbbrev ?? 'Kl'}: ${result.classPlacement}', AppColors.accent2),
                  if (result.hasCK)
                    _buildChip('CK', AppColors.success, icon: Icons.check_circle),
                  if (result.bestOfSexPlacement != null)
                    _buildChip('${AppLocalizations.of(context)?.bestOfSexAbbrev ?? 'BH/BT'}: ${result.bestOfSexPlacement}', AppColors.accent1),
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
                  AppLocalizations.of(context)?.noCertCacibYet ?? 'Ingen Cert/Cacib ennå',
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
                          AppLocalizations.of(context)?.judgeStatsSummary(judge.showCount, judge.excellentCount, judge.ckCount) ?? '${judge.showCount} utstillinger • ${judge.excellentCount} Excellent • ${judge.ckCount} CK',
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

  // ──── TITLE PROGRESSION TAB ────

  Widget _buildTitleProgressionTab() {
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
                Icon(Icons.military_tech_outlined, size: 64, color: context.colors.textDisabled),
                const SizedBox(height: AppSpacing.lg),
                Text('Ingen resultater ennå', style: TextStyle(color: context.colors.textMuted)),
              ],
            ),
          );
        }

        final progression = ShowDataService().getTitleProgression(results, dogDateOfBirth: widget.dog.dateOfBirth, dogBreed: widget.dog.breed, tilleggskravCompleted: widget.dog.tilleggskravCompleted);
        results.sort((a, b) => a.date.compareTo(b.date));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title progress cards
              ...progression.titles.where((t) => !t.isInformational).map((title) => _buildTitleCard(title)),
              const SizedBox(height: AppSpacing.lg),
              // Informational stats
              ...progression.titles.where((t) => t.isInformational).map((title) => _buildInfoStatCard(title)),
              const SizedBox(height: AppSpacing.xxl),
              // Trend graph
              _buildTrendGraph(results),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleCard(TitleProgress title) {
    final primaryColor = Theme.of(context).primaryColor;
    final isComplete = title.isComplete;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: isComplete
            ? BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.success.withValues(alpha: 0.15)
                        : primaryColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    isComplete ? Icons.emoji_events : Icons.military_tech_outlined,
                    color: isComplete ? AppColors.success : primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title.titleName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isComplete ? AppColors.success : null,
                            ),
                          ),
                          if (isComplete) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          ],
                        ],
                      ),
                      Text(
                        title.fullName,
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${title.current}/${title.required}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? AppColors.success : primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: title.progress,
                backgroundColor: context.colors.neutral200,
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? AppColors.success : primaryColor,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isComplete
                  ? '✓ Tittel oppnådd!'
                  : '${title.remaining} gjenstår — ${title.description}',
              style: TextStyle(
                color: isComplete ? AppColors.success : context.colors.textMuted,
                fontSize: 12,
                fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // Prerequisite warning
            if (title.prerequisite != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    title.prerequisite!,
                    style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            // Notes / warnings
            if (title.notes != null && title.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ...title.notes!.map((note) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(fontSize: 11, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            // Tilleggskrav section
            if (title.tilleggskrav != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: title.tilleggskravCompleted
                      ? AppColors.success.withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(
                    color: title.tilleggskravCompleted
                        ? AppColors.success.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          title.tilleggskravCompleted
                              ? Icons.check_circle
                              : Icons.assignment_outlined,
                          size: 16,
                          color: title.tilleggskravCompleted
                              ? AppColors.success
                              : Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tilleggskrav (${title.tilleggskrav!.kravType})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: title.tilleggskravCompleted
                                  ? AppColors.success
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Switch.adaptive(
                            value: title.tilleggskravCompleted,
                            activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                            activeThumbColor: AppColors.success,
                            onChanged: (value) async {
                              widget.dog.tilleggskravCompleted = value;
                              await widget.dog.save();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.tilleggskrav!.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: title.tilleggskravCompleted
                            ? AppColors.success
                            : Colors.orange[900],
                        decoration: title.tilleggskravCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (title.tilleggskravCompleted) ...[
                      const SizedBox(height: 2),
                      Text(
                        '✓ Tilleggskrav oppfylt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Detail counts
            if (title.detailCounts != null && title.detailCounts!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: title.detailCounts!.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.colors.neutral200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(fontSize: 10, color: context.colors.textCaption),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStatCard(TitleProgress title) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      child: ListTile(
        leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
        title: Text(title.titleName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(title.description),
        trailing: Text(
          title.current.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  // ──── TREND GRAPH ────

  Widget _buildTrendGraph(List<ShowResult> sortedResults) {
    final primaryColor = Theme.of(context).primaryColor;

    // Group by month: calculate a "score" per show
    // Excellent=4, VeryGood=3, Good=2, Sufficient=1, +2 for CK, +3 for BIR, +2 for BIM
    int scoreResult(ShowResult r) {
      int s = 0;
      switch (r.quality) {
        case 'Excellent':
        case 'Særdeles lovende':
          s = 4;
          break;
        case 'Very Good':
        case 'Meget lovende':
          s = 3;
          break;
        case 'Good':
        case 'Lovende':
          s = 2;
          break;
        case 'Sufficient':
          s = 1;
          break;
        default:
          s = 0;
      }
      if (r.gotCK) s += 2;
      if (r.placement == 'BIR' || r.placement == 'BIR Valp') s += 3;
      if (r.placement == 'BIM' || r.placement == 'BIM Valp') s += 2;
      if (r.groupResult != null) s += 2;
      if (r.bisResult != null) s += 3;
      return s;
    }

    if (sortedResults.length < 2) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: primaryColor),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Resultattrend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Minst 2 resultater kreves for å vise trend',
                style: TextStyle(color: context.colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final spots = sortedResults.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), scoreResult(entry.value).toDouble());
    }).toList();

    final dateFormat = DateFormat('dd.MM.yy');

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
                Icon(Icons.show_chart, color: primaryColor),
                const SizedBox(width: AppSpacing.sm),
                const Text('Resultattrend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Score basert på premiegrad, CK, BIR/BIM, gruppe og BIS',
              style: TextStyle(color: context.colors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.colors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10, color: context.colors.textCaption),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (sortedResults.length / 5).ceil().toDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedResults.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                dateFormat.format(sortedResults[idx].date),
                                style: TextStyle(fontSize: 9, color: context.colors.textCaption),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final idx = spot.spotIndex;
                        if (idx < 0 || idx >= sortedResults.length) return null;
                        final r = sortedResults[idx];
                        return LineTooltipItem(
                          '${r.showName}\n${dateFormat.format(r.date)}\nScore: ${spot.y.toInt()}',
                          TextStyle(color: Colors.white, fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──── PDF EXPORT ────

  Future<void> _exportShowCV(BuildContext context) async {
    final box = Hive.box<ShowResult>('show_results');
    final results = box.values
        .where((r) => r.dogId == widget.dog.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingen resultater å eksportere')),
      );
      return;
    }

    final dateFormat = DateFormat('dd.MM.yyyy');
    final stats = ShowStatistics.fromResults(results);
    final progression = ShowDataService().getTitleProgression(results, dogDateOfBirth: widget.dog.dateOfBirth, dogBreed: widget.dog.breed, tilleggskravCompleted: widget.dog.tilleggskravCompleted);
    final dog = widget.dog;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Text(
              'Utstillings-CV',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              dog.name,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '${dog.breed} • ${dog.gender == 'Male' ? 'Hann' : 'Tispe'} • Født: ${dateFormat.format(dog.dateOfBirth)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          if (dog.registrationNumber != null && dog.registrationNumber!.isNotEmpty)
            pw.Center(
              child: pw.Text(
                'Reg.nr: ${dog.registrationNumber}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Statistics summary
          pw.Text('Statistikk', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _pdfStatBox('Utstillinger', stats.totalShows.toString()),
              _pdfStatBox('CK', stats.ckCount.toString()),
              _pdfStatBox('BIR', stats.birCount.toString()),
              _pdfStatBox('BIM', stats.bimCount.toString()),
              _pdfStatBox('Cert', stats.certCount.toString()),
              _pdfStatBox('Cacib', stats.cacibCount.toString()),
            ],
          ),
          pw.SizedBox(height: 12),

          // Title progress
          ...progression.titles.where((t) => !t.isInformational).map((title) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                children: [
                  pw.Text('${title.titleName}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    title.isComplete
                        ? 'Oppnådd ✓'
                        : '${title.current}/${title.required} (${title.remaining} gjenstår)',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Results table
          pw.Text('Alle resultater (${results.length})', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 22,
            headerHeight: 26,
            headers: ['Dato', 'Utstilling', 'Klasse', 'Premiegrad', 'CK', 'Plassering', 'Cert', 'Dommer'],
            data: results.map((r) => [
              dateFormat.format(r.date),
              r.showName,
              r.showClass,
              r.quality,
              r.gotCK ? 'CK' : '',
              r.placement ?? '',
              (r.certificates ?? []).join(', '),
              r.judge ?? '',
            ]).toList(),
          ),
        ],
      ),
    );

    final messenger = ScaffoldMessenger.of(context);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/utstillings_cv_${dog.name.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Utstillings-CV for ${dog.name}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Feil ved eksport: $e')),
      );
    }
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
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
                        tooltip: AppLocalizations.of(context)?.shareResultCard ?? 'Del resultatkort',
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
                        _buildChip('${AppLocalizations.of(context)?.classAbbrev ?? 'Kl'}: ${result.classPlacement}', AppColors.accent2),
                      if (result.hasCK)
                        _buildChip('CK', AppColors.success, icon: Icons.check_circle),
                      if (result.bestOfSexPlacement != null)
                        _buildChip('${widget.dog.gender == 'Male' ? (AppLocalizations.of(context)?.bestMaleAbbrev ?? 'BHK') : (AppLocalizations.of(context)?.bestFemaleAbbrev ?? 'BTK')}: ${result.bestOfSexPlacement}', AppColors.accent1),
                      if (result.placement != null)
                        _buildChip(result.placement!, _getPlacementColor(result.placement!)),
                      if (result.certificates != null)
                        ...result.certificates!.map((cert) => _buildChip(cert, AppColors.accent5)),
                      if (result.groupResult != null)
                        _buildChip(result.groupResult!, AppColors.warning, icon: Icons.groups),
                      if (result.groupJudge != null && result.groupJudge!.isNotEmpty)
                        _buildChip(AppLocalizations.of(context)?.groupJudgeWithName(result.groupJudge!) ?? 'Gruppedommer: ${result.groupJudge!}', AppColors.accent3, icon: Icons.person_outline),
                      if (result.bisResult != null)
                        _buildChip(result.bisResult!, AppColors.warning, icon: Icons.emoji_events),
                      if (result.bisJudge != null && result.bisJudge!.isNotEmpty)
                        _buildChip(AppLocalizations.of(context)?.bisJudgeWithName(result.bisJudge!) ?? 'BIS-dommer: ${result.bisJudge!}', AppColors.warning, icon: Icons.person_outline),
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
                  
                  // Utstillingsnavn (med autocomplete)
                  _buildAutocompleteField(
                    controller: _showNameController,
                    label: '${localizations?.showName ?? 'Utstillingsnavn'} *',
                    hint: localizations?.showNameHint ?? 'f.eks. NKK Drammen',
                    optionsFuture: ShowDataService().getShowNames(),
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
                      labelText: localizations?.country ?? 'Land',
                      border: const OutlineInputBorder(),
                      helperText: _isNordicCountry 
                          ? (localizations?.ckSystemAvailable ?? 'CK-systemet er tilgjengelig')
                          : (localizations?.ckOnlyNordic ?? 'CK er kun tilgjengelig i Norden'),
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
                  
                  // Dommer (med autocomplete)
                  _buildAutocompleteField(
                    controller: _judgeController,
                    label: localizations?.judge ?? 'Dommer',
                    hint: 'f.eks. Hans Hansen',
                    optionsFuture: ShowDataService().getJudgeNames(),
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
                          ? (localizations?.noPlacementWithQuality ?? 'Ingen plassering eller sertifikater tilgjengelig med denne premiegraden')
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
                          localizations?.hpAward ?? 'HP (Hederspris / Hopeful Puppy)',
                          style: TextStyle(
                            color: _quality == 'Særdeles lovende' ? null : context.colors.textDisabled,
                          ),
                        ),
                        subtitle: _quality != 'Særdeles lovende'
                            ? Text(
                                localizations?.requiresHighlyPromising ?? 'Krever Særdeles lovende',
                                style: TextStyle(color: context.colors.textDisabled, fontSize: 12),
                              )
                            : Text(
                                localizations?.qualifiesForBestPuppy ?? 'Kvalifiserer for beste hannvalp/tispevalp',
                                style: const TextStyle(fontSize: 12),
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
                              localizations?.requiresExcellent ?? 'Krever Excellent',
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
                              ? (localizations?.bestMalePuppy ?? 'Beste hannvalp')
                              : (localizations?.bestFemalePuppy ?? 'Beste tispevalp'))
                          : (widget.dogGender == 'Male' 
                              ? (localizations?.bestMalePlacement ?? 'Plassering beste hannhund (BHK)')
                              : (localizations?.bestFemalePlacement ?? 'Plassering beste tispe (BTK)')),
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_hasCK && _classPlacement == '1' ? (localizations?.qualifiedForBIRBIMPuppy ?? 'Kvalifisert for BIR/BIM Valp') : (localizations?.requiresFirstWithHP ?? 'Krever 1. plass med HP for å delta'))
                          : (_isNordicCountry && _bestOfSexPlacement != '1'
                              ? (localizations?.requiresBHKBTKFirstNordic ?? 'BHK/BTK 1 kreves for BIR/BIM i Norden')
                              : null),
                    ),
                    items: _isPuppyClass
                        ? [
                            DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'Ingen')),
                            DropdownMenuItem(value: '1', child: Text(localizations?.yesWon ?? 'Ja - Vant')),
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
                      labelText: _isPuppyClass ? (localizations?.birBimPuppy ?? 'BIR/BIM Valp') : 'BIR/BIM',
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_bestOfSexPlacement != '1' ? (localizations?.requiresBestPuppy ?? 'Krever å være beste hannvalp/tispevalp') : null)
                          : (!_isBIRBIMAvailable ? (localizations?.requiresBHKBTKFirstNordic ?? 'Krever BHK/BTK 1. plass i Norden') : null),
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
                          _buildAutocompleteField(
                            controller: _groupJudgeController,
                            label: localizations?.groupJudge ?? 'Gruppedommer',
                            hint: '',
                            optionsFuture: ShowDataService().getJudgeNames(),
                            filled: true,
                            prefixIcon: const Icon(Icons.person_outline),
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
                          _buildAutocompleteField(
                            controller: _bisJudgeController,
                            label: localizations?.bisJudge ?? 'BIS-dommer',
                            hint: '',
                            optionsFuture: ShowDataService().getJudgeNames(),
                            filled: true,
                            prefixIcon: const Icon(Icons.person_outline),
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

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Future<List<String>> optionsFuture,
    String? Function(String?)? validator,
    bool filled = false,
    Widget? prefixIcon,
  }) {
    return FutureBuilder<List<String>>(
      future: optionsFuture,
      builder: (context, snapshot) {
        final options = snapshot.data ?? [];
        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
            final query = textEditingValue.text.toLowerCase();

            // 1. Exact substring matches first
            final exactMatches = options
                .where((o) => o.toLowerCase().contains(query))
                .toList();

            // 2. Fuzzy matches (only if query is 3+ chars and few exact matches)
            if (query.length >= 3 && exactMatches.length < 5) {
              final fuzzyMatches = ShowDataService.findSimilarNames(
                textEditingValue.text,
                options,
                threshold: 0.6,
              );
              // Add fuzzy results that aren't already in exact matches
              for (final match in fuzzyMatches) {
                if (!exactMatches.contains(match.name)) {
                  exactMatches.add(match.name);
                }
              }
            }

            return exactMatches.take(10);
          },
          initialValue: controller.value,
          onSelected: (selection) {
            controller.text = selection;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            // Sync with our controller
            textController.text = controller.text;
            textController.addListener(() {
              if (controller.text != textController.text) {
                controller.text = textController.text;
              }
            });
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint.isEmpty ? null : hint,
                border: const OutlineInputBorder(),
                filled: filled,
                fillColor: filled ? context.colors.surface : null,
                prefixIcon: prefixIcon,
                suffixIcon: options.isNotEmpty
                    ? Icon(Icons.arrow_drop_down, color: context.colors.textCaption)
                    : null,
              ),
              validator: validator,
              onFieldSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, filteredOptions) {
            final query = controller.text;

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: AppRadius.smAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions.elementAt(index);
                      // Check if this is a fuzzy match (not an exact substring match)
                      final isFuzzyOnly = query.isNotEmpty &&
                          !option.toLowerCase().contains(query.toLowerCase());

                      return ListTile(
                        dense: true,
                        title: Text(
                          option,
                          style: isFuzzyOnly
                              ? TextStyle(fontStyle: FontStyle.italic, color: Colors.orange[800])
                              : null,
                        ),
                        trailing: isFuzzyOnly
                            ? Tooltip(
                                message: 'Lignende navn – mente du dette?',
                                child: Icon(Icons.help_outline, size: 16, color: Colors.orange[600]),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show a dialog when a similar name is found, letting the user choose
  /// the existing name or confirm their new spelling.
  Future<String?> _showSimilarNameDialog(String newName, List<SimilarNameMatch> matches, String fieldLabel) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.compare_arrows, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Lignende navn funnet', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'Du skrev ',
                children: [
                  TextSpan(
                    text: '"$newName"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ', men det finnes lignende navn.\nMente du ett av disse?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...matches.take(5).map((m) {
              final pct = (m.similarity * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    alignment: Alignment.centerLeft,
                    side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(m.name),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text('$pct%', style: TextStyle(fontSize: 12, color: context.colors.textCaption)),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                alignment: Alignment.centerLeft,
                side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              onPressed: () => Navigator.of(ctx).pop(newName),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Behold "$newName" (ny stavemåte)',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Avbryt'),
          ),
        ],
      ),
    );
  }

  /// Check a name against the existing list and show dialog if similar names exist.
  /// Returns the chosen name (original, existing match, or null if cancelled).
  Future<String?> _checkAndResolveName(String name, List<String> existingNames, String fieldLabel) async {
    if (name.trim().isEmpty) return name;
    final trimmed = name.trim();

    // If it's an exact match (case-insensitive), no need to check
    if (existingNames.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      return trimmed;
    }

    // Find similar names
    final matches = ShowDataService.findSimilarNames(trimmed, existingNames, threshold: 0.75);

    // Filter out exact normalized matches (those are handled automatically by addJudgeName)
    final fuzzyOnly = matches.where((m) => !m.isExactNormalized).toList();

    if (fuzzyOnly.isEmpty) return trimmed;

    // Show dialog
    return _showSimilarNameDialog(trimmed, fuzzyOnly, fieldLabel);
  }

  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;

    final box = Hive.box<ShowResult>('show_results');
    
    // Hent verdier fra controllers
    var showName = _showNameController.text.trim();
    var judge = _judgeController.text.trim().isEmpty ? null : _judgeController.text.trim();
    final critique = _critiqueController.text.trim().isEmpty ? null : _critiqueController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    var groupJudge = _groupJudgeController.text.trim().isEmpty ? null : _groupJudgeController.text.trim();
    var bisJudge = _bisJudgeController.text.trim().isEmpty ? null : _bisJudgeController.text.trim();

    // ── Check for similar names and let user resolve duplicates ──
    final judgeNames = await ShowDataService().getJudgeNames();
    final showNames = await ShowDataService().getShowNames();

    // Check judge name
    if (judge != null && judge.isNotEmpty) {
      final resolved = await _checkAndResolveName(judge, judgeNames, 'Dommer');
      if (resolved == null) return; // User cancelled
      judge = resolved;
      _judgeController.text = resolved;
    }

    // Check group judge name
    if (groupJudge != null && groupJudge.isNotEmpty) {
      final resolved = await _checkAndResolveName(groupJudge, judgeNames, 'Gruppedommer');
      if (resolved == null) return;
      groupJudge = resolved;
      _groupJudgeController.text = resolved;
    }

    // Check BIS judge name
    if (bisJudge != null && bisJudge.isNotEmpty) {
      final resolved = await _checkAndResolveName(bisJudge, judgeNames, 'BIS-dommer');
      if (resolved == null) return;
      bisJudge = resolved;
      _bisJudgeController.text = resolved;
    }

    // Check show name
    if (showName.isNotEmpty) {
      final resolved = await _checkAndResolveName(showName, showNames, 'Utstillingsnavn');
      if (resolved == null) return;
      showName = resolved;
      _showNameController.text = resolved;
    }
    
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

    // Save judge and show names to shared database for autocomplete
    try {
      if (showName.isNotEmpty) {
        ShowDataService().addShowName(showName);
      }
      if (judge != null && judge.isNotEmpty) {
        ShowDataService().addJudgeName(judge);
      }
      if (groupJudge != null && groupJudge.isNotEmpty) {
        ShowDataService().addJudgeName(groupJudge);
      }
      if (bisJudge != null && bisJudge.isNotEmpty) {
        ShowDataService().addJudgeName(bisJudge);
      }
    } catch (e) {
      AppLogger.debug('Error saving to shared DB: $e');
    }

    if (mounted) {
      // Capture scaffold/navigator/localizations before popping (context becomes invalid after pop)
      Dog? shareDog;
      ScaffoldMessengerState? scaffoldMessenger;
      NavigatorState? navigator;
      final localizations = AppLocalizations.of(context);
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

      // Prompt to share to Breedly feed (only for new results)
      if (shareDog != null && scaffoldMessenger != null && navigator != null) {
        final dog = shareDog;
        _showShareToFeedDialog(navigator, scaffoldMessenger, localizations, result, dog);
      }
    }
  }

  void _showShareToFeedDialog(
    NavigatorState navigator,
    ScaffoldMessengerState messenger,
    AppLocalizations? l10n,
    ShowResult result,
    Dog dog,
  ) {
    // Show the share dialog using the navigator's overlay context
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation1, animation2) {
          return _ShareToFeedDialogPage(
            result: result,
            dog: dog,
            l10n: l10n,
            onShared: () {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n?.feedPostPublished ?? 'Delt på Breedly!'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onSkipped: () {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n?.resultSaved ?? 'Resultat lagret!'),
                  action: SnackBarAction(
                    label: l10n?.shareResultCard ?? 'Del resultatkort',
                    onPressed: () {
                      navigator.push(
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
            },
          );
        },
      ),
    );
  }
}

/// Dialog page for sharing a show result to the Breedly feed
class _ShareToFeedDialogPage extends StatefulWidget {
  final ShowResult result;
  final Dog dog;
  final AppLocalizations? l10n;
  final VoidCallback onShared;
  final VoidCallback onSkipped;

  const _ShareToFeedDialogPage({
    required this.result,
    required this.dog,
    required this.l10n,
    required this.onShared,
    required this.onSkipped,
  });

  @override
  State<_ShareToFeedDialogPage> createState() => _ShareToFeedDialogPageState();
}

class _ShareToFeedDialogPageState extends State<_ShareToFeedDialogPage> {
  String _visibility = 'public';
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final result = widget.result;

    // Build result summary
    final parts = <String>[];
    parts.add(result.quality);
    if (result.hasCK) parts.add('CK');
    if (result.certificates != null) parts.addAll(result.certificates!);
    if (result.placement != null) parts.add(result.placement!);
    if (result.groupResult != null) parts.add(result.groupResult!);
    if (result.bisResult != null) parts.add(result.bisResult!);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.newspaper_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n?.feedShareTitle ?? 'Del på Breedly?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.dog.name} – ${result.showName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: parts.map((part) {
                          final isCert = part == 'CERT' || part == 'CACIB' || part == 'CK';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCert
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : context.colors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              part,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isCert ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Visibility selector
                Text(
                  l10n?.feedVisibility ?? 'Synlighet',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _VisibilityOption(
                        icon: Icons.public,
                        label: l10n?.feedPublic ?? 'Alle',
                        isSelected: _visibility == 'public',
                        onTap: () => setState(() => _visibility = 'public'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VisibilityOption(
                        icon: Icons.lock_outline,
                        label: l10n?.feedFollowersOnly ?? 'Kun følgere',
                        isSelected: _visibility == 'followersOnly',
                        onTap: () => setState(() => _visibility = 'followersOnly'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isPublishing
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onSkipped();
                            },
                      child: Text(l10n?.feedSkip ?? 'Hopp over'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isPublishing ? null : _publishToFeed,
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(l10n?.feedPublish ?? 'Del'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publishToFeed() async {
    setState(() => _isPublishing = true);

    try {
      final userId = AuthService().currentUserId ?? '';
      final kennelId = KennelService().activeKennelId ?? userId;

      // Get kennel name
      String kennelName = 'Ukjent kennel';
      try {
        final kennelBox = Hive.box<Kennel>('kennel');
        final kennel = kennelBox.values.firstOrNull;
        if (kennel != null) kennelName = kennel.name;
      } catch (_) {}

      final post = FeedPost.fromShowResult(
        id: const Uuid().v4(),
        authorId: userId,
        kennelId: kennelId,
        kennelName: kennelName,
        breed: widget.dog.breed,
        dogName: widget.dog.name,
        showName: widget.result.showName,
        showDate: widget.result.date,
        quality: widget.result.quality,
        showClass: widget.result.showClass,
        placement: widget.result.placement,
        certificates: widget.result.certificates,
        judge: widget.result.judge,
        groupResult: widget.result.groupResult,
        bisResult: widget.result.bisResult,
        hasCK: widget.result.hasCK,
        visibility: _visibility,
      );

      await FeedService().publishPost(post);

      if (mounted) {
        Navigator.pop(context);
        widget.onShared();
      }
    } catch (e) {
      AppLogger.error('Failed to publish to feed', e);
      setState(() => _isPublishing = false);
    }
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.colors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : context.colors.textCaption,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
