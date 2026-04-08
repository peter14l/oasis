import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oasis/features/messages/core/chat_api_config.dart';

class KlipyService {
  final String _baseUrl = 'https://api.klipy.co/v1';

  Future<List<KlipyMedia>> search(String query, {int limit = 20, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer ${ChatApiConfig.klipyApiKey}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((e) => KlipyMedia.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<KlipyMedia>> getTrending({int limit = 20, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending?limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer ${ChatApiConfig.klipyApiKey}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((e) => KlipyMedia.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
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
