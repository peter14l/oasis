import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

import 'package:image_picker/image_picker.dart' show XFile;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static bool isInitialized = false;
  
  SupabaseClient? _mockClient;
  late SupabaseClient _client;
  
  factory SupabaseService() {
    if (!isInitialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance;
  }
  
  // Getter for the Supabase client
  SupabaseClient get client => _mockClient ?? _client;
  
  @visibleForTesting
  static void setMockClient(SupabaseClient mockClient) {
    _instance._mockClient = mockClient;
    isInitialized = true;
  }
  
  SupabaseService._internal();
  
  // Initialize Supabase
  static Future<void> initialize() async {
    if (isInitialized) return;
    
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: SupabaseConfig.debug,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      
      _instance._client = Supabase.instance.client;
      isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }
  
  // Auth methods
  GoTrueClient get auth {
    _checkInitialized();
    return client.auth;
  }
  
  // Storage methods
  SupabaseStorageClient get storage {
    _checkInitialized();
    return client.storage;
  }
  
  // Database tables
  SupabaseClient get db {
    _checkInitialized();
    return client;
  }
  
  // Check if user is authenticated
  bool get isAuthenticated {
    _checkInitialized();
    return client.auth.currentUser != null;
  }
  
  // Get current user
  User? get currentUser {
    _checkInitialized();
    return client.auth.currentUser;
  }
  
  // Get current user ID
  String? get currentUserId => currentUser?.id;
  
  // Get current user's email
  String? get currentUserEmail => currentUser?.email;
  
  // Auth state changes
  Stream<AuthState> get onAuthStateChange {
    _checkInitialized();
    return client.auth.onAuthStateChange;
  }
  
  // Sign out
  Future<void> signOut() async {
    _checkInitialized();
    try {
      await client.auth.signOut();
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
    required XFile file,
    FileOptions? fileOptions,
  }) async {
    _checkInitialized();
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await client.storage
            .from(bucket)
            .uploadBinary(path, bytes, fileOptions: fileOptions ?? const FileOptions());
      } else {
        await client.storage
            .from(bucket)
            .upload(path, File(file.path), fileOptions: fileOptions ?? const FileOptions());
      }
      
      return getPublicUrl(bucket, path);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    _checkInitialized();
    try {
      await client.storage
          .from(bucket)
          .remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
  
  // Clear session data (useful for testing)
  @visibleForTesting
  static void reset() {
    isInitialized = false;
  }
  
  // Check if the service is initialized
  void _checkInitialized() {
    if (!isInitialized) {
      throw Exception('SupabaseService not initialized. Call SupabaseService.initialize() first.');
    }
  }
}
