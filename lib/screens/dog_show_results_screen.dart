import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:peddex/utils/app_theme.dart';
import 'package:peddex/utils/theme_colors.dart';
import 'package:peddex/models/dog.dart';
import 'package:peddex/models/show_result.dart';
import 'package:peddex/utils/app_bar_builder.dart';
import 'package:peddex/utils/page_info_helper.dart';
import 'package:peddex/services/auth_service.dart';
import 'package:peddex/services/cloud_sync_service.dart';
import 'package:peddex/services/feed_service.dart';
import 'package:peddex/models/feed_post.dart';
import 'package:peddex/utils/logger.dart';
import 'package:peddex/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:peddex/widgets/show_result_card.dart';
import 'package:peddex/services/show_data_service.dart';
import 'package:peddex/services/show_import_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:peddex/widgets/peddex_async_wrapper.dart';
import 'package:peddex/utils/performance_telemetry.dart';

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
  String? _filterCountry;
  List<ShowResult> _allResults = [];
  late Future<void> _resultsFuture;
  ShowStatistics? _memoizedStats;
  int _memoizedStatsHash = 0;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _loadResults();
  }

  Future<void> _loadResults() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;
    final snapshot = await FirestoreService()
        .baseQuery('show_results', userId)
        .where('dogId', isEqualTo: widget.dog.id)
        .get();
    if (!mounted) return;
    setState(() {
      _allResults = _uniqueResults(
        snapshot.docs
            .map((d) => ShowResult.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );
      _memoizedStats = null;
      _memoizedStatsHash = 0;
    });
  }

  int _statsHash(List<ShowResult> results) {
    return Object.hashAll(
      results.map((r) => Object.hash(r.id, r.updatedAt?.millisecondsSinceEpoch)),
    );
  }

  ShowStatistics _getMemoizedStats(List<ShowResult> results) {
    final statsTimer = Stopwatch()..start();
    final hash = _statsHash(results);
    if (_memoizedStats != null && _memoizedStatsHash == hash) {
      statsTimer.stop();
      PerformanceTelemetry.trackElapsed(
        key: 'showStatsMemoizedMs',
        stopwatch: statsTimer,
        logLabel: 'Memoized stats',
      );
      return _memoizedStats!;
    }
    _memoizedStats = ShowStatistics.fromResults(results);
    _memoizedStatsHash = hash;
    statsTimer.stop();
    PerformanceTelemetry.trackElapsed(
      key: 'showStatsMemoizedMs',
      stopwatch: statsTimer,
      logLabel: 'Memoized stats',
    );
    return _memoizedStats!;
  }

  void _retryLoadResults() {
    setState(() {
      _resultsFuture = _loadResults();
    });
  }

  /// Returns deduplicated results for [dogId], newest first.
  /// First deduplicates by UUID (one entry per id), preferring the richer copy.
  /// Then deduplicates by (date + showName) so Firebase duplicates with
  /// different UUIDs never appear twice on screen.
  List<ShowResult> _uniqueResults(List<ShowResult> source) {
    // Pass 1: by UUID — exclude soft-deleted items (they appear in Trash)
    final byId = <String, ShowResult>{};
    for (final r in source.where((r) => r.dogId == widget.dog.id && !r.isDeleted)) {
      final existing = byId[r.id];
      if (existing == null) {
        byId[r.id] = r;
      } else {
        if (_richness(r) > _richness(existing)) byId[r.id] = r;
      }
    }
    // Pass 2: by (date + showName) — catches different-UUID duplicates
    final bySig = <String, ShowResult>{};
    for (final r in byId.values) {
      final sig =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}|${r.showName.trim().toLowerCase()}';
      final existing = bySig[sig];
      if (existing == null) {
        bySig[sig] = r;
      } else {
        if (_richness(r) > _richness(existing)) bySig[sig] = r;
      }
    }
    return bySig.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  int _richness(ShowResult r) => [
        r.place, r.showType, r.judge, r.classPlacement,
        r.placement, r.groupResult, r.bisResult, r.notes,
      ].where((v) => v != null && v.toString().isNotEmpty).length +
      (r.certificates?.length ?? 0) +
      (r.hasCK ? 1 : 0);

  List<int> _getAvailableYears() {
    final years = _allResults
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
      if (_filterCountry != null && (r.country ?? '') != _filterCountry) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _filterYear != null || _filterShowType != null || _filterJudge != null || _filterQuality != null || _filterCountry != null;

  void _clearFilters() {
    setState(() {
      _filterYear = null;
      _filterShowType = null;
      _filterJudge = null;
      _filterQuality = null;
      _filterCountry = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBarBuilder.buildAppBar(
          title: '${localizations?.exhibitions ?? 'Exhibitions'} - ${widget.dog.name}',
          context: context,
          actions: [
            // Import show results button
            IconButton(
              icon: const Icon(LucideIcons.fileInput),
              tooltip: localizations?.importShowResults ?? 'Import show results',
              onPressed: () => _showImportDialog(context),
            ),
            // PDF Export button
            IconButton(
              icon: const Icon(LucideIcons.fileText),
              tooltip: localizations?.exportShowCV ?? 'Export show CV',
              onPressed: () => _exportShowCV(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical),
              onSelected: (value) {
                if (value == 'delete_all') _deleteAllResults();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        localizations?.deleteAllResults ?? 'Delete all results',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            PageInfoHelper.buildInfoButton(
              context,
              title: localizations?.exhibitionResults ?? 'Exhibition results',
              description: localizations?.exhibitionResultsDesc(widget.dog.name) ?? 'Here you can register and track all show results for ${widget.dog.name}.',
              features: [
                PageInfoItem(
                  icon: LucideIcons.plusCircle,
                  title: localizations?.registerResults ?? 'Register results',
                  description: localizations?.registerResultsDesc ?? 'Add results from shows',
                  color: AppColors.info,
                ),
                PageInfoItem(
                  icon: LucideIcons.barChart,
                  title: localizations?.showStatistics ?? 'Statistics',
                  description: localizations?.showStatisticsDesc ?? 'View statistics for BIR, BIM, group and BIS results',
                  color: AppColors.success,
                ),
                PageInfoItem(
                  icon: LucideIcons.fileText,
                  title: localizations?.critique ?? 'Critique',
                  description: localizations?.critiqueDesc ?? 'Save judge critique for each show',
                  color: AppColors.warning,
                ),
              ],
              tip: localizations?.showResultTip ?? 'If the dog wins BIR, you can add a group result. If it wins the group (BIG1), you can add a BIS result.',
            ),
          ],
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: context.colors.textMuted,
            indicatorWeight: 3,
            tabs: [
              Tab(text: localizations?.results ?? 'Results'),
              Tab(text: localizations?.statistics ?? 'Statistics'),
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
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    final localizations = AppLocalizations.of(context);
    return FutureBuilder<void>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        return PeddexAsyncWrapper<void>(
          snapshot: snapshot,
          loadingMessage: 'Loading show results...',
          errorTitle: 'Error loading show results',
          emptyTitle: localizations?.noShowResults ?? 'No show results yet',
          onRetry: _retryLoadResults,
          isEmpty: (_) => _allResults.isEmpty,
          dataBuilder: (_) => _buildResultsTabContent(),
        );
      },
    );
  }

  Widget _buildResultsTabContent() {
    final localizations = AppLocalizations.of(context);
    final allResults = _allResults;
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
                      Icon(
                        LucideIcons.filterX,
                        size: 48,
                        color: context.colors.textDisabled,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        localizations?.noResultsMatchFilter ??
                            'No results match the filter',
                        style: TextStyle(color: context.colors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _clearFilters,
                        child:
                            Text(localizations?.clearFilters ?? 'Clear filter'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.sm,
                    bottom: 80,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      _buildResultCard(results[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<ShowResult> allResults) {
    final localizations = AppLocalizations.of(context);
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
    final countries = allResults
        .where((r) => r.country != null && r.country!.isNotEmpty)
        .map((r) => r.country!)
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
            Icon(LucideIcons.filter, size: 18, color: context.colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            // Year filter
            _buildFilterDropdown<int?>(
              label: _filterYear?.toString() ?? (localizations?.year ?? 'Year'),
              isActive: _filterYear != null,
              items: [null, ...years],
              itemLabel: (v) => v?.toString() ?? (localizations?.allYears ?? 'All years'),
              onSelected: (v) => setState(() => _filterYear = v),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Show type filter
            if (showTypes.isNotEmpty)
              _buildFilterDropdown<String?>(
                label: _filterShowType ?? (localizations?.type ?? 'Type'),
                isActive: _filterShowType != null,
                items: [null, ...showTypes],
                itemLabel: (v) => v ?? (localizations?.allTypes ?? 'All types'),
                onSelected: (v) => setState(() => _filterShowType = v),
              ),
            const SizedBox(width: AppSpacing.sm),
            // Judge filter
            if (judges.isNotEmpty)
              _buildFilterDropdown<String?>(
                label: _filterJudge ?? (localizations?.judge ?? 'Judge'),
                isActive: _filterJudge != null,
                items: [null, ...judges],
                itemLabel: (v) => v ?? (localizations?.allJudgesFilter ?? 'All judges'),
                onSelected: (v) => setState(() => _filterJudge = v),
              ),
            const SizedBox(width: AppSpacing.sm),
            // Country filter
            if (countries.isNotEmpty)
              _buildFilterDropdown<String?>(
                label: _filterCountry ?? (localizations?.country ?? 'Country'),
                isActive: _filterCountry != null,
                items: [null, ...countries],
                itemLabel: (v) => v ?? (localizations?.allCountries ?? 'All countries'),
                onSelected: (v) => setState(() => _filterCountry = v),
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
                      Icon(LucideIcons.x, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(localizations?.resetFilters ?? 'Reset', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
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
              LucideIcons.chevronDown,
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
                          result.place != null
                              ? '${dateFormat.format(result.date)}  •  ${result.place}'
                              : dateFormat.format(result.date),
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
                    _buildChip('${AppLocalizations.of(context)?.classAbbrev ?? 'Cl'}: ${result.classPlacement}', AppColors.accent2),
                  if (result.hasCK)
                    _buildChip('CK', AppColors.success, icon: LucideIcons.checkCircle),
                  if (result.bestOfSexPlacement != null)
                    _buildChip('${AppLocalizations.of(context)?.bestOfSexAbbrev ?? 'BOS'}: ${result.bestOfSexPlacement}', AppColors.accent1),
                  if (result.placement != null &&
                      !RegExp(r'^\d(BHK|BTK)$', caseSensitive: false)
                          .hasMatch(result.placement!))
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
                      _buildChip(result.groupResult!, AppColors.warning, icon: LucideIcons.users),
                    if (result.bisResult != null)
                      _buildChip(result.bisResult!, AppColors.warning, icon: LucideIcons.trophy),
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
      badges.add(_buildBadge(LucideIcons.trophy, AppColors.warning));
    } else if (result.groupResult != null) {
      badges.add(_buildBadge(LucideIcons.users, AppColors.warning));
    } else if (result.isBIR) {
      badges.add(_buildBadge(LucideIcons.star, Theme.of(context).primaryColor));
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
    final results = _allResults;

    if (results.isEmpty) {
      return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.barChart,
                  size: 64,
                  color: context.colors.textDisabled,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizations?.noStatisticsAvailable ?? 'No statistics available',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ],
            ),
          );
    }

    final stats = _getMemoizedStats(results);

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
              _buildCertificatesByCountryCard(results),
              const SizedBox(height: AppSpacing.lg),
              _buildJudgesCard(stats, results),
            ],
          ),
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
                Icon(LucideIcons.lineChart, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.overview ?? 'Overview',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(localizations?.exhibitions ?? 'Exhibitions', stats.totalShows.toString(), LucideIcons.calendar),
                ),
                Expanded(
                  child: _buildStatItem('CK', stats.ckCount.toString(), LucideIcons.checkCircle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              localizations?.quality ?? 'Quality grades',
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
        ? (localizations?.bestMaleDog ?? 'Best male dog (BHK)')
        : (localizations?.bestFemaleDog ?? 'Best female dog (BTK)');
    
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
                Icon(LucideIcons.listOrdered, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.classPlacements ?? 'Class placements',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Text(
              localizations?.classPlacement ?? 'Class placement',
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
                Icon(LucideIcons.star, color: Theme.of(context).primaryColor),
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
                Icon(LucideIcons.trophy, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.groupAndBIS ?? 'Group & BIS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Text(
              localizations?.groupFinals ?? 'Group finals',
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

  // ignore: unused_element
  Widget _buildCertificatesCard(ShowStatistics stats) {
    // Collect all certificates from results to show actual data
    final results = _allResults;
    
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
                  Icon(LucideIcons.award, color: Theme.of(context).primaryColor),
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
                  AppLocalizations.of(context)?.noCertCacibYet ?? 'No Cert/Cacib yet',
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
                Icon(LucideIcons.award, color: Theme.of(context).primaryColor),
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
                Icon(LucideIcons.user, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  localizations?.judges ?? 'Judges',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  localizations?.judgesCount(judges.length) ?? '${judges.length} judges',
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
                  child: Text(localizations?.seeAllJudges(judges.length) ?? 'See all ${judges.length} judges'),
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
                        ? (localizations?.exhibitionCount(judge.showCount) ?? '${judge.showCount} exhibition')
                        : (localizations?.exhibitionsCount(judge.showCount) ?? '${judge.showCount} exhibitions'),
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
            const Icon(LucideIcons.chevronRight, color: AppColors.neutral500),
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
                          AppLocalizations.of(context)?.judgeStatsSummary(judge.showCount, judge.excellentCount, judge.ckCount) ?? '${judge.showCount} exhibitions • ${judge.excellentCount} Excellent • ${judge.ckCount} CK',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
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
                  Icon(LucideIcons.user, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${AppLocalizations.of(context)?.allJudges ?? 'All judges'} (${judges.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
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

  // ──── CERTIFICATES BY COUNTRY CARD ────

  Widget _buildCertificatesByCountryCard(List<ShowResult> results) {
    final l10n = AppLocalizations.of(context);
    final unknownLabel = l10n?.unknown ?? 'Unknown';

    // Build map: certName (lower) → {country → count}
    final Map<String, Map<String, int>> certByCountry = {};
    for (final r in results) {
      final country = (r.country?.isNotEmpty == true) ? r.country! : unknownLabel;
      for (final cert in r.certificates ?? <String>[]) {
        final key = cert.toLowerCase();
        certByCountry.putIfAbsent(key, () => {})[country] =
            (certByCountry[key]?[country] ?? 0) + 1;
      }
    }

    // Helper: get per-country map for a cert type
    Map<String, int> cc(String certName) =>
        certByCountry[certName.toLowerCase()] ?? {};

    int total(List<String> names) => names
        .expand((n) => cc(n).values)
        .fold(0, (a, b) => a + b);

    final primary = Theme.of(context).primaryColor;
    final juniorTotal = total(['Junior Cert', 'Nordisk Junior Cert', 'Junior Cacib']);
    final veteranTotal = total(['Veteran Cert', 'Nordisk Veteran Cert', 'Veteran Cacib']);
    final hasAnyCert = total([
      'Cert', 'Res.Cert', 'Cacib', 'Res.Cacib', 'Nordisk Cert', 'Res.Nordisk Cert',
      'Junior Cert', 'Nordisk Junior Cert', 'Junior Cacib',
      'Veteran Cert', 'Nordisk Veteran Cert', 'Veteran Cacib',
    ]) > 0;

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
                Icon(LucideIcons.award, color: primary),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n?.certificates ?? 'Certificates', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            if (!hasAnyCert)
              Center(
                child: Text(l10n?.noCertificates ?? 'No certificates yet', style: TextStyle(color: context.colors.textMuted)),
              )
            else ...[
              _certSectionHeader(l10n?.national ?? 'National', LucideIcons.flag, primary),
              const SizedBox(height: AppSpacing.sm),
              _certRow('Cert', cc('Cert'), const Color(0xFF2E7D32)),
              _certRow('Res. Cert', cc('Res.Cert'), const Color(0xFF66BB6A)),
              const SizedBox(height: AppSpacing.lg),

              _certSectionHeader(l10n?.international ?? 'International', LucideIcons.globe, const Color(0xFFB8860B)),
              const SizedBox(height: AppSpacing.sm),
              _certRow('CACIB', cc('Cacib'), const Color(0xFFD4A017)),
              _certRow('Res. CACIB', cc('Res.Cacib'), const Color(0xFFE8C547)),
              const SizedBox(height: AppSpacing.lg),

              _certSectionHeader(l10n?.nordic ?? 'Nordic', LucideIcons.compass, const Color(0xFF1565C0)),
              const SizedBox(height: AppSpacing.sm),
              _certRow('Nordic Cert', cc('Nordisk Cert'), const Color(0xFF1976D2)),
              _certRow('Res. Nordic Cert', cc('Res.Nordisk Cert'), const Color(0xFF64B5F6)),

              if (juniorTotal > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                _certSectionHeader(l10n?.juniorCertificates ?? 'Junior', LucideIcons.zap, const Color(0xFF00796B)),
                const SizedBox(height: AppSpacing.sm),
                _certRow('Junior Cert', cc('Junior Cert'), const Color(0xFF00897B)),
                _certRow('Nordic Junior Cert', cc('Nordisk Junior Cert'), const Color(0xFF4DB6AC)),
                _certRow('Junior CACIB', cc('Junior Cacib'), const Color(0xFFD4A017)),
              ],

              if (veteranTotal > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                _certSectionHeader(l10n?.veteranCertificates ?? 'Veteran', LucideIcons.shieldCheck, const Color(0xFF6A1B9A)),
                const SizedBox(height: AppSpacing.sm),
                _certRow('Veteran Cert', cc('Veteran Cert'), const Color(0xFF7B1FA2)),
                _certRow('Nordic Veteran Cert', cc('Nordisk Veteran Cert'), const Color(0xFFBA68C8)),
                _certRow('Veteran CACIB', cc('Veteran Cacib'), const Color(0xFFD4A017)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Section header for each certificate group
  Widget _certSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.2), thickness: 1)),
      ],
    );
  }

  /// One row: cert label | per-country chips | total count badge
  /// Returns empty if no certificates of this type were earned.
  Widget _certRow(String label, Map<String, int> byCountry, Color color) {
    final total = byCountry.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sortedEntries = byCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: sortedEntries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    '${e.key} ×${e.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              total.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──── PDF EXPORT ────

  /*
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
                    isComplete ? LucideIcons.trophy : LucideIcons.medal,
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
                            Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
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
                  ? '✓ ${AppLocalizations.of(context)?.titleAchieved ?? 'Title achieved!'}'
                  : (AppLocalizations.of(context)?.remainingProgress(title.remaining, title.description) ?? '${title.remaining} remaining — ${title.description}'),
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
                  Icon(LucideIcons.lock, size: 14, color: AppColors.warning),
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
                    Icon(LucideIcons.info, size: 13, color: AppColors.warning),
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
                              ? LucideIcons.checkCircle
                              : LucideIcons.clipboardList,
                          size: 16,
                          color: title.tilleggskravCompleted
                              ? AppColors.success
                              : Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.additionalRequirementWithType(title.tilleggskrav!.kravType) ?? 'Additional requirement (${title.tilleggskrav!.kravType})',
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
                              final userId = AuthService().currentUserId;
                              if (userId != null) {
                                await FirestoreService().saveDog(
                                  userId: userId,
                                  dogId: widget.dog.id,
                                  dogData: widget.dog.toJson(),
                                );
                              }
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
                        '✓ ${AppLocalizations.of(context)?.additionalRequirementFulfilled ?? 'Additional requirement fulfilled'}',
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
  */

  /*
  Widget _buildInfoStatCard(TitleProgress title) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      child: ListTile(
        leading: Icon(LucideIcons.info, color: Theme.of(context).primaryColor),
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
  */

  /*
  Widget _buildTrendGraph_DELETE_ME(List<ShowResult> sortedResults) {
    final primaryColor = Theme.of(context).primaryColor;
    // DELETE MARKER START
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
                  Icon(LucideIcons.lineChart, color: primaryColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppLocalizations.of(context)?.resultTrend ?? 'Result trend', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context)?.minTwoResultsForTrend ?? 'At least 2 results required to show trend',
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
                Icon(LucideIcons.lineChart, color: primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(AppLocalizations.of(context)?.resultTrend ?? 'Result trend', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context)?.trendScoreDescription ?? 'Score based on quality grade, CK, BIR/BIM, group and BIS',
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
  */

  Future<void> _exportShowCV(BuildContext context) async {
    final results = [..._allResults]..sort((a, b) => b.date.compareTo(a.date));

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.noResultsToExport ?? 'No results to export')),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final stats = _getMemoizedStats(results);
    // Title progression feature is currently disabled.
    // final progression = ShowDataService().getTitleProgression(results, dogDateOfBirth: widget.dog.dateOfBirth, dogBreed: widget.dog.breed, tilleggskravCompleted: widget.dog.tilleggskravCompleted);
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
              l10n?.showCV ?? 'Show CV',
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
              '${dog.breed} • ${dog.gender == 'Male' ? (l10n?.male ?? 'Male') : (l10n?.female ?? 'Female')} • ${l10n?.bornLabel ?? 'Born:'} ${dateFormat.format(dog.dateOfBirth)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          if (dog.registrationNumber != null && dog.registrationNumber!.isNotEmpty)
            pw.Center(
              child: pw.Text(
                '${l10n?.regNoLabel ?? 'Reg. no:'} ${dog.registrationNumber}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Statistics summary
          pw.Text(l10n?.statistics ?? 'Statistics', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _pdfStatBox(l10n?.exhibitions ?? 'Exhibitions', stats.totalShows.toString()),
              _pdfStatBox('CK', stats.ckCount.toString()),
              _pdfStatBox('BIR', stats.birCount.toString()),
              _pdfStatBox('BIM', stats.bimCount.toString()),
              _pdfStatBox('Cert', stats.certCount.toString()),
              _pdfStatBox('Cacib', stats.cacibCount.toString()),
            ],
          ),
          pw.SizedBox(height: 12),

        // Title progress feature is currently disabled.
        /*
        // Title progress
        ...progression.titles.where((t) => !t.isInformational).map((title) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Text('${title.titleName}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text(
                  title.isComplete
                      ? (l10n?.pdfAchieved ?? 'Achieved ✓')
                      : (l10n?.pdfRemainingProgress(title.current, title.required, title.remaining) ?? '${title.current}/${title.required} (${title.remaining} remaining)'),
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        }),
        */
          pw.SizedBox(height: 12),

          // Results table
          pw.Text(l10n?.allResultsCount(results.length) ?? 'All results (${results.length})', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 22,
            headerHeight: 26,
            headers: [l10n?.date ?? 'Date', l10n?.showName ?? 'Show name', l10n?.showClass ?? 'Class', l10n?.quality ?? 'Quality grade', 'CK', l10n?.placement ?? 'Placement', 'Cert', l10n?.judge ?? 'Judge'],
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
      final pdfBytes = await pdf.save();
      final fileName = 'show_cv_${dog.name.replaceAll(' ', '_')}.pdf';

      if (kIsWeb) {
        // On web: open browser print/save dialog via the printing package
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: fileName,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (!mounted) return;
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          text: l10n?.showCVFor(dog.name) ?? 'Show CV for ${dog.name}',
        ));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.exportError(e.toString()) ?? 'Error exporting: $e')),
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
        dog: widget.dog,
        dogId: widget.dog.id,
        dogGender: widget.dog.gender,
        onSaved: _loadResults,
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShowResultsImportSheet(
        dogId: widget.dog.id,
        onImported: _loadResults,
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
                        icon: Icon(LucideIcons.share2, color: AppColors.info),
                        tooltip: AppLocalizations.of(context)?.shareResultCard ?? 'Share result card',
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
                        icon: const Icon(LucideIcons.pencil),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditResultDialog(result);
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                        onPressed: () => _deleteResult(result),
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(result.date),
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                  if (result.place != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: context.colors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          result.place!,
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (result.judge != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppLocalizations.of(context)?.judge ?? 'Judge'}: ${result.judge}',
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppLocalizations.of(context)?.result ?? 'Result',
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
                        _buildChip('${AppLocalizations.of(context)?.classAbbrev ?? 'Cl'}: ${result.classPlacement}', AppColors.accent2),
                      if (result.hasCK)
                        _buildChip('CK', AppColors.success, icon: LucideIcons.checkCircle),
                      if (result.bestOfSexPlacement != null)
                        _buildChip('${widget.dog.gender == 'Male' ? (AppLocalizations.of(context)?.bestMaleAbbrev ?? 'BM') : (AppLocalizations.of(context)?.bestFemaleAbbrev ?? 'BF')}: ${result.bestOfSexPlacement}', AppColors.accent1),
                      if (result.placement != null &&
                          !RegExp(r'^\d(BHK|BTK)$', caseSensitive: false)
                              .hasMatch(result.placement!))
                        _buildChip(result.placement!, _getPlacementColor(result.placement!)),
                      if (result.certificates != null)
                        ...result.certificates!.map((cert) => _buildChip(cert, AppColors.accent5)),
                      if (result.groupResult != null)
                        _buildChip(result.groupResult!, AppColors.warning, icon: LucideIcons.users),
                      if (result.groupJudge != null && result.groupJudge!.isNotEmpty)
                        _buildChip(AppLocalizations.of(context)?.groupJudgeWithName(result.groupJudge!) ?? 'Group judge: ${result.groupJudge!}', AppColors.accent3, icon: LucideIcons.user),
                      if (result.bisResult != null)
                        _buildChip(result.bisResult!, AppColors.warning, icon: LucideIcons.trophy),
                      if (result.bisJudge != null && result.bisJudge!.isNotEmpty)
                        _buildChip(AppLocalizations.of(context)?.bisJudgeWithName(result.bisJudge!) ?? 'BIS judge: ${result.bisJudge!}', AppColors.warning, icon: LucideIcons.user),
                    ],
                  ),
                  if (result.critique != null && result.critique!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppLocalizations.of(context)?.critique ?? 'Critique',
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
                      AppLocalizations.of(context)?.ownNotes ?? 'Notes',
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
        dog: widget.dog,
        dogId: widget.dog.id,
        dogGender: widget.dog.gender,
        existingResult: result,
        onSaved: _loadResults,
      ),
    );
  }

  Future<void> _deleteAllResults() async {
    final localizations = AppLocalizations.of(context);
    final dogResults = _allResults.where((r) => !r.isDeleted).toList();

    if (dogResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noResultsToDelete ?? 'No results to delete.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteAllResults ?? 'Delete all results'),
        content: Text(
          localizations?.moveAllResultsToTrash(dogResults.length, widget.dog.name) ?? 'Move all ${dogResults.length} show results for ${widget.dog.name} to trash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(localizations?.moveToTrash ?? 'Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final userId = AuthService().currentUserId;

    for (final result in dogResults) {
      if (userId != null) {
        try {
          await FirestoreService().deleteShowResult(
            userId: userId,
            showResultId: result.id,
          );
        } catch (e) {
          AppLogger.debug('Error soft-deleting show result: $e');
        }
      }
    }

    if (mounted) {
      _retryLoadResults();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.resultsMovedToTrash(dogResults.length) ?? '${dogResults.length} results moved to trash.'),
        ),
      );
    }
  }

  Future<void> _deleteResult(ShowResult result) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteResult ?? 'Delete result'),
        content: Text(
          localizations?.confirmDeleteResult(result.showName) ??
          'Move result from ${result.showName} to trash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(localizations?.delete ?? 'Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);

      // Sync soft-delete to Firestore
      try {
        final userId = AuthService().currentUserId;
        if (userId != null) {
          await FirestoreService().deleteShowResult(
            userId: userId,
            showResultId: result.id,
          );
        }
      } catch (e) {
        AppLogger.debug('Error syncing show result deletion: $e');
      }
      _retryLoadResults();
    }
  }
}

class _AddShowResultSheet extends StatefulWidget {
  final Dog dog;
  final String dogId;
  final String dogGender; // 'Male' eller 'Female'
  final ShowResult? existingResult;
  final VoidCallback onSaved;

  const _AddShowResultSheet({
    required this.dog,
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
  late TextEditingController _placeController;
  
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
  
  // Alle land — Nordiske land øverst, deretter FCI Europa + tillegg alfabetisk
  static const List<String> _countries = [
    // Nordiske land
    'Norge',
    'Sverige',
    'Danmark',
    'Finland',
    'Island',
    // Øvrige FCI Europa + tillegg
    'Albania',
    'Armenia',
    'Aserbajdsjan',
    'Belgia',
    'Bosnia-Hercegovina',
    'Bulgaria',
    'Estland',
    'Frankrike',
    'Georgia',
    'Gibraltar',
    'Hellas',
    'Hviterussland',
    'Irland',
    'Israel',
    'Italia',
    'Kasakhstan',
    'Kirgisistan',
    'Kosovo',
    'Kroatia',
    'Kypros',
    'Latvia',
    'Libanon',
    'Litauen',
    'Luxembourg',
    'Malta',
    'Moldova',
    'Monaco',
    'Montenegro',
    'Nederland',
    'Nord-Makedonia',
    'Polen',
    'Portugal',
    'Romania',
    'Russland',
    'San Marino',
    'Serbia',
    'Slovakia',
    'Slovenia',
    'Spania',
    'Storbritannia',
    'Sveits',
    'Tsjekkia',
    'Tyrkia',
    'Tyskland',
    'Ukraina',
    'Ungarn',
    'Usbekistan',
    'Østerrike',
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
    _placeController = TextEditingController();
    
    if (widget.existingResult != null) {
      _selectedDate = widget.existingResult!.date;
      _showNameController.text = widget.existingResult!.showName;
      _judgeController.text = widget.existingResult!.judge ?? '';
      _showClass = widget.existingResult!.showClass;
      _quality = widget.existingResult!.quality;
      _classPlacement = widget.existingResult!.classPlacement;
      // Migrate legacy placement values ('2BHK','3BHK','4BHK','2BTK','3BTK','4BTK')
      // that were stored in the placement field before bestOfSexPlacement existed.
      final rawPlacement = widget.existingResult!.placement;
      final legacyBosMatch = RegExp(
        r'^(\d)(BHK|BTK)$',
        caseSensitive: false,
      ).firstMatch(rawPlacement ?? '');
      if (legacyBosMatch != null) {
        // Prefer the dedicated field if already set; otherwise migrate the legacy value.
        _bestOfSexPlacement =
            widget.existingResult!.bestOfSexPlacement ?? legacyBosMatch.group(1);
        _placement = null;
      } else {
        _placement = rawPlacement;
        _bestOfSexPlacement = widget.existingResult!.bestOfSexPlacement;
      }
      _selectedCertificates = widget.existingResult!.certificates != null
          ? List<String>.from(widget.existingResult!.certificates!)
          : [];
      _groupResult = widget.existingResult!.groupResult;
      _bisResult = widget.existingResult!.bisResult;
      _groupJudgeController.text = widget.existingResult!.groupJudge ?? '';
      _bisJudgeController.text = widget.existingResult!.bisJudge ?? '';
      _critiqueController.text = widget.existingResult!.critique ?? '';
      _notesController.text = widget.existingResult!.notes ?? '';
      _placeController.text = widget.existingResult!.place ?? '';
      _showType = widget.existingResult!.showType;
      _hasCK = widget.existingResult!.hasCK;
      _selectedCountry = widget.existingResult!.country ?? 'Norge';
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
    _placeController.dispose();
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
                      ? (localizations?.editResult ?? 'Edit result')
                      : (localizations?.addResult ?? 'Add result'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
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
                    leading: Icon(LucideIcons.calendar, color: Theme.of(context).primaryColor),
                    title: Text(localizations?.date ?? 'Date'),
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
                    label: '${localizations?.showName ?? 'Show name'} *',
                    hint: localizations?.showNameHint ?? 'e.g. NKK Drammen',
                    optionsFuture: ShowDataService().getShowNames(),
                    validator: (value) => value?.isEmpty ?? true ? (localizations?.required ?? 'Required') : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sted
                  TextFormField(
                    controller: _placeController,
                    decoration: InputDecoration(
                      labelText: 'Place',
                      hintText: 'e.g. Drammen, Oslo Spektrum',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(LucideIcons.mapPin),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Utstillingstype
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _showType,
                    decoration: InputDecoration(
                      labelText: localizations?.showType ?? 'Show type',
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
                      labelText: localizations?.country ?? 'Country',
                      border: const OutlineInputBorder(),
                      helperText: _isNordicCountry 
                          ? (localizations?.ckSystemAvailable ?? 'CK system is available')
                          : (localizations?.ckOnlyNordic ?? 'CK is only available in Nordic countries'),
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
                    label: localizations?.judge ?? 'Judge',
                    hint: localizations?.judgeHint ?? 'e.g. Hans Hansen',
                    optionsFuture: ShowDataService().getJudgeNames(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Klasse
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey('class_$_showType'), // Force rebuild når showType endres
                    initialValue: _availableShowClasses.contains(_showClass) ? _showClass : _availableShowClasses.first,
                    decoration: InputDecoration(
                      labelText: '${localizations?.showClass ?? 'Class'} *',
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
                      labelText: '${localizations?.quality ?? 'Quality grade'} *',
                      border: const OutlineInputBorder(),
                      helperText: _isQualityLocking 
                          ? (localizations?.noPlacementWithQuality ?? 'No placement or certificates available with this quality grade')
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
                      labelText: localizations?.classPlacement ?? 'Class placement',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'None')),
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
                          localizations?.hpAward ?? 'HP (Hopeful Puppy)',
                          style: TextStyle(
                            color: _quality == 'Særdeles lovende' ? null : context.colors.textDisabled,
                          ),
                        ),
                        subtitle: _quality != 'Særdeles lovende'
                            ? Text(
                                localizations?.requiresHighlyPromising ?? 'Requires Highly promising',
                                style: TextStyle(color: context.colors.textDisabled, fontSize: 12),
                              )
                            : Text(
                                localizations?.qualifiesForBestPuppy ?? 'Qualifies for best male puppy/female puppy',
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
                        localizations?.ckCertificateQuality ?? 'CK (Certificate Quality)',
                        style: TextStyle(
                          color: _isCKAvailable ? null : context.colors.textDisabled,
                        ),
                      ),
                      subtitle: !_isCKAvailable
                          ? Text(
                              localizations?.requiresExcellent ?? 'Requires Excellent',
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
                              ? (localizations?.bestMalePuppy ?? 'Best male puppy')
                              : (localizations?.bestFemalePuppy ?? 'Best female puppy'))
                          : (widget.dogGender == 'Male' 
                              ? (localizations?.bestMalePlacement ?? 'Best male placement (BHK)')
                              : (localizations?.bestFemalePlacement ?? 'Best female placement (BTK)')),
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_hasCK && _classPlacement == '1' ? (localizations?.qualifiedForBIRBIMPuppy ?? 'Qualified for BIR/BIM Puppy') : (localizations?.requiresFirstWithHP ?? 'Requires 1st place with HP to participate'))
                          : (_isNordicCountry && _bestOfSexPlacement != '1'
                              ? (localizations?.requiresBHKBTKFirstNordic ?? 'BHK/BTK 1st required for BIR/BIM in Nordic countries')
                              : null),
                    ),
                    items: _isPuppyClass
                        ? [
                            DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'None')),
                            DropdownMenuItem(value: '1', child: Text(localizations?.yesWon ?? 'Yes - Won')),
                          ]
                        : [
                            DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'None')),
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
                      labelText: _isPuppyClass ? (localizations?.birBimPuppy ?? 'BIR/BIM Puppy') : 'BIR/BIM',
                      border: const OutlineInputBorder(),
                      helperText: _isPuppyClass
                          ? (_bestOfSexPlacement != '1' ? (localizations?.requiresBestPuppy ?? 'Requires being best male/female puppy') : null)
                          : (!_isBIRBIMAvailable ? (localizations?.requiresBHKBTKFirstNordic ?? 'BHK/BTK 1st required for BIR/BIM in Nordic countries') : null),
                      helperStyle: TextStyle(color: AppColors.warning),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(localizations?.unplaced ?? 'None')),
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
                              Icon(LucideIcons.users, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                localizations?.groupFinal ?? 'Group final',
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
                              labelText: localizations?.groupResult ?? 'Group result',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(localizations?.didNotParticipate ?? 'Did not participate / no placement')),
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
                            label: localizations?.groupJudge ?? 'Group judge',
                            hint: '',
                            optionsFuture: ShowDataService().getJudgeNames(),
                            filled: true,
                            prefixIcon: const Icon(LucideIcons.user),
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
                              Icon(LucideIcons.trophy, color: AppColors.warning),
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
                              labelText: localizations?.bisResult ?? 'BIS result',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: context.colors.surface,
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(localizations?.noPlacement ?? 'No placement')),
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
                            label: localizations?.bisJudge ?? 'BIS judge',
                            hint: '',
                            optionsFuture: ShowDataService().getJudgeNames(),
                            filled: true,
                            prefixIcon: const Icon(LucideIcons.user),
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
                      labelText: localizations?.judgeCritique ?? 'Judge critique',
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
                      labelText: localizations?.ownNotes ?? 'Own notes',
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
                          ? (localizations?.update ?? 'Update')
                          : (localizations?.save ?? 'Save')),
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
                    ? Icon(LucideIcons.chevronDown, color: context.colors.textCaption)
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
                                message: AppLocalizations.of(context)?.similarNameTooltip ?? 'Similar name – did you mean this?',
                                child: Icon(LucideIcons.helpCircle, size: 16, color: Colors.orange[600]),
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
            Icon(LucideIcons.arrowLeftRight, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLocalizations.of(context)?.similarNameFound ?? 'Similar name found', style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: '${AppLocalizations.of(context)?.youTyped ?? 'You typed'} ',
                children: [
                  TextSpan(
                    text: '"$newName"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ', ${AppLocalizations.of(context)?.butSimilarNamesExist ?? 'but similar names exist.\nDid you mean one of these?'}'),
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
                      const Icon(LucideIcons.checkCircle, size: 18, color: Colors.green),
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
                  Icon(LucideIcons.plusCircle, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.keepNewSpelling(newName) ?? 'Keep "$newName" (new spelling)',
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
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
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
      final resolved = await _checkAndResolveName(judge, judgeNames, 'Judge');
      if (resolved == null) return; // User cancelled
      judge = resolved;
      _judgeController.text = resolved;
    }

    // Check group judge name
    if (groupJudge != null && groupJudge.isNotEmpty) {
      final resolved = await _checkAndResolveName(groupJudge, judgeNames, 'Group judge');
      if (resolved == null) return;
      groupJudge = resolved;
      _groupJudgeController.text = resolved;
    }

    // Check BIS judge name
    if (bisJudge != null && bisJudge.isNotEmpty) {
      final resolved = await _checkAndResolveName(bisJudge, judgeNames, 'BIS judge');
      if (resolved == null) return;
      bisJudge = resolved;
      _bisJudgeController.text = resolved;
    }

    // Check show name
    if (showName.isNotEmpty) {
      final resolved = await _checkAndResolveName(showName, showNames, 'Show name');
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
      place: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
      country: _selectedCountry,
    );

    // Sync to cloud
    try {
      final userId = AuthService().currentUserId;
      if (userId != null) {
        await FirestoreService.saveShowResultEntry(userId, result);
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
          shareDog = widget.dog;
          scaffoldMessenger = ScaffoldMessenger.of(context);
          navigator = Navigator.of(context);
        } catch (_) {}
      }

      Navigator.pop(context);
      widget.onSaved();

      // Prompt to share to Peddex feed (only for new results)
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
              messenger.clearSnackBars();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n?.feedPostPublished ?? 'Shared on Peddex!'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onSkipped: () {
              messenger.clearSnackBars();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n?.resultSaved ?? 'Result saved!'),
                  action: SnackBarAction(
                    label: l10n?.shareResultCard ?? 'Share result card',
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
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Dialog page for sharing a show result to the Peddex feed
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
                    Icon(LucideIcons.newspaper, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n?.feedShareTitle ?? 'Share on Peddex?',
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
                  l10n?.feedVisibility ?? 'Visibility',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _VisibilityOption(
                        icon: LucideIcons.globe,
                        label: l10n?.feedPublic ?? 'Everyone',
                        isSelected: _visibility == 'public',
                        onTap: () => setState(() => _visibility = 'public'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VisibilityOption(
                        icon: LucideIcons.lock,
                        label: l10n?.feedFollowersOnly ?? 'Followers only',
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
                      child: Text(l10n?.feedSkip ?? 'Skip'),
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
                          : const Icon(LucideIcons.send, size: 18),
                      label: Text(l10n?.feedPublish ?? 'Share'),
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
      
      // Get kennel profile to ensure we have the correct kennelId and name
      final profile = await FeedService().getOwnPublicProfile();
      final kennelId = profile?['kennelId'] as String? ?? userId;
      final kennelName = profile?['kennelName'] as String? ?? 'Unknown kennel';

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

// ═══════════════════════════════════════════════════════════════════
// Show Results Import Sheet
// ═══════════════════════════════════════════════════════════════════

enum _ImportStep { paste, analyzing, preview }

class _ShowResultsImportSheet extends StatefulWidget {
  final String dogId;
  final VoidCallback onImported;

  const _ShowResultsImportSheet({
    required this.dogId,
    required this.onImported,
  });

  @override
  State<_ShowResultsImportSheet> createState() => _ShowResultsImportSheetState();
}

class _ShowResultsImportSheetState extends State<_ShowResultsImportSheet> {
  final _textController = TextEditingController();
  _ImportStep _step = _ImportStep.paste;
  String? _errorMessage;
  List<ImportedShowResult> _results = [];
  late List<bool> _selected;
  late List<String?> _placementOverride; // BIR/BIM chosen per-result in preview
  late List<bool> _duplicates; // true if result already exists in Firestore
  List<ShowResult> _existingResults = [];

  Future<void> _loadExistingResults() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;
    final snapshot = await FirestoreService()
        .baseQuery('show_results', userId)
        .where('dogId', isEqualTo: widget.dogId)
        .get();
    _existingResults = snapshot.docs
        .map((d) => ShowResult.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Returns a parallel bool list — true if an existing result for this dog
  /// already has the same date and a matching show name (case-insensitive).
  List<bool> _detectDuplicates(List<ImportedShowResult> results) {
    final existing = _existingResults;
    return results.map((r) {
      return existing.any((e) =>
          e.date.year == r.date.year &&
          e.date.month == r.date.month &&
          e.date.day == r.date.day &&
          e.showName.trim().toLowerCase() == r.showName.trim().toLowerCase());
    }).toList();
  }

  /// Returns the existing [ShowResult] that matches [r] (same dog, date, show name),
  /// or null if none exists.
  ShowResult? _findExistingResult(ImportedShowResult r) {
    try {
      return _existingResults.firstWhere(
        (e) =>
            e.dogId == widget.dogId &&
            e.date.year == r.date.year &&
            e.date.month == r.date.month &&
            e.date.day == r.date.day &&
            e.showName.trim().toLowerCase() == r.showName.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Shows a dialog when the user is about to import a show result that already
  /// exists. Returns:
  /// - `'replace'` → delete the existing record and save the imported one
  /// - `'both'`    → keep the existing record AND save the imported one as new
  /// - `'skip'`    → do nothing (keep existing, skip import)
  /// - `null`      → dialog dismissed (treated as skip)
  Future<String?> _showDuplicateImportDialog(
    ImportedShowResult imported,
    ShowResult existing,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.copyX, color: AppColors.warning),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n?.importResultAlreadyExists ?? 'Result already exists')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.importResultAlreadyExistsDesc(imported.showName, dateFormat.format(imported.date)) ??
                  'A result for "${imported.showName}" on ${dateFormat.format(imported.date)} is already saved.',
                  style: const TextStyle(fontSize: 14),
                ),
                SizedBox(height: AppSpacing.md),
                // Existing record summary
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ctx.colors.neutral100,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n?.importSavedResult ?? 'Saved result',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: ctx.colors.textMuted)),
                      SizedBox(height: 4),
                      Text(
                        [existing.showClass, existing.quality,
                          if (existing.hasCK) 'CK',
                          if (existing.placement != null) existing.placement!,
                          if (existing.certificates != null)
                            ...existing.certificates!,
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (existing.judge != null)
                        Text('${l10n?.judge ?? "Judge"}: ${existing.judge}',
                            style: TextStyle(
                                fontSize: 13, color: ctx.colors.textMuted)),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                // Imported record summary
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.07),
                    borderRadius: AppRadius.smAll,
                    border:
                        Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n?.importedResult ?? 'Imported result',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.info)),
                      SizedBox(height: 4),
                      Text(
                        [imported.showClass, imported.quality,
                          if (imported.hasCK) 'CK',
                          if (imported.placement != null) imported.placement!,
                          ...imported.certificates,
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (imported.judge != null)
                        Text('${l10n?.judge ?? "Judge"}: ${imported.judge}',
                            style: TextStyle(
                                fontSize: 13,
                                color: ctx.colors.textMuted)),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(l10n?.importWhatToDo ?? 'What do you want to do?',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: Text(l10n?.importSkip ?? 'Skip'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'both'),
              child: Text(l10n?.importKeepBoth ?? 'Keep both'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: Text(l10n?.importReplace ?? 'Replace'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _step = _ImportStep.analyzing;
      _errorMessage = null;
    });

    try {
      await _loadExistingResults();
      final results = await ShowImportService().analyzeText(text);
      if (!mounted) return;
      setState(() {
        _results = results;
        _selected = List.filled(results.length, true);
        // Pre-fill overrides from AI-parsed placement (may already be BIR/BIM)
        _placementOverride = results.map((r) => r.placement).toList();
        // Detect duplicates: pre-deselect results already saved for this dog
        _duplicates = _detectDuplicates(results);
        for (int i = 0; i < results.length; i++) {
          if (_duplicates[i]) _selected[i] = false;
        }
        _step = _ImportStep.preview;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _step = _ImportStep.paste;
      });
    }
  }

  Future<void> _importSelected() async {
    int count = 0;

    for (int i = 0; i < _results.length; i++) {
      if (!_selected[i]) continue;
      final r = _results[i];

      // If this result already exists, ask the user what to do
      if (_duplicates[i]) {
        final existing = _findExistingResult(r);
        if (existing != null) {
          if (!mounted) return;
          final action = await _showDuplicateImportDialog(r, existing);
          if (action == null || action == 'skip') continue;
          if (action == 'replace') {
            try {
              final userId = AuthService().currentUserId;
              if (userId != null) {
                await FirestoreService.removeShowResult(userId, existing.id);
              }
            } catch (e) {
              AppLogger.debug('Import replace cloud delete error: \$e');
            }
          }
          // 'both' falls through and saves as a new record
        }
      }

      final result = ShowResult(
        id: const Uuid().v4(),
        dogId: widget.dogId,
        date: r.date,
        showName: r.showName,
        judge: r.judge,
        showClass: r.showClass,
        quality: r.quality,
        classPlacement: r.classPlacement,
        placement: _placementOverride[i],
        certificates: r.certificates.isNotEmpty ? r.certificates : null,
        bestOfSexPlacement: r.bestOfSexPlacement,
        groupResult: r.groupResult,
        bisResult: r.bisResult,
        groupJudge: null,
        bisJudge: null,
        critique: null,
        notes: r.notes,
        showType: r.showType,
        hasCK: r.hasCK,
        place: r.place,
      );

      // Sync to cloud
      try {
        final userId = AuthService().currentUserId;
        if (userId != null) {
          await FirestoreService.saveShowResultEntry(userId, result);
        }
      } catch (e) {
        AppLogger.debug('Import save error: $e');
      }

      // Save show name & judge for autocomplete
      try {
        if (r.showName.isNotEmpty) ShowDataService().addShowName(r.showName);
        if (r.judge != null && r.judge!.isNotEmpty) {
          ShowDataService().addJudgeName(r.judge!);
        }
      } catch (_) {}

      count++;
    }

    if (!mounted) return;
    Navigator.pop(context);
    widget.onImported();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.importSuccess(count) ??
          '$count result${count == 1 ? '' : 's'} imported',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.fileInput, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.importShowResults ?? 'Import show results',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _ImportStep.paste:
        return _buildPasteStep();
      case _ImportStep.analyzing:
        return _buildAnalyzingStep();
      case _ImportStep.preview:
        return _buildPreviewStep();
    }
  }

  Widget _buildPasteStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.info, color: AppColors.info, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n?.importShowResultsHowTo ?? 'How to import show results',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _instructionStep('1', l10n?.importStep1 ?? 'Open your kennel club\'s show results page and navigate to the dog\'s results.'),
              _instructionStep('2', l10n?.importStep2 ?? 'Select all the text on the page (Ctrl+A / Cmd+A).'),
              _instructionStep('3', l10n?.importStep3 ?? 'Copy it (Ctrl+C / Cmd+C).'),
              _instructionStep('4', l10n?.importStep4 ?? 'Paste it into the field below.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Text field
        TextField(
          controller: _textController,
          maxLines: 10,
          minLines: 5,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: l10n?.importPasteLabel ?? 'Paste show results text here',
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            hintText: l10n?.importPasteHint ?? 'Paste the copied text here…',
          ),
          onChanged: (_) => setState(() => _errorMessage = null),
        ),
        if (_errorMessage != null) ...
          [
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: AppColors.error, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(_errorMessage!, style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: _textController.text.trim().isEmpty ? null : _analyze,
          icon: const Icon(LucideIcons.sparkles),
          label: Text(l10n?.importAnalyzeWithAI ?? 'Analyze with AI'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildAnalyzingStep() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.importAnalyzing ?? 'Analyzing with AI…',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n?.importAnalyzingSubtitle ?? 'This may take a few seconds',
            style: TextStyle(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final selectedCount = _selected.where((v) => v).length;

    if (_results.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Icon(LucideIcons.searchX, size: 48, color: context.colors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n?.importNoResultsFound ?? 'No results found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n?.importNoResultsFoundDesc ??
            'The AI could not extract any show results from the pasted text. Try selecting more of the page.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => setState(() => _step = _ImportStep.paste),
            icon: const Icon(LucideIcons.arrowLeft),
            label: Text(l10n?.back ?? 'Back'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary row
        Row(
          children: [
            Expanded(
              child: Text(
                l10n?.importResultsFound(_results.length) ??
                '${_results.length} result${_results.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                final allSelected = _selected.every((v) => v);
                _selected = List.filled(_results.length, !allSelected);
              }),
              child: Text(_selected.every((v) => v)
                  ? (l10n?.importDeselectAll ?? 'Deselect all')
                  : (l10n?.importSelectAll ?? 'Select all')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Result rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = _results[index];
            final currentPlacement = _placementOverride[index];
            final needsBirBimChoice = r.bestOfSexPlacement == '1';
            final isDuplicate = _duplicates[index];

            final badges = [
              r.quality,
              if (r.hasCK) 'CK',
              if (currentPlacement != null) currentPlacement,
              if (r.groupResult != null) r.groupResult!,
              if (r.bisResult != null) r.bisResult!,
              ...r.certificates,
            ];

            return CheckboxListTile(
              value: _selected[index],
              onChanged: (v) => setState(() => _selected[index] = v ?? false),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              title: Text(
                '${dateFormat.format(r.date)}  •  ${r.showName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDuplicate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.copyX, size: 13, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            _selected[index]
                                ? (l10n?.importAlreadySavedWillAsk ?? 'Already saved — will ask on import')
                                : (l10n?.importAlreadySavedSelectToReplace ?? 'Already saved — select to replace or keep both'),
                            style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    [r.showClass, if (r.place != null) r.place!, if (r.judge != null) r.judge!].join('  •  '),
                    style: TextStyle(fontSize: 13, color: context.colors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: badges
                        .map(
                          (b) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  // BIR / BIM picker — shown when dog won best of sex
                  if (needsBirBimChoice) ...
                    [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            l10n?.importBestOfSex ?? 'Best of sex:',
                            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          _PlacementChip(
                            label: 'BIR',
                            selected: currentPlacement == 'BIR',
                            onTap: () => setState(
                              () => _placementOverride[index] =
                                  currentPlacement == 'BIR' ? null : 'BIR',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PlacementChip(
                            label: 'BIM',
                            selected: currentPlacement == 'BIM',
                            onTap: () => setState(
                              () => _placementOverride[index] =
                                  currentPlacement == 'BIM' ? null : 'BIM',
                            ),
                          ),
                        ],
                      ),
                    ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        // Action buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _step = _ImportStep.paste),
              icon: const Icon(LucideIcons.arrowLeft),
              label: Text(l10n?.back ?? 'Back'),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: selectedCount == 0 ? null : _importSelected,
                icon: const Icon(LucideIcons.download),
                label: Text(
                  selectedCount == 0
                      ? (l10n?.importNoResultsSelected ?? 'No results selected')
                      : (l10n?.importCount(selectedCount) ?? 'Import $selectedCount result${selectedCount == 1 ? '' : 's'}'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// Small selectable chip used in the import preview for choosing BIR / BIM.
class _PlacementChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlacementChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).primaryColor : context.colors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.14)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : context.colors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }
}
