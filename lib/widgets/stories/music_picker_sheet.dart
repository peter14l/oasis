import 'package:flutter/material.dart';
import 'package:oasis_v2/models/story_model.dart';
import 'package:oasis_v2/services/spotify_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/app_initializer.dart';
import 'package:oasis_v2/core/utils/haptic_utils.dart';
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
  
  List<StoryMusic> _tracks = [];
  bool _isLoading = true;
  String? _playingTrackId;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final tracks = await _spotifyService.getFeaturedTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadFeatured();
      return;
    }
    setState(() => _isLoading = true);
    final results = await _spotifyService.searchTracks(query);
    if (mounted) {
      setState(() {
        _tracks = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePreview(StoryMusic track) async {
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(isM3E ? 48 : 24)),
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
                      color: isM3E 
                          ? colorScheme.surfaceContainerHighest 
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.white54, size: 20),
                        hintText: 'Search for music...',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _tracks.isEmpty
                    ? const Center(
                        child: Text(
                          'No music found',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tracks.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          final isPlaying = _playingTrackId == track.trackId;
                          return FadeInUp(
                            duration: Duration(milliseconds: 100 + (index * 20)),
                            child: ListTile(
                              onTap: () {
                                _audioPlayer.stop();
                                Navigator.pop(context, track);
                              },
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
                                    child: CachedNetworkImage(
                                      imageUrl: track.albumArtUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.white10,
                                        width: 50,
                                        height: 50,
                                      ),
                                    ),
                                  ),
                                  if (isPlaying)
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
                                      ),
                                      child: const Icon(Icons.pause, color: Colors.white, size: 24),
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
                                  fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isPlaying 
                                      ? Icons.pause_circle_filled_rounded 
                                      : Icons.play_circle_filled_rounded,
                                  color: isPlaying ? colorScheme.primary : Colors.white70,
                                  size: 32,
                                ),
                                onPressed: () => _togglePreview(track),
                              ),
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
}
