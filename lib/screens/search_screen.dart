import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:go_router/go_router.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/services/search_service.dart';
import 'package:oasis/features/feed/presentation/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/widgets/desktop_header.dart';
import 'package:oasis/widgets/wellbeing/lockout_overlay.dart';
import 'package:oasis/widgets/custom_snackbar.dart';

import 'package:oasis/services/app_initializer.dart';
import 'package:provider/provider.dart';

class SearchScreen extends material.StatefulWidget {
  final bool isPanel;
  const SearchScreen({super.key, this.isPanel = false});

  @override
  material.State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends material.State<SearchScreen>
    with material.SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final material.TextEditingController _searchController = material.TextEditingController();
  late material.TabController _tabController;
  Timer? _debounce;

  List<Map<String, dynamic>> _userResults = [];
  List<Post> _postResults = [];
  bool _isLoading = false;
  String _query = '';

  // Filter states
  String _selectedFilter = 'all'; // all, users, posts
  String _sortBy = 'relevance'; // relevance, recent, popular
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _tabController = material.TabController(length: 2, vsync: this);
  }

  Future<void> _performSearch() async {
    if (_query.isEmpty) {
      setState(() {
        _userResults = [];
        _postResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final users = await _searchService.searchUsers(_query);
      final posts = await _searchService.searchPosts(_query);

      if (mounted) {
        setState(() {
          _userResults = users;
          _postResults = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.showError(context, e);
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _onSearchSubmitted(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = material.Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final useFluent = themeProvider.useFluentUI;
    final usePanelLayout = widget.isPanel;

    if (useFluent && !usePanelLayout) {
      return _buildFluentSearch(context, themeProvider);
    }

    if (isDesktop && !usePanelLayout) {
      // Full Screen Desktop layout
      final desktopBgColor = disableTransparency
          ? colorScheme.surface
          : colorScheme.surface.withValues(alpha: 0.4);

      return material.Padding(
        padding: const material.EdgeInsets.all(12),
        child: material.Container(
          decoration: material.BoxDecoration(
            color: desktopBgColor,
            borderRadius: material.BorderRadius.circular(isM3E ? 32 : 12),
            border: material.Border.all(color: material.Colors.white.withValues(alpha: 0.05)),
          ),
          child: material.ClipRRect(
            borderRadius: material.BorderRadius.circular(isM3E ? 32 : 12),
            child: disableTransparency
                ? material.Scaffold(
                    backgroundColor: material.Colors.transparent,
                    body: material.Stack(
                      children: [
                        material.Column(
                          children: [
                            _buildNewDesktopHeader(theme, colorScheme, isM3E),
                            material.Expanded(child: _buildDesktopLayout(isM3E)),
                          ],
                        ),
                        const LockoutOverlay(pageName: 'Search'),
                      ],
                    ),
                  )
                : material.BackdropFilter(
                    filter: material.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: material.Scaffold(
                      backgroundColor: material.Colors.transparent,
                      body: material.Stack(
                        children: [
                          material.Column(
                            children: [
                              _buildNewDesktopHeader(theme, colorScheme, isM3E),
                              material.Expanded(child: _buildDesktopLayout(isM3E)),
                            ],
                          ),
                          const LockoutOverlay(pageName: 'Search'),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    // Mobile layout OR Panel layout (Simplified for narrow width)
    if (usePanelLayout) {
      // Panel layout - adapted for 400px sliding panel
      return material.Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: material.AppBar(
          backgroundColor: colorScheme.surface,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 60,
          title: material.Container(
            height: 40,
            decoration: material.BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: material.BorderRadius.circular(isM3E ? 12 : 20),
              border: material.Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: material.TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: material.InputDecoration(
                hintText: 'Search...',
                border: material.InputBorder.none,
                hintStyle: material.TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: material.Icon(
                  material.Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                contentPadding: const material.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textInputAction: material.TextInputAction.search,
            ),
          ),
          actions: [
            if (_query.isNotEmpty)
              material.IconButton(
                icon: const material.Icon(material.Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            const material.SizedBox(width: 4),
          ],
        ),
        body: _buildPanelLayout(isM3E),
      );
    }

    // Mobile layout
    return material.Scaffold(
      backgroundColor: usePanelLayout
          ? colorScheme.surface
          : theme.scaffoldBackgroundColor,
      appBar: material.AppBar(
        backgroundColor: colorScheme.surface,
        automaticallyImplyLeading: !usePanelLayout,
        flexibleSpace: material.ClipRRect(
          child: disableTransparency
              ? material.Container(color: material.Colors.transparent)
              : material.BackdropFilter(
                  filter: material.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: material.Container(color: material.Colors.transparent),
                ),
        ),
        elevation: 0,
        toolbarHeight: 80,
        title: material.Container(
          height: 52,
          decoration: material.BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: material.BorderRadius.circular(isM3E ? 16 : 26),
            border: material.Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: material.TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            decoration: material.InputDecoration(
              hintText: 'Search...',
              border: material.InputBorder.none,
              hintStyle: material.TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: material.Icon(
                material.Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              contentPadding: const material.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textInputAction: material.TextInputAction.search,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            material.IconButton(
              icon: const material.Icon(material.Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          if (usePanelLayout)
            material.IconButton(
              icon: const material.Icon(material.Icons.filter_list_rounded),
              onPressed: () => _showPanelFilters(context, isM3E),
            ),
          const material.SizedBox(width: 8),
        ],
        bottom: material.PreferredSize(
          preferredSize: const material.Size.fromHeight(60),
          child: material.Padding(
            padding: const material.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: material.TabBar(
              controller: _tabController,
              indicator: const material.BoxDecoration(),
              dividerColor: material.Colors.transparent,
              labelPadding: const material.EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                _buildTab('People', 0, isM3E),
                _buildTab('Posts', 1, isM3E),
              ],
            ),
          ),
        ),
      ),
      body: material.Stack(
        children: [
          _buildMobileLayout(isM3E),
          const LockoutOverlay(pageName: 'Search'),
        ],
      ),
    );
  }

  material.Widget _buildFluentSearch(material.BuildContext context, ThemeProvider themeProvider) {
    return fluent.ScaffoldPage.scrollable(
      header: fluent.PageHeader(
        title: const fluent.Text('Search'),
        commandBar: fluent.CommandBar(
          mainAxisAlignment: material.MainAxisAlignment.end,
          primaryItems: [
            fluent.CommandBarButton(
              icon: material.Icon(_showFilters ? material.Icons.filter_list_off : material.Icons.filter_list, size: 18),
              label: fluent.Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ],
        ),
      ),
      children: [
        material.Padding(
          padding: const material.EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: fluent.TextBox(
            controller: _searchController,
            placeholder: 'Search for anything on Oasis...',
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            prefix: const material.Padding(
              padding: material.EdgeInsets.only(left: 12.0),
              child: material.Icon(material.Icons.search, size: 20),
            ),
            suffix: _query.isNotEmpty ? fluent.IconButton(
              icon: const material.Icon(material.Icons.clear, size: 16),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ) : null,
          ),
        ),
        material.Row(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            if (_showFilters)
              material.Container(
                width: 250,
                padding: const material.EdgeInsets.all(24),
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    const fluent.Text('Type', style: material.TextStyle(fontWeight: material.FontWeight.bold)),
                    fluent.RadioButton(
                      checked: _selectedFilter == 'all',
                      content: const fluent.Text('All'),
                      onChanged: (v) => setState(() => _selectedFilter = 'all'),
                    ),
                    fluent.RadioButton(
                      checked: _selectedFilter == 'users',
                      content: const fluent.Text('Users'),
                      onChanged: (v) => setState(() => _selectedFilter = 'users'),
                    ),
                    fluent.RadioButton(
                      checked: _selectedFilter == 'posts',
                      content: const fluent.Text('Posts'),
                      onChanged: (v) => setState(() => _selectedFilter = 'posts'),
                    ),
                  ],
                ),
              ),
            material.Expanded(
              child: _isLoading 
                ? const material.Center(child: fluent.ProgressRing())
                : _query.isEmpty
                  ? _buildSearchSuggestions(themeProvider.isM3EEnabled)
                  : _buildDesktopResults(themeProvider.isM3EEnabled),
            ),
          ],
        ),
      ],
    );
  }

  material.Widget _buildNewDesktopHeader(
    material.ThemeData theme,
    material.ColorScheme colorScheme,
    bool isM3E,
  ) {
    return material.Column(
      children: [
        DesktopHeader(
          title: 'Search',
          subtitle: 'Discover people, posts, and moments',
          actions: [
            material.IconButton.filledTonal(
              icon: material.Icon(
                _showFilters ? material.Icons.filter_list_off : material.Icons.filter_list,
                size: 20,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              style: material.IconButton.styleFrom(
                backgroundColor: _showFilters
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: _showFilters
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                shape: material.RoundedRectangleBorder(
                  borderRadius: material.BorderRadius.circular(isM3E ? 12 : 20),
                ),
              ),
            ),
          ],
        ),
        material.Container(
          padding: const material.EdgeInsets.fromLTRB(40, 0, 40, 24),
          child: MaxWidthContainer(
            maxWidth: 1000,
            child: material.Container(
              height: 64,
              decoration: material.BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: material.BorderRadius.circular(isM3E ? 16 : 32),
                border: material.Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: material.TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                decoration: material.InputDecoration(
                  hintText: 'Search for anything on Oasis...',
                  border: material.InputBorder.none,
                  hintStyle: material.TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: material.FontWeight.w500,
                  ),
                  prefixIcon: const material.Icon(material.Icons.search, size: 28),
                  suffixIcon: _query.isNotEmpty
                      ? material.IconButton(
                          icon: const material.Icon(material.Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  contentPadding: const material.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: material.FontWeight.w600,
                ),
                textInputAction: material.TextInputAction.search,
              ),
            ),
          ),
        ),
        const material.Divider(height: 1),
      ],
    );
  }

  void _showPanelFilters(material.BuildContext context, bool isM3E) {
    material.showModalBottomSheet(
      context: context,
      backgroundColor: material.Theme.of(context).colorScheme.surface,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.vertical(
          top: material.Radius.circular(isM3E ? 48 : 24),
        ),
      ),
      builder: (context) => material.Container(
        padding: const material.EdgeInsets.all(24),
        child: material.Column(
          mainAxisSize: material.MainAxisSize.min,
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Text(
              'Sort Results',
              style: material.Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
                letterSpacing: isM3E ? -0.5 : 0,
              ),
            ),
            const material.SizedBox(height: 24),
            _buildSortOption('Relevance', 'relevance', material.Icons.star_outline),
            _buildSortOption('Recent', 'recent', material.Icons.access_time),
            _buildSortOption('Popular', 'popular', material.Icons.trending_up),
            const material.SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  material.Widget _buildTab(String label, int index, bool isM3E) {
    return material.ListenableBuilder(
      listenable: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final theme = material.Theme.of(context);
        return material.Container(
          width: material.double.infinity,
          height: 44,
          alignment: material.Alignment.center,
          decoration: material.BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            borderRadius: material.BorderRadius.circular(isM3E ? 12 : 12),
          ),
          child: material.Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? material.Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected
                  ? (isM3E ? material.FontWeight.w900 : material.FontWeight.bold)
                  : material.FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  material.Widget _buildDesktopLayout(bool isM3E) {
    return material.Row(
      children: [
        // Filters Sidebar
        if (_showFilters)
          material.Container(
            width: 280,
            decoration: material.BoxDecoration(
              border: material.Border(
                right: material.BorderSide(
                  color: material.Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: _buildFiltersSidebar(isM3E),
          ),
        // Main Content
        material.Expanded(
          child: _isLoading
              ? const material.Center(child: material.CircularProgressIndicator())
              : _query.isEmpty
              ? _buildSearchSuggestions(isM3E)
              : _buildDesktopResults(isM3E),
        ),
      ],
    );
  }

  material.Widget _buildMobileLayout(bool isM3E) {
    return _isLoading
        ? const material.Center(child: material.CircularProgressIndicator())
        : _query.isEmpty
        ? _buildSearchSuggestions(isM3E)
        : material.TabBarView(
            controller: _tabController,
            children: [_buildUserList(isM3E), _buildPostList()],
          );
  }

  material.Widget _buildPanelLayout(bool isM3E) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _isLoading
        ? const material.Center(child: material.CircularProgressIndicator())
        : _query.isEmpty
        ? material.Center(
            child: material.Padding(
              padding: const material.EdgeInsets.all(16),
              child: material.Column(
                mainAxisAlignment: material.MainAxisAlignment.center,
                children: [
                  material.Icon(
                    material.Icons.search,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const material.SizedBox(height: 16),
                  material.Text(
                    'Search for people and posts',
                    style: theme.textTheme.titleSmall,
                    textAlign: material.TextAlign.center,
                  ),
                  const material.SizedBox(height: 8),
                  material.Text(
                    'Enter keywords to find users and posts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: material.TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : material.Column(
            children: [
              // Simple tab bar
              material.Padding(
                padding: const material.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: material.Row(
                  children: [
                    material.Expanded(child: _buildPanelTab('People', 0, isM3E)),
                    const material.SizedBox(width: 8),
                    material.Expanded(child: _buildPanelTab('Posts', 1, isM3E)),
                  ],
                ),
              ),
              // Results
              material.Expanded(
                child: material.TabBarView(
                  controller: _tabController,
                  children: [_buildPanelUserList(isM3E), _buildPanelPostList()],
                ),
              ),
            ],
          );
  }

  material.Widget _buildPanelTab(String label, int index, bool isM3E) {
    return material.ListenableBuilder(
      listenable: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final theme = material.Theme.of(context);
        return material.GestureDetector(
          onTap: () => _tabController.animateTo(index),
          child: material.Container(
            height: 36,
            alignment: material.Alignment.center,
            decoration: material.BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: material.BorderRadius.circular(isM3E ? 10 : 10),
            ),
            child: material.Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? material.Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? material.FontWeight.w600 : material.FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  material.Widget _buildPanelUserList(bool isM3E) {
    if (_userResults.isEmpty) {
      return material.Center(
        child: material.Text(
          'No users found',
          style: material.Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: material.Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return material.ListView.builder(
      padding: const material.EdgeInsets.symmetric(horizontal: 8),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return material.ListTile(
          contentPadding: const material.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          dense: true,
          leading: material.CircleAvatar(
            radius: 18,
            backgroundImage: user['avatar_url'] != null
                ? CachedNetworkImageProvider(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? material.Text(user['username'][0].toUpperCase())
                : null,
          ),
          title: material.Text(
            user['full_name'] ?? user['username'],
            style: material.Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: material.FontWeight.w600),
            maxLines: 1,
            overflow: material.TextOverflow.ellipsis,
          ),
          subtitle: material.Text(
            '@${user['username']}',
            style: material.Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: material.TextOverflow.ellipsis,
          ),
          onTap: () {
            context.push('/profile/${user['id']}');
          },
        );
      },
    );
  }

  material.Widget _buildPanelPostList() {
    if (_postResults.isEmpty) {
      return material.Center(
        child: material.Text(
          'No posts found',
          style: material.Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: material.Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return material.ListView.builder(
      padding: const material.EdgeInsets.symmetric(horizontal: 8),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return _buildPanelPostCard(post);
      },
    );
  }

  material.Widget _buildPanelPostCard(Post post) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return material.Container(
      margin: const material.EdgeInsets.only(bottom: 8),
      padding: const material.EdgeInsets.all(12),
      decoration: material.BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: material.BorderRadius.circular(12),
      ),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          // User info
          material.Row(
            children: [
              material.CircleAvatar(
                radius: 14,
                backgroundImage: post.userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatar)
                    : null,
                child: post.userAvatar.isEmpty
                    ? material.Text(
                        post.username[0].toUpperCase(),
                        style: const material.TextStyle(fontSize: 10),
                      )
                    : null,
              ),
              const material.SizedBox(width: 8),
              material.Expanded(
                child: material.Text(
                  post.username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: material.FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: material.TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const material.SizedBox(height: 8),
          // Content
          material.Text(
            post.content ?? '',
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: material.TextOverflow.ellipsis,
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const material.SizedBox(height: 8),
            material.ClipRRect(
              borderRadius: material.BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                height: 120,
                width: material.double.infinity,
                fit: material.BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  material.Widget _buildFiltersSidebar(bool isM3E) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return material.ListView(
      padding: const material.EdgeInsets.all(16),
      children: [
        material.Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
          ),
        ),
        const material.SizedBox(height: 24),

        // Filter by Type
        material.Text(
          'Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: material.FontWeight.w600,
          ),
        ),
        const material.SizedBox(height: 8),
        _buildFilterChip('All', 'all'),
        _buildFilterChip('Users', 'users'),
        _buildFilterChip('Posts', 'posts'),
        const material.SizedBox(height: 24),

        // Sort By
        material.Text(
          'Sort By',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: material.FontWeight.w600,
          ),
        ),
        const material.SizedBox(height: 8),
        _buildSortOption('Relevance', 'relevance', material.Icons.star_outline),
        _buildSortOption('Recent', 'recent', material.Icons.access_time),
        _buildSortOption('Popular', 'popular', material.Icons.trending_up),
        const material.SizedBox(height: 24),

        // Quick Stats
        if (_userResults.isNotEmpty || _postResults.isNotEmpty) ...[
          material.Container(
            padding: const material.EdgeInsets.all(16),
            decoration: material.BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: material.BorderRadius.circular(isM3E ? 16 : 12),
            ),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: [
                material.Text(
                  'Results',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: material.FontWeight.w600,
                  ),
                ),
                const material.SizedBox(height: 12),
                material.Row(
                  mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                  children: [
                    material.Text('Users:', style: theme.textTheme.bodyMedium),
                    material.Text(
                      '${_userResults.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: material.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const material.SizedBox(height: 8),
                material.Row(
                  mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                  children: [
                    material.Text('Posts:', style: theme.textTheme.bodyMedium),
                    material.Text(
                      '${_postResults.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: material.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  material.Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return material.Padding(
      padding: const material.EdgeInsets.only(bottom: 8),
      child: material.FilterChip(
        label: material.SizedBox(width: material.double.infinity, child: material.Text(label)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  material.Widget _buildSortOption(String label, String value, material.IconData icon) {
    final isSelected = _sortBy == value;
    final theme = material.Theme.of(context);

    return material.Padding(
      padding: const material.EdgeInsets.only(bottom: 8),
      child: material.InkWell(
        onTap: () => setState(() => _sortBy = value),
        borderRadius: material.BorderRadius.circular(8),
        child: material.Container(
          padding: const material.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: material.BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null,
            borderRadius: material.BorderRadius.circular(8),
          ),
          child: material.Row(
            children: [
              material.Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const material.SizedBox(width: 12),
              material.Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? material.FontWeight.w600 : material.FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  material.Widget _buildDesktopResults(bool isM3E) {
    if (_selectedFilter == 'users' || _selectedFilter == 'all') {
      if (_selectedFilter == 'users') {
        return _buildUserList(isM3E);
      }
      // Show both
      return material.SingleChildScrollView(
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            if (_userResults.isNotEmpty) ...[
              material.Padding(
                padding: const material.EdgeInsets.all(16),
                child: material.Text(
                  'People',
                  style: material.Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
                  ),
                ),
              ),
              material.SizedBox(height: 200, child: _buildUserList(isM3E)),
            ],
            if (_postResults.isNotEmpty) ...[
              material.Padding(
                padding: const material.EdgeInsets.all(16),
                child: material.Text(
                  'Posts',
                  style: material.Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
                  ),
                ),
              ),
              _buildPostList(),
            ],
            if (_userResults.isEmpty && _postResults.isEmpty)
              _buildEmptyState('No results found'),
          ],
        ),
      );
    } else {
      return _buildPostList();
    }
  }

  material.Widget _buildSearchSuggestions(bool isM3E) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return material.Center(
      child: MaxWidthContainer(
        maxWidth: 600,
        child: material.SingleChildScrollView(
          child: material.Padding(
            padding: const material.EdgeInsets.all(24),
            child: material.Column(
              mainAxisAlignment: material.MainAxisAlignment.center,
              children: [
                material.Icon(
                  material.Icons.search,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                const material.SizedBox(height: 24),
                material.Text(
                  'Search for people and posts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
                  ),
                  textAlign: material.TextAlign.center,
                ),
                const material.SizedBox(height: 12),
                material.Text(
                  'Enter keywords to find users, posts, and more',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: material.TextAlign.center,
                ),
                const material.SizedBox(height: 32),
                // Search Tips
                material.Container(
                  padding: const material.EdgeInsets.all(20),
                  decoration: material.BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: material.BorderRadius.circular(isM3E ? 24 : 16),
                  ),
                  child: material.Column(
                    crossAxisAlignment: material.CrossAxisAlignment.start,
                    children: [
                      material.Text(
                        'Search Tips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
                        ),
                      ),
                      const material.SizedBox(height: 16),
                      _buildSearchTip(
                        material.Icons.person_outline,
                        'Find users by name or username',
                      ),
                      _buildSearchTip(
                        material.Icons.article_outlined,
                        'Discover posts by keywords',
                      ),
                      _buildSearchTip(material.Icons.tag, 'Search using hashtags'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  material.Widget _buildSearchTip(material.IconData icon, String text) {
    final theme = material.Theme.of(context);
    return material.Padding(
      padding: const material.EdgeInsets.only(bottom: 12),
      child: material.Row(
        children: [
          material.Icon(icon, size: 20, color: theme.colorScheme.primary),
          const material.SizedBox(width: 12),
          material.Expanded(child: material.Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  material.Widget _buildUserList(bool isM3E) {
    if (_userResults.isEmpty) {
      return _buildEmptyState('No users found');
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;

    if (isDesktop && !usePanelLayout) {
      return MaxWidthContainer(
        maxWidth: ResponsiveLayout.maxContentWidth,
        child: material.GridView.builder(
          padding: const material.EdgeInsets.all(16),
          gridDelegate: material.SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveLayout.getGridColumns(
              context,
              mobile: 1,
              tablet: 2,
              desktop: 3,
            ),
            childAspectRatio: 3.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _userResults.length,
          itemBuilder: (context, index) {
            final user = _userResults[index];
            return _buildUserCard(user, isM3E);
          },
        ),
      );
    }

    return material.ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return material.ListTile(
          leading: material.Container(
            padding: material.EdgeInsets.all(isM3E ? 2 : 0),
            decoration: material.BoxDecoration(
              shape: isM3E ? material.BoxShape.rectangle : material.BoxShape.circle,
              borderRadius: isM3E ? material.BorderRadius.circular(10) : null,
              border: isM3E
                  ? material.Border.all(
                      color: material.Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: material.ClipRRect(
              borderRadius: isM3E
                  ? material.BorderRadius.circular(8)
                  : material.BorderRadius.circular(20),
              child: material.SizedBox(
                width: 40,
                height: 40,
                child: user['avatar_url'] != null
                    ? CachedNetworkImage(
                        imageUrl: user['avatar_url'],
                        fit: material.BoxFit.cover,
                      )
                    : material.Container(
                        color: material.Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: material.Center(
                          child: material.Text(
                            user['username'][0].toUpperCase(),
                            style: material.TextStyle(
                              fontWeight: material.FontWeight.bold,
                              color: material.Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          title: material.Text(
            user['full_name'] ?? user['username'],
            style: material.TextStyle(
              fontWeight: isM3E ? material.FontWeight.w900 : material.FontWeight.bold,
            ),
          ),
          subtitle: material.Text('@${user['username']}'),
          onTap: () {
            context.push('/profile/${user['id']}');
          },
        );
      },
    );
  }

  material.Widget _buildUserCard(Map<String, dynamic> user, bool isM3E) {
    final theme = material.Theme.of(context);

    return material.ClipRRect(
      borderRadius: material.BorderRadius.circular(isM3E ? 24 : 16),
      child: material.BackdropFilter(
        filter: material.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: material.Container(
          decoration: material.BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: material.BorderRadius.circular(isM3E ? 24 : 16),
            border: material.Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: material.InkWell(
            onTap: () => context.push('/profile/${user['id']}'),
            borderRadius: material.BorderRadius.circular(isM3E ? 24 : 12),
            child: material.Padding(
              padding: const material.EdgeInsets.all(16),
              child: material.Row(
                children: [
                  material.Container(
                    padding: material.EdgeInsets.all(isM3E ? 3 : 0),
                    decoration: material.BoxDecoration(
                      shape: isM3E ? material.BoxShape.rectangle : material.BoxShape.circle,
                      borderRadius: isM3E ? material.BorderRadius.circular(14) : null,
                      border: isM3E
                          ? material.Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: material.ClipRRect(
                      borderRadius: isM3E
                          ? material.BorderRadius.circular(11)
                          : material.BorderRadius.circular(28),
                      child: material.SizedBox(
                        width: 56,
                        height: 56,
                        child: user['avatar_url'] != null
                            ? CachedNetworkImage(
                                imageUrl: user['avatar_url'],
                                fit: material.BoxFit.cover,
                              )
                            : material.Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: material.Center(
                                  child: material.Text(
                                    user['username'][0].toUpperCase(),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: material.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const material.SizedBox(width: 16),
                  material.Expanded(
                    child: material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      mainAxisAlignment: material.MainAxisAlignment.center,
                      children: [
                        material.Text(
                          user['full_name'] ?? user['username'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isM3E
                                ? material.FontWeight.w900
                                : material.FontWeight.bold,
                            letterSpacing: isM3E ? -0.5 : 0,
                          ),
                          maxLines: 1,
                          overflow: material.TextOverflow.ellipsis,
                        ),
                        const material.SizedBox(height: 4),
                        material.Text(
                          '@${user['username']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: material.TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  material.Icon(
                    material.Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  material.Widget _buildPostList() {
    if (_postResults.isEmpty) {
      return _buildEmptyState('No posts found');
    }

    final postList = material.ListView.builder(
      padding: const material.EdgeInsets.all(16),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return PostCard(post: post);
      },
    );

    return (ResponsiveLayout.isDesktop(context) && !widget.isPanel)
        ? MaxWidthContainer(
            maxWidth: ResponsiveLayout.maxFeedWidth,
            child: postList,
          )
        : postList;
  }

  material.Widget _buildEmptyState(String message) {
    final theme = material.Theme.of(context);
    return material.Center(
      child: material.Column(
        mainAxisAlignment: material.Center,
        children: [
          material.Icon(
            material.Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const material.SizedBox(height: 16),
          material.Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const material.SizedBox(height: 8),
          material.Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
