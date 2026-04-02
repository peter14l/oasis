import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _feedKey = 'cached_feed';
  static const String _storiesKey = 'cached_stories';

  Future<void> saveFeed(List<Map<String, dynamic>> feedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(feedData);
      await prefs.setString(_feedKey, jsonString);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<Map<String, dynamic>>> getFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_feedKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveStories(List<Map<String, dynamic>> storiesData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(storiesData);
      await prefs.setString(_storiesKey, jsonString);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storiesKey);
      if (jsonString == null) return [];

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedKey);
      await prefs.remove(_storiesKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
