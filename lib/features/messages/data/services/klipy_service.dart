import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oasis/features/messages/core/chat_api_config.dart';

/// Result wrapper that includes error information for debugging
class KlipyResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  bool get isSuccess => error == null && data != null;

  KlipyResult.success(this.data) : error = null, statusCode = 200;

  KlipyResult.failure(this.error, {this.statusCode}) : data = null;
}

class KlipyService {
  final String _baseUrl = 'https://api.klipy.co/v1';
  final bool _debugMode = true; // Set to false in production

  Future<KlipyResult<List<KlipyMedia>>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (ChatApiConfig.klipyApiKey.isEmpty) {
      return KlipyResult.failure(
        'API key is empty. Check .env KLIPY keys (WEB_KEY, etc.)',
        statusCode: 0,
      );
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/search?q=$query&limit=$limit&offset=$offset',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${ChatApiConfig.klipyApiKey}'},
      );

      if (_debugMode) {
        print('[Klipy] Search request: $uri');
        print('[Klipy] Search response status: ${response.statusCode}');
        print('[Klipy] Search response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return KlipyResult.success(
          results.map((e) => KlipyMedia.fromJson(e)).toList(),
        );
      }
      return KlipyResult.failure(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return KlipyResult.failure('Network error: $e', statusCode: -1);
    }
  }

  Future<KlipyResult<List<KlipyMedia>>> getTrending({
    int limit = 20,
    int offset = 0,
  }) async {
    if (ChatApiConfig.klipyApiKey.isEmpty) {
      return KlipyResult.failure(
        'API key is empty. Check .env KLIPY keys (WEB_KEY, etc.)',
        statusCode: 0,
      );
    }

    try {
      final uri = Uri.parse('$_baseUrl/trending?limit=$limit&offset=$offset');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${ChatApiConfig.klipyApiKey}'},
      );

      if (_debugMode) {
        print('[Klipy] Trending request: $uri');
        print('[Klipy] Trending response status: ${response.statusCode}');
        print('[Klipy] Trending response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return KlipyResult.success(
          results.map((e) => KlipyMedia.fromJson(e)).toList(),
        );
      }
      return KlipyResult.failure(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return KlipyResult.failure('Network error: $e', statusCode: -1);
    }
  }
}

class KlipyMedia {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String title;

  KlipyMedia({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.title,
  });

  factory KlipyMedia.fromJson(Map<String, dynamic> json) {
    return KlipyMedia(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      title: json['title'] ?? '',
    );
  }
}
