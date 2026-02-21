import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/services/global_search_service.dart';
import 'package:breedly/screens/dog_detail_screen.dart';
import 'package:breedly/screens/litter_detail_screen.dart';
import 'package:breedly/screens/buyers_screen.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalSearchService _searchService = GlobalSearchService();
  Timer? _debounceTimer;

  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Add listener for live search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many searches while typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _searchService.search(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  void _navigateToResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.dog:
        final dogBox = Hive.box<Dog>('dogs');
        final dog = dogBox.values.where((d) => d.id == result.id).firstOrNull;
        if (dog != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DogDetailScreen(dog: dog),
            ),
          );
        }
        break;
      case SearchResultType.litter:
        final litterBox = Hive.box<Litter>('litters');
        final litter = litterBox.values.where((l) => l.id == result.id).firstOrNull;
        if (litter != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LitterDetailScreen(litter: litter),
            ),
          );
        }
        break;
      case SearchResultType.puppy:
        // Navigate to puppy's litter
        final puppy = result.data;
        if (puppy != null) {
          final litterBox = Hive.box<Litter>('litters');
          final litter = litterBox.values.where((l) => l.id == puppy.litterId).firstOrNull;
          if (litter != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LitterDetailScreen(litter: litter),
              ),
            );
          }
        }
        break;
      case SearchResultType.buyer:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BuyersScreen(),
          ),
        );
        break;
    }
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.dog:
        return AppColors.info;
      case SearchResultType.litter:
        return AppColors.success;
      case SearchResultType.puppy:
        return AppColors.warning;
      case SearchResultType.buyer:
        return AppColors.accent5;
    }
  }

  String _getTypeLabel(SearchResultType type, AppLocalizations l10n) {
    switch (type) {
      case SearchResultType.dog:
        return l10n.dogs;
      case SearchResultType.litter:
        return l10n.litters;
      case SearchResultType.puppy:
        return l10n.puppy;
      case SearchResultType.buyer:
        return l10n.buyer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '${l10n.search}...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
          ),
          // Live search via listener - no need for onChanged here
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                // Results are cleared via the listener
              },
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return _buildSearchPrompt(l10n);
    }

    if (_results.isEmpty) {
      return _buildNoResults(l10n);
    }

    return _buildResults(l10n);
  }

  Widget _buildSearchPrompt(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: context.colors.border,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.searchPrompt,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: context.colors.border,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.noResults,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tryDifferentSearch,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    // Group results by type
    final groupedResults = <SearchResultType, List<SearchResult>>{};
    for (final result in _results) {
      groupedResults.putIfAbsent(result.type, () => []).add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final type = groupedResults.keys.elementAt(index);
        final results = groupedResults[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withValues(alpha: 0.1),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Text(
                      _getTypeLabel(type, l10n),
                      style: TextStyle(
                        color: _getTypeColor(type),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '(${results.length})',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...results.map((result) => _buildResultCard(result)),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(result.type).withValues(alpha: 0.1),
          child: Icon(
            result.icon,
            color: _getTypeColor(result.type),
          ),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(result.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToResult(result),
      ),
    );
  }
}
