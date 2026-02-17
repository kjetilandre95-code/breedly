import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/feed_post.dart';
import 'package:breedly/services/feed_service.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

import 'package:breedly/generated_l10n/app_localizations.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _feedService = FeedService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  List<FeedPost> _allPosts = [];
  List<FeedPost> _followingPosts = [];
  bool _isLoading = true;
  FeedPostType? _activeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadFeed();
      }
    });
    _loadFeed();
    _feedService.markAllAsRead();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        _followingPosts = await _feedService.getFollowingFeed(
          filterType: _activeFilter,
        );
      } else {
        _allPosts = await _feedService.getFeed(
          filterType: _activeFilter,
        );
      }
    } catch (e) {
      // Use cached data on error
      _allPosts = _feedService.getCachedFeed();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.feedTitle,
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showKennelSearch(context, l10n),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.colors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.feedFollowing),
            Tab(text: l10n.feedAll),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active filter chip
          if (_activeFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Chip(
                    label: Text(_getFilterName(_activeFilter!, l10n)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _activeFilter = null);
                      _loadFeed();
                    },
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),

          // Feed content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedList(_followingPosts, isFollowing: true),
                _buildFeedList(_allPosts, isFollowing: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<FeedPost> posts, {required bool isFollowing}) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFollowing ? Icons.people_outline : Icons.newspaper,
                size: 64,
                color: context.colors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isFollowing
                    ? l10n.feedNoFollowing
                    : l10n.feedNoNews,
                style: AppTypography.bodyLarge.copyWith(
                  color: context.colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (isFollowing) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.feedSearchKennels,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colors.textCaption,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _FeedPostCard(
            post: posts[index],
            dateFormat: _dateFormat,
            onLike: () => _handleLike(posts[index]),
            onDelete: posts[index].authorId == AuthService().currentUserId
                ? () => _handleDelete(posts[index])
                : null,
          );
        },
      ),
    );
  }

  Future<void> _handleLike(FeedPost post) async {
    await _feedService.toggleLike(post.id);
    _loadFeed();
  }

  Future<void> _handleDelete(FeedPost post) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.feedDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _feedService.deletePost(post.id);
      _loadFeed();
    }
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.filter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: Text(l10n.all),
              selected: _activeFilter == null,
              onTap: () {
                setState(() => _activeFilter = null);
                Navigator.pop(context);
                _loadFeed();
              },
            ),
            ...FeedPostType.values.map((type) => ListTile(
                  leading: Icon(_getFilterIcon(type)),
                  title: Text(_getFilterName(type, l10n)),
                  selected: _activeFilter == type,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    setState(() => _activeFilter = type);
                    Navigator.pop(context);
                    _loadFeed();
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getFilterName(FeedPostType type, AppLocalizations l10n) {
    switch (type) {
      case FeedPostType.showResult:
        return l10n.feedShowResults;
      case FeedPostType.championTitle:
        return l10n.feedChampionTitles;
      case FeedPostType.litterAnnouncement:
        return l10n.feedLitterAnnouncements;
      case FeedPostType.puppiesAvailable:
        return l10n.feedPuppiesAvailable;
    }
  }

  IconData _getFilterIcon(FeedPostType type) {
    switch (type) {
      case FeedPostType.showResult:
        return Icons.emoji_events;
      case FeedPostType.championTitle:
        return Icons.workspace_premium;
      case FeedPostType.litterAnnouncement:
        return Icons.pets;
      case FeedPostType.puppiesAvailable:
        return Icons.sell;
    }
  }

  void _showKennelSearch(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _KennelSearchSheet(feedService: _feedService),
    );
  }
}

// ─── Feed Post Card ───────────────────────────────────────

class _FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final DateFormat dateFormat;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  const _FeedPostCard({
    required this.post,
    required this.dateFormat,
    required this.onLike,
    this.onDelete,
  });

  IconData _getPostIcon() {
    switch (post.postType) {
      case FeedPostType.showResult:
        return Icons.emoji_events;
      case FeedPostType.championTitle:
        return Icons.workspace_premium;
      case FeedPostType.litterAnnouncement:
        return Icons.pets;
      case FeedPostType.puppiesAvailable:
        return Icons.sell;
    }
  }

  Color _getPostColor() {
    switch (post.postType) {
      case FeedPostType.showResult:
        return AppColors.accent1;
      case FeedPostType.championTitle:
        return const Color(0xFFFFD700);
      case FeedPostType.litterAnnouncement:
        return AppColors.success;
      case FeedPostType.puppiesAvailable:
        return AppColors.accent4;
    }
  }

  String _getTimeAgo(AppLocalizations l10n) {
    final diff = DateTime.now().difference(post.timestamp);
    if (diff.inMinutes < 60) {
      return l10n.feedMinutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.feedHoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.feedDaysAgo(diff.inDays);
    } else {
      return dateFormat.format(post.timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final postColor = _getPostColor();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: kennel name + time + icon
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: postColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(_getPostIcon(), color: postColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.kennelName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${post.breed} · ${_getTimeAgo(l10n)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: context.colors.textCaption),
                    onSelected: (value) {
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.delete),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            // Subtitle / details
            if (post.subtitle != null && post.subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _buildSubtitleContent(context, theme),
            ],

            // Show result details
            if (post.postType == FeedPostType.showResult && post.contentData != null)
              _buildShowResultDetails(context, theme, l10n),

            if (post.postType == FeedPostType.litterAnnouncement && post.contentData != null)
              _buildLitterDetails(context, theme, l10n),

            const SizedBox(height: AppSpacing.md),

            // Footer: likes
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: AppRadius.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: context.colors.textCaption,
                        ),
                        if (post.likes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.textCaption,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (post.visibility == 'followersOnly')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: context.colors.textCaption),
                      const SizedBox(width: 4),
                      Text(
                        l10n.feedFollowersOnly,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textCaption,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleContent(BuildContext context, ThemeData theme) {
    final postColor = _getPostColor();

    if (post.postType == FeedPostType.showResult || post.postType == FeedPostType.championTitle) {
      // Show result badges
      final parts = post.subtitle!.split(', ');
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: parts.map((part) {
          final isCert = part == 'CERT' || part == 'CACIB' || part == 'CK';
          final isBIR = part == 'BIR' || part == 'BIM' || part.startsWith('BIS') || part.startsWith('BIG');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isBIR
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : isCert
                      ? postColor.withValues(alpha: 0.15)
                      : context.colors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: AppRadius.smAll,
              border: isBIR
                  ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5))
                  : null,
            ),
            child: Text(
              part,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isCert || isBIR ? FontWeight.bold : FontWeight.normal,
                color: isBIR
                    ? const Color(0xFFB8860B)
                    : isCert
                        ? postColor
                        : context.colors.textSecondary,
              ),
            ),
          );
        }).toList(),
      );
    }

    return Text(
      post.subtitle!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }

  Widget _buildShowResultDetails(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final data = post.contentData!;
    final judge = data['judge'] as String?;
    final showClass = data['showClass'] as String?;

    if (judge == null && showClass == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          if (showClass != null) ...[
            Icon(Icons.category_outlined, size: 14, color: context.colors.textCaption),
            const SizedBox(width: 4),
            Text(
              showClass,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textCaption,
              ),
            ),
          ],
          if (showClass != null && judge != null) const SizedBox(width: AppSpacing.lg),
          if (judge != null) ...[
            Icon(Icons.person_outline, size: 14, color: context.colors.textCaption),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                judge,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textCaption,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLitterDetails(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final data = post.contentData!;
    final damName = data['damName'] as String?;
    final sireName = data['sireName'] as String?;

    if (damName == null && sireName == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (damName != null)
            Row(
              children: [
                Icon(Icons.female, size: 16, color: AppColors.female),
                const SizedBox(width: 4),
                Text(
                  '${l10n.dam}: $damName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          if (sireName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.male, size: 16, color: AppColors.male),
                const SizedBox(width: 4),
                Text(
                  '${l10n.sire}: $sireName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Kennel Search Bottom Sheet ─────────────────────────

class _KennelSearchSheet extends StatefulWidget {
  final FeedService feedService;

  const _KennelSearchSheet({required this.feedService});

  @override
  State<_KennelSearchSheet> createState() => _KennelSearchSheetState();
}

class _KennelSearchSheetState extends State<_KennelSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  Set<String> _followingSet = {};

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final following = await widget.feedService.getFollowing();
    setState(() => _followingSet = following.toSet());
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await widget.feedService.searchKennelsByName(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.feedSearchKennelsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.feedSearchKennelsHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.lgAll,
                  ),
                ),
                onChanged: _search,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? l10n.feedSearchKennelsPrompt
                                : l10n.noResults,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final kennel = _results[index];
                            final kennelId = kennel['kennelId'] as String? ?? '';
                            final isFollowing = _followingSet.contains(kennelId);
                            final breeds = (kennel['breeds'] as List<dynamic>?)
                                    ?.cast<String>()
                                    .join(', ') ??
                                '';
                            final followerCount = kennel['followerCount'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    (kennel['kennelName'] as String? ?? '?')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  kennel['kennelName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (breeds.isNotEmpty)
                                      Text(
                                        breeds,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    Text(
                                      '$followerCount ${l10n.feedFollowers}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: context.colors.textCaption,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isFollowing
                                    ? OutlinedButton(
                                        onPressed: () async {
                                          await widget.feedService.unfollowKennel(kennelId);
                                          setState(() => _followingSet.remove(kennelId));
                                        },
                                        child: Text(l10n.feedUnfollow),
                                      )
                                    : FilledButton(
                                        onPressed: () async {
                                          await widget.feedService.followKennel(kennelId);
                                          setState(() => _followingSet.add(kennelId));
                                        },
                                        child: Text(l10n.feedFollow),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
