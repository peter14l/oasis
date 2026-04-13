import 'package:flutter/material.dart';
import 'package:oasis/features/stories/domain/models/story_entity.dart';
import 'package:oasis/services/spotify_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/core/utils/haptic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';

class MusicPickerSheet extends StatefulWidget {
  const MusicPickerSheet({super.key});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final SpotifyService _spotifyService = SpotifyService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<StoryMusicEntity> _tracks = [];
  List<StoryMusicEntity> _featuredTracks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _playingTrackId;
  String _currentSearchQuery = '';
  int _displayedCount = 5;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFeatured() async {
    final tracks = await _spotifyService.getFeaturedTracks();
    if (mounted) {
      setState(() {
        _featuredTracks = tracks;
        _tracks = tracks.take(_displayedCount).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _currentSearchQuery = '';
      _loadFeatured();
      return;
    }
    _currentSearchQuery = query;
    setState(() => _isSearching = true);
    final results = await _spotifyService.searchTracks(query);
    if (mounted) {
      setState(() {
        _tracks = results.take(_displayedCount).toList();
        _isSearching = false;
      });
    }
  }

  void _loadMore() {
    if (_displayedCount >= _tracks.length) return;
    setState(() {
      _displayedCount = (_displayedCount + _pageSize).clamp(0, _tracks.length);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _togglePreview(StoryMusicEntity track) async {
    if (_playingTrackId == track.trackId) {
      await _audioPlayer.stop();
      setState(() => _playingTrackId = null);
    } else {
      await _audioPlayer.stop();
      if (track.previewUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(track.previewUrl));
        setState(() => _playingTrackId = track.trackId);
      }
    }
    HapticUtils.selectionClick();
  }

  void _showArtworkPicker(StoryMusicEntity track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ArtworkPickerSheet(
            track: track,
            onSelect: (artworkStyle) {
              final updatedTrack = StoryMusicEntity(
                trackId: track.trackId,
                title: track.title,
                artist: track.artist,
                albumArtUrl: track.albumArtUrl,
                previewUrl: track.previewUrl,
                artworkStyle: artworkStyle,
              );
              Navigator.pop(context);
              Navigator.pop(context, updatedTrack);
            },
          ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isM3E ? colorScheme.surface : Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isM3E ? 28 : 24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          isM3E
                              ? colorScheme.surfaceContainerHighest
                              : Colors.white10,
                      borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                          size: 20,
                        ),
                        hintText: 'Search for music...',
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _search('');
                                  },
                                )
                                : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionHeader(isM3E),
          Expanded(
            child:
                _isLoading || _isSearching
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : _tracks.isEmpty
                    ? const Center(
                      child: Text(
                        'No music found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _tracks.length + 1,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        if (index >= _tracks.length) {
                          return _tracks.length >= _displayedCount
                              ? _buildLoadMoreButton(isM3E, colorScheme)
                              : const SizedBox.shrink();
                        }
                        final track = _tracks[index];
                        final isPlaying = _playingTrackId == track.trackId;
                        return FadeInUp(
                          duration: Duration(milliseconds: 100 + (index * 20)),
                          child: _buildTrackTile(
                            track,
                            isPlaying,
                            isM3E,
                            colorScheme,
                          ),
                        );
                      },
                    ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isM3E) {
    final String headerText;
    if (_currentSearchQuery.isNotEmpty) {
      headerText = 'Results for "$_currentSearchQuery"';
    } else {
      headerText = 'Featured';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            _currentSearchQuery.isNotEmpty ? Icons.search : Icons.music_note,
            color: Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            headerText,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_tracks.length} songs',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(
    StoryMusicEntity track,
    bool isPlaying,
    bool isM3E,
    ColorScheme colorScheme,
  ) {
    return ListTile(
      onTap: () {
        _audioPlayer.stop();
        _showArtworkPicker(track);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
            child: CachedNetworkImage(
              imageUrl: track.albumArtUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      Container(color: Colors.white10, width: 56, height: 56),
            ),
          ),
          if (isPlaying)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
              ),
              child: const Icon(Icons.pause, color: Colors.white, size: 28),
            ),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
          letterSpacing: isM3E ? -0.5 : 0,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      trailing: IconButton(
        icon: Icon(
          isPlaying
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_filled_rounded,
          color: isPlaying ? colorScheme.primary : Colors.white70,
          size: 36,
        ),
        onPressed: () => _togglePreview(track),
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isM3E, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: _loadMore,
          child: Text(
            'Load more',
            style: TextStyle(
              color: isM3E ? colorScheme.primary : Colors.white70,
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPickerSheet extends StatefulWidget {
  final StoryMusicEntity track;
  final Function(String) onSelect;

  const _ArtworkPickerSheet({required this.track, required this.onSelect});

  @override
  State<_ArtworkPickerSheet> createState() => _ArtworkPickerSheetState();
}

class _ArtworkPickerSheetState extends State<_ArtworkPickerSheet> {
  String _selectedStyle = 'original';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    final artworkOptions = [
      {'id': 'original', 'label': 'Original', 'icon': Icons.crop_square},
      {'id': 'blurred', 'label': 'Blurred', 'icon': Icons.blur_on},
      {'id': 'circle', 'label': 'Circle', 'icon': Icons.circle},
      {'id': 'full', 'label': 'Full', 'icon': Icons.fullscreen},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isM3E ? colorScheme.surface : Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isM3E ? 28 : 24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose artwork style',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.track.title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: artworkOptions.length,
              itemBuilder: (context, index) {
                final option = artworkOptions[index];
                final isSelected = _selectedStyle == option['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedStyle = option['id'] as String);
                    HapticUtils.selectionClick();
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (isM3E
                                  ? colorScheme.primaryContainer
                                  : Colors.white.withOpacity(0.1))
                              : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
                      border:
                          isSelected
                              ? Border.all(
                                color:
                                    isM3E
                                        ? colorScheme.primary
                                        : Colors.white54,
                                width: 2,
                              )
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
                          child: CachedNetworkImage(
                            imageUrl: widget.track.albumArtUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSelect(_selectedStyle),
              style: ElevatedButton.styleFrom(
                backgroundColor: isM3E ? colorScheme.primary : Colors.white,
                foregroundColor: isM3E ? colorScheme.onPrimary : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
                ),
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
