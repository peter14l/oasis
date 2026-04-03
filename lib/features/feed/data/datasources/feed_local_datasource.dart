import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local datasource for feed caching.
///
/// Handles SharedPreferences-based caching of feed data
/// to enable offline display and faster initial load.
class FeedLocalDatasource {
  static const String _feedKey = 'cached_feed';

  /// Save feed data to local cache.
  Future<void> saveFeed(List<Map<String, dynamic>> feedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(feedData);
      await prefs.setString(_feedKey, jsonString);
    } catch (e) {
      debugPrint('[FeedLocalDatasource] Save cache error: $e');
    }
  }

  /// Load feed data from local cache.
  Future<List<Map<String, dynamic>>> getFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_feedKey);
      if (jsonString == null) return [];

      final decoded = jsonDecode(jsonString);
      return (decoded as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[FeedLocalDatasource] Load cache error: $e');
      return [];
    }
  }

  /// Clear the feed cache.
  Future<void> clearFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedKey);
    } catch (e) {
      debugPrint('[FeedLocalDatasource] Clear cache error: $e');
    }
  }
}
