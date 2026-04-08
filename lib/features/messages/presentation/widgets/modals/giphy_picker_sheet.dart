import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:oasis/features/messages/data/services/klipy_service.dart';
import 'package:oasis/features/messages/core/chat_api_config.dart';

class GiphyPickerSheet extends StatefulWidget {
  final Function(String url, bool isSticker) onSelected;

  const GiphyPickerSheet({
    super.key,
    required this.onSelected,
  });

  @override
  State<GiphyPickerSheet> createState() => _GiphyPickerSheetState();
}

class _GiphyPickerSheetState extends State<GiphyPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KlipyService _klipyService = KlipyService();
  final TextEditingController _searchController = TextEditingController();
  List<KlipyMedia> _klipyResults = [];
  bool _isLoadingKlipy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrendingKlipy();
  }

  Future<void> _loadTrendingKlipy() async {
    if (ChatApiConfig.klipyApiKey.isEmpty) return;
    
    setState(() => _isLoadingKlipy = true);
    final results = await _klipyService.getTrending();
    setState(() {
      _klipyResults = results;
      _isLoadingKlipy = false;
    });
  }

  Future<void> _searchKlipy(String query) async {
    if (ChatApiConfig.klipyApiKey.isEmpty) return;
    if (query.isEmpty) {
      _loadTrendingKlipy();
      return;
    }
    setState(() => _isLoadingKlipy = true);
    final results = await _klipyService.search(query);
    setState(() {
      _klipyResults = results;
      _isLoadingKlipy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Giphy'),
              Tab(text: 'Klipy'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiphyTab(),
                _buildKlipyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiphyTab() {
    final theme = Theme.of(context);
    final apiKey = ChatApiConfig.giphyApiKey;

    if (apiKey.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Giphy Service Unavailable',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please configure your Giphy API key in the .env file to enable this feature.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search),
        onPressed: () async {
          try {
            GiphyGif? gif = await GiphyGet.getGif(
              context: context,
              apiKey: apiKey,
              lang: GiphyLanguage.english,
            );
            if (gif != null && gif.images?.original?.url != null) {
              widget.onSelected(gif.images!.original!.url!, gif.type == 'sticker');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Giphy error: $e')),
              );
            }
          }
        },
        label: const Text('Search Giphy'),
      ),
    );
  }

  Widget _buildKlipyTab() {
    final theme = Theme.of(context);
    final apiKey = ChatApiConfig.klipyApiKey;

    if (apiKey.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Klipy Service Unavailable',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please configure your Klipy API key in the .env file to enable this feature.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Klipy...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _loadTrendingKlipy();
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: _searchKlipy,
          ),
        ),
        Expanded(
          child: _isLoadingKlipy
              ? const Center(child: CircularProgressIndicator())
              : _klipyResults.isEmpty 
                  ? Center(child: Text('No results found', style: theme.textTheme.bodyMedium))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _klipyResults.length,
                      itemBuilder: (context, index) {
                        final media = _klipyResults[index];
                        return GestureDetector(
                          onTap: () => widget.onSelected(media.url, false),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              media.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
