import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oasis/features/stories/domain/models/story_entity.dart';
import 'package:flutter/foundation.dart';

class SpotifyService {
  static String get _clientId {
    const fromEnv = String.fromEnvironment('SPOTIFY_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  static String get _clientSecret {
    const fromEnv = String.fromEnvironment('SPOTIFY_CLIENT_SECRET');
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  String? _accessToken;
  DateTime? _tokenExpiry;

  // Popular tracks for mock/fallback
  static final List<StoryMusicEntity> _featuredTracks = [
    StoryMusicEntity(
      trackId: '0VjIj970nyB7S6tc27JpsO',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      albumArtUrl:
          'https://i.scdn.co/image/ab67616d0000b2738863bc11fafbf383a54d6d67',
      previewUrl:
          'https://p.scdn.co/mp3-preview/6324268e36785501869811f269a84d413554e4c2',
      artworkStyle: 'original',
    ),
    StoryMusicEntity(
      trackId: '5Y640pS3K99Z766oXv8p7P',
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      albumArtUrl:
          'https://i.scdn.co/image/ab67616d0000b2738863bc11fafbf383a54d6d67',
      previewUrl:
          'https://p.scdn.co/mp3-preview/a91901174620585f6738c823f66299b86be0b155',
      artworkStyle: 'original',
    ),
    StoryMusicEntity(
      trackId: '2693892839283',
      title: 'As It Was',
      artist: 'Harry Styles',
      albumArtUrl:
          'https://i.scdn.co/image/ab67616d0000b273b46b7e8b6267802871ee27a7',
      previewUrl:
          'https://p.scdn.co/mp3-preview/3e0bd2275841774312017366d9817751f78f6920',
      artworkStyle: 'original',
    ),
    StoryMusicEntity(
      trackId: '7K3165q8u6mZfX2K8T2K6K',
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      albumArtUrl:
          'https://i.scdn.co/image/ab67616d0000b273e787cffec20aa2a096fa0655',
      previewUrl:
          'https://p.scdn.co/mp3-preview/f4f9f214220359f1311099434823483984398439',
      artworkStyle: 'original',
    ),
    StoryMusicEntity(
      trackId: '1BxfuLsSRmSclS9vunvS8S',
      title: 'Flowers',
      artist: 'Miley Cyrus',
      albumArtUrl:
          'https://i.scdn.co/image/ab67616d0000b273f443997576f9d34343d96924',
      previewUrl:
          'https://p.scdn.co/mp3-preview/9f383e9383938393839383938393839383938393',
      artworkStyle: 'original',
    ),
  ];

  static const List<String> artworkStyles = [
    'original',
    'blurred',
    'circle',
    'full',
  ];

  Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    if (_clientId.isEmpty ||
        _clientId == 'your_client_id_here' ||
        _clientSecret.isEmpty) {
      return null;
    }

    try {
      final authStr = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $authStr',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in']),
        );
        return _accessToken;
      }
    } catch (e) {
      debugPrint('Spotify Auth Error: $e');
    }
    return null;
  }

  Future<List<StoryMusicEntity>> searchTracks(String query) async {
    if (query.isEmpty) return _featuredTracks;

    final token = await _getAccessToken();
    if (token == null) {
      return _featuredTracks
          .where(
            (t) =>
                t.title.toLowerCase().contains(query.toLowerCase()) ||
                t.artist.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=20',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['tracks']['items'];
        return items.map((item) => _parseTrack(item)).toList();
      }
    } catch (e) {
      debugPrint('Spotify Search Error: $e');
    }
    return _featuredTracks;
  }

  StoryMusicEntity _parseTrack(Map<String, dynamic> item) {
    final images = item['album']['images'] as List;
    return StoryMusicEntity(
      trackId: item['id'],
      title: item['name'] ?? '',
      artist: (item['artists'] as List).map((a) => a['name']).join(', '),
      albumArtUrl: images.isNotEmpty ? images[0]['url'] : '',
      previewUrl: item['preview_url'] ?? '',
      artworkStyle: 'original',
    );
  }

  Future<List<StoryMusicEntity>> getFeaturedTracks() async {
    return _featuredTracks;
  }
}
