import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static bool _isInitialized = false;
  
  late final SupabaseClient _client;
  
  factory SupabaseService() {
    if (!_isInitialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance;
  }
  
  // Getter for the Supabase client
  SupabaseClient get client => _client;
  
  SupabaseService._internal();
  
  // Initialize Supabase
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Make sure environment variables are loaded
      await dotenv.load(fileName: ".env");
      
      await Supabase.initialize(
        url: dotenv.get('SUPABASE_URL'),
        anonKey: dotenv.get('SUPABASE_ANON_KEY'),
        debug: true,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      
      _instance._client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }
  
  // Auth methods
  GoTrueClient get auth {
    _checkInitialized();
    return _client.auth;
  }
  
  // Storage methods
  SupabaseStorageClient get storage {
    _checkInitialized();
    return _client.storage;
  }
  
  // Database tables
  SupabaseClient get db {
    _checkInitialized();
    return _client;
  }
  
  // Check if user is authenticated
  bool get isAuthenticated {
    _checkInitialized();
    return _client.auth.currentUser != null;
  }
  
  // Get current user
  User? get currentUser {
    _checkInitialized();
    return _client.auth.currentUser;
  }
  
  // Get current user ID
  String? get currentUserId => currentUser?.id;
  
  // Get current user's email
  String? get currentUserEmail => currentUser?.email;
  
  // Auth state changes
  Stream<AuthState> get onAuthStateChange {
    _checkInitialized();
    return _client.auth.onAuthStateChange;
  }
  
  // Sign out
  Future<void> signOut() async {
    _checkInitialized();
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Get public URL for storage file
  String getPublicUrl(String bucket, String path) {
    _checkInitialized();
    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';
  }
  
  // Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    FileOptions? fileOptions,
  }) async {
    _checkInitialized();
    try {
      await _client.storage
          .from(bucket)
          .upload(path, file, fileOptions: fileOptions ?? const FileOptions());
      
      return getPublicUrl(bucket, path);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    _checkInitialized();
    try {
      await _client.storage
          .from(bucket)
          .remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
  
  // Clear session data (useful for testing)
  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
  
  // Check if the service is initialized
  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('SupabaseService not initialized. Call SupabaseService.initialize() first.');
    }
  }
}
