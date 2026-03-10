import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:morrow_v2/models/post.dart';
import 'package:morrow_v2/services/search_service.dart';
import 'package:morrow_v2/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/utils/responsive_layout.dart';
import 'package:morrow_v2/widgets/greyscale_wrapper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

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
    if (_query.isEmpty) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  void _onSearchSubmitted(String value) {
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      // Desktop layout without AppBar
      return GreyscaleWrapper(
        child: Scaffold(
          body: Column(
            children: [
              // Integrated search header
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.6),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onSubmitted: _onSearchSubmitted,
                              decoration: InputDecoration(
                                hintText: 'Search users or posts...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: const Icon(Icons.search, size: 24),
                                suffixIcon:
                                    _query.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _query = '';
                                              _userResults = [];
                                              _postResults = [];
                                            });
                                          },
                                        )
                                        : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(color: colorScheme.onSurface),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            _showFilters
                                ? Icons.filter_list_off
                                : Icons.filter_list,
                            size: 24,
                          ),
                          onPressed:
                              () =>
                                  setState(() => _showFilters = !_showFilters),
                          tooltip:
                              _showFilters ? 'Hide Filters' : 'Show Filters',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _showFilters
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                            foregroundColor:
                                _showFilters
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(child: _buildDesktopLayout()),
            ],
          ),
        ),
      );
    }

    // Mobile layout with AppBar
    return GreyscaleWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: colorScheme.surface.withValues(alpha: 0.6),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          elevation: 0,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search users or posts...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
              textInputAction: TextInputAction.search,
            ),
          ),
          actions: [
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _userResults = [];
                    _postResults = [];
                  });
                },
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [Tab(text: 'People'), Tab(text: 'Posts')],
          ),
        ),
        body: _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Filters Sidebar
        if (_showFilters)
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildFiltersSidebar(),
          ),
        // Main Content
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildDesktopResults(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _query.isEmpty
        ? _buildSearchSuggestions()
        : TabBarView(
          controller: _tabController,
          children: [_buildUserList(), _buildPostList()],
        );
  }

  Widget _buildFiltersSidebar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
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
            color:
                isSelected
                    ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                    : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected
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

  Widget _buildDesktopResults() {
    if (_selectedFilter == 'users' || _selectedFilter == 'all') {
      if (_selectedFilter == 'users') {
        return _buildUserList();
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 200, child: _buildUserList()),
            ],
            if (_postResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Posts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildSearchSuggestions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: MaxWidthContainer(
        maxWidth: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Search for people and posts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Tips',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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

  Widget _buildUserList() {
    if (_userResults.isEmpty) {
      return _buildEmptyState('No users found');
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
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
            return _buildUserCard(user);
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user['avatar_url'] != null
                    ? CachedNetworkImageProvider(user['avatar_url'])
                    : null,
            child:
                user['avatar_url'] == null
                    ? Text(user['username'][0].toUpperCase())
                    : null,
          ),
          title: Text(user['full_name'] ?? user['username']),
          subtitle: Text('@${user['username']}'),
          onTap: () {
            context.push('/profile/${user['id']}');
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/profile/${user['id']}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        user['avatar_url'] != null
                            ? CachedNetworkImageProvider(user['avatar_url'])
                            : null,
                    child:
                        user['avatar_url'] == null
                            ? Text(
                              user['username'][0].toUpperCase(),
                              style: theme.textTheme.titleLarge,
                            )
                            : null,
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
                            fontWeight: FontWeight.bold,
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

    return ResponsiveLayout.isDesktop(context)
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
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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
