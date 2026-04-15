import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/services/search_service.dart';
import 'package:oasis/features/feed/presentation/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/widgets/desktop_header.dart';
import 'package:oasis/widgets/wellbeing/lockout_overlay.dart';
import 'package:oasis/widgets/custom_snackbar.dart';

import 'package:oasis/services/app_initializer.dart'; // For ThemeProvider
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  final bool isPanel;
  const SearchScreen({super.key, this.isPanel = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
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
    _tabController = TabController(length: 2, vsync: this);
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;

    if (isDesktop && !usePanelLayout) {
      // Full Screen Desktop layout
      final desktopBgColor = disableTransparency
          ? colorScheme.surface
          : colorScheme.surface.withValues(alpha: 0.4);

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: desktopBgColor,
            borderRadius: BorderRadius.circular(isM3E ? 32 : 12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isM3E ? 32 : 12),
            child: disableTransparency
                ? Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Stack(
                      children: [
                        Column(
                          children: [
                            _buildNewDesktopHeader(theme, colorScheme, isM3E),
                            Expanded(child: _buildDesktopLayout(isM3E)),
                          ],
                        ),
                        const LockoutOverlay(pageName: 'Search'),
                      ],
                    ),
                  )
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Stack(
                        children: [
                          Column(
                            children: [
                              _buildNewDesktopHeader(theme, colorScheme, isM3E),
                              Expanded(child: _buildDesktopLayout(isM3E)),
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
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 60,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          actions: [
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: _buildPanelLayout(isM3E),
      );
    }

    // Mobile layout
    return Scaffold(
      backgroundColor: usePanelLayout
          ? colorScheme.surface
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        automaticallyImplyLeading: !usePanelLayout,
        flexibleSpace: ClipRRect(
          child: disableTransparency
              ? Container(color: Colors.transparent)
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
        ),
        elevation: 0,
        toolbarHeight: 80,
        title: Container(
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(isM3E ? 16 : 26),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          if (usePanelLayout)
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showPanelFilters(context, isM3E),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                _buildTab('People', 0, isM3E),
                _buildTab('Posts', 1, isM3E),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildMobileLayout(isM3E),
          const LockoutOverlay(pageName: 'Search'),
        ],
      ),
    );
  }

  Widget _buildNewDesktopHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isM3E,
  ) {
    return Column(
      children: [
        DesktopHeader(
          title: 'Search',
          subtitle: 'Discover people, posts, and moments',
          actions: [
            IconButton.filledTonal(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                size: 20,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              style: IconButton.styleFrom(
                backgroundColor: _showFilters
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: _showFilters
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
          child: MaxWidthContainer(
            maxWidth: 1000,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(isM3E ? 16 : 32),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search for anything on Oasis...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 28),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showPanelFilters(BuildContext context, bool isM3E) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isM3E ? 48 : 24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: isM3E ? -0.5 : 0,
              ),
            ),
            const SizedBox(height: 24),
            _buildSortOption('Relevance', 'relevance', Icons.star_outline),
            _buildSortOption('Recent', 'recent', Icons.access_time),
            _buildSortOption('Popular', 'popular', Icons.trending_up),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, bool isM3E) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final theme = Theme.of(context);
        return Container(
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            borderRadius: BorderRadius.circular(isM3E ? 12 : 12),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected
                  ? (isM3E ? FontWeight.w900 : FontWeight.bold)
                  : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(bool isM3E) {
    return Row(
      children: [
        // Filters Sidebar
        if (_showFilters)
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: _buildFiltersSidebar(isM3E),
          ),
        // Main Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _query.isEmpty
              ? _buildSearchSuggestions(isM3E)
              : _buildDesktopResults(isM3E),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isM3E) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _query.isEmpty
        ? _buildSearchSuggestions(isM3E)
        : TabBarView(
            controller: _tabController,
            children: [_buildUserList(isM3E), _buildPostList()],
          );
  }

  Widget _buildPanelLayout(bool isM3E) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _query.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for people and posts',
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter keywords to find users and posts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              // Simple tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildPanelTab('People', 0, isM3E)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPanelTab('Posts', 1, isM3E)),
                  ],
                ),
              ),
              // Results
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildPanelUserList(isM3E), _buildPanelPostList()],
                ),
              ),
            ],
          );
  }

  Widget _buildPanelTab(String label, int index, bool isM3E) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () => _tabController.animateTo(index),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: BorderRadius.circular(isM3E ? 10 : 10),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelUserList(bool isM3E) {
    if (_userResults.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: user['avatar_url'] != null
                ? CachedNetworkImageProvider(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? Text(user['username'][0].toUpperCase())
                : null,
          ),
          title: Text(
            user['full_name'] ?? user['username'],
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '@${user['username']}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            context.push('/profile/${user['id']}');
          },
        );
      },
    );
  }

  Widget _buildPanelPostList() {
    if (_postResults.isEmpty) {
      return Center(
        child: Text(
          'No posts found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return _buildPanelPostCard(post);
      },
    );
  }

  Widget _buildPanelPostCard(Post post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: post.userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatar)
                    : null,
                child: post.userAvatar.isEmpty
                    ? Text(
                        post.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Content
          Text(
            post.content ?? '',
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersSidebar(bool isM3E) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Filter by Type
        Text(
          'Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildFilterChip('All', 'all'),
        _buildFilterChip('Users', 'users'),
        _buildFilterChip('Posts', 'posts'),
        const SizedBox(height: 24),

        // Sort By
        Text(
          'Sort By',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildSortOption('Relevance', 'relevance', Icons.star_outline),
        _buildSortOption('Recent', 'recent', Icons.access_time),
        _buildSortOption('Popular', 'popular', Icons.trending_up),
        const SizedBox(height: 24),

        // Quick Stats
        if (_userResults.isNotEmpty || _postResults.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Users:', style: theme.textTheme.bodyMedium),
                    Text(
                      '${_userResults.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Posts:', style: theme.textTheme.bodyMedium),
                    Text(
                      '${_postResults.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilterChip(
        label: SizedBox(width: double.infinity, child: Text(label)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _sortBy = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopResults(bool isM3E) {
    if (_selectedFilter == 'users' || _selectedFilter == 'all') {
      if (_selectedFilter == 'users') {
        return _buildUserList(isM3E);
      }
      // Show both
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'People',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 200, child: _buildUserList(isM3E)),
            ],
            if (_postResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Posts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
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

  Widget _buildSearchSuggestions(bool isM3E) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: MaxWidthContainer(
        maxWidth: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Search for people and posts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter keywords to find users, posts, and more',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Search Tips
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Tips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchTip(
                        Icons.person_outline,
                        'Find users by name or username',
                      ),
                      _buildSearchTip(
                        Icons.article_outlined,
                        'Discover posts by keywords',
                      ),
                      _buildSearchTip(Icons.tag, 'Search using hashtags'),
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

  Widget _buildSearchTip(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildUserList(bool isM3E) {
    if (_userResults.isEmpty) {
      return _buildEmptyState('No users found');
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;

    if (isDesktop && !usePanelLayout) {
      return MaxWidthContainer(
        maxWidth: ResponsiveLayout.maxContentWidth,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: Container(
            padding: EdgeInsets.all(isM3E ? 2 : 0),
            decoration: BoxDecoration(
              shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isM3E ? BorderRadius.circular(10) : null,
              border: isM3E
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: isM3E
                  ? BorderRadius.circular(8)
                  : BorderRadius.circular(20),
              child: SizedBox(
                width: 40,
                height: 40,
                child: user['avatar_url'] != null
                    ? CachedNetworkImage(
                        imageUrl: user['avatar_url'],
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            user['username'][0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          title: Text(
            user['full_name'] ?? user['username'],
            style: TextStyle(
              fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
          subtitle: Text('@${user['username']}'),
          onTap: () {
            context.push('/profile/${user['id']}');
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isM3E) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/profile/${user['id']}'),
            borderRadius: BorderRadius.circular(isM3E ? 24 : 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isM3E ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isM3E ? BorderRadius.circular(14) : null,
                      border: isM3E
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: isM3E
                          ? BorderRadius.circular(11)
                          : BorderRadius.circular(28),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: user['avatar_url'] != null
                            ? CachedNetworkImage(
                                imageUrl: user['avatar_url'],
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Text(
                                    user['username'][0].toUpperCase(),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user['full_name'] ?? user['username'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isM3E
                                ? FontWeight.w900
                                : FontWeight.bold,
                            letterSpacing: isM3E ? -0.5 : 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user['username']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
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

  Widget _buildPostList() {
    if (_postResults.isEmpty) {
      return _buildEmptyState('No posts found');
    }

    final postList = ListView.builder(
      padding: const EdgeInsets.all(16),
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

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
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
