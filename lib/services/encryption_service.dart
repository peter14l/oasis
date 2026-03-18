import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Encryption service using basic_utils for key management and encrypt for operations
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SupabaseClient _supabase = Supabase.instance.client;

  static String _privateKeyKey(String uid) => 'rsa_private_key_$uid';
  static String _publicKeyKey(String uid) => 'rsa_public_key_$uid';
  
  /// Global toggle for E2EE messaging
  static bool isEnabled = true;

  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitialized => _isInitialized;

  /// Initialize encryption service
  Future<EncryptionStatus> init() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return EncryptionStatus.error;

    if (_isInitialized) return EncryptionStatus.ready;

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized ? EncryptionStatus.ready : EncryptionStatus.needsSetup;
    }
    
    _isInitializing = true;
    try {
      // 1. MIGRATION PRIORITY: Check for legacy "ghost" keys first.
      // These are likely the "Good Keys" restored by Google Backup.
      final legacyPrivate = await _secureStorage.read(key: 'rsa_private_key');
      final legacyPublic = await _secureStorage.read(key: 'rsa_public_key');
      
      if (legacyPrivate != null && legacyPublic != null) {
        debugPrint('[Encryption] Found legacy keys. Healing server backup for $userId...');
        
        // Migrate locally
        await _secureStorage.write(key: _privateKeyKey(userId), value: legacyPrivate);
        await _secureStorage.write(key: _publicKeyKey(userId), value: legacyPublic);
        
        // HEAL SERVER: Overwrite the server backup with these known-good keys
        final backupKey = _deriveBackupKey(userId);
        final encryptedPrivateKey = _encryptWithKey(legacyPrivate, backupKey);
        await _supabase.from('profiles').update({
          'public_key': legacyPublic,
          'encrypted_private_key': encryptedPrivateKey,
        }).eq('id', userId);

        // Cleanup ghost keys now that they are safe in the vault
        await _secureStorage.delete(key: 'rsa_private_key');
        await _secureStorage.delete(key: 'rsa_public_key');

        _isInitialized = true;
        _isInitializing = false;
        return EncryptionStatus.ready;
      }

      // 2. Check for existing prefixed keys
      final privateKeyPem = await _secureStorage.read(key: _privateKeyKey(userId));
      final publicKeyPem = await _secureStorage.read(key: _publicKeyKey(userId));

      if (privateKeyPem != null && publicKeyPem != null) {
        debugPrint('[Encryption] Local keys verified for user $userId.');
        _isInitialized = true;
        _isInitializing = false;
        return EncryptionStatus.ready;
      }

      // 3. Try to fetch from server
      debugPrint('[Encryption] No local keys. Checking server for $userId...');
      bool serverHasData = false;
      
      try {
        final response = await _supabase
            .from('profiles')
            .select('encrypted_private_key, public_key')
            .eq('id', userId)
            .maybeSingle();
            
        serverHasData = response != null && 
                        response['encrypted_private_key'] != null && 
                        response['public_key'] != null;
      } catch (e) {
        debugPrint('[Encryption] Server check failed: $e');
        _isInitializing = false;
        return EncryptionStatus.error;
      }

      if (serverHasData) {
        debugPrint('[Encryption] Backup found on server — attempting auto-restore...');
        final restored = await restoreKeys();
        if (restored) {
          _isInitializing = false;
          _isInitialized = true;
          return EncryptionStatus.ready;
        }
        _isInitializing = false;
        return EncryptionStatus.needsRestore;
      }

      // 4. Only if server is confirmed EMPTY, run setup
      debugPrint('[Encryption] No backup on server. Running fresh setup for $userId...');
      final setupSuccess = await setupEncryption();
      if (setupSuccess) {
        _isInitializing = false;
        _isInitialized = true;
        return EncryptionStatus.ready;
      }

      _isInitializing = false;
      return EncryptionStatus.needsSetup;
    } catch (e) {
      _isInitializing = false;
      debugPrint('[Encryption] Unexpected error in init(): $e');
      return EncryptionStatus.error;
    }
  }

  /// Setup encryption (Seamless - No PIN)
  Future<bool> setupEncryption() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[Encryption] setupEncryption: no authenticated user.');
        return false;
      }

      // Generate RSA key pair in the background using compute
      final keySize = kIsWeb ? 1024 : 2048;
      debugPrint('[Encryption] Generating RSA key pair (background, size: $keySize)...');
      final keyPair = await compute(_generateKeyPair, keySize);

      final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        keyPair.privateKey as dynamic,
      );
      final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
        keyPair.publicKey as dynamic,
      );

      // Encrypt private key with derived user key (Seamless)
      final backupKey = _deriveBackupKey(userId);
      final encryptedPrivateKey = _encryptWithKey(privateKeyPem, backupKey);

      // Upload to server
      await _supabase
          .from('profiles')
          .update({
            'public_key': publicKeyPem,
            'encrypted_private_key': encryptedPrivateKey,
          })
          .eq('id', userId);

      // Store keys locally
      await _secureStorage.write(key: _privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: _publicKeyKey(userId), value: publicKeyPem);

      _isInitialized = true;
      debugPrint('[Encryption] Setup complete.');
      return true;
    } catch (e) {
      debugPrint('[Encryption] Error setting up encryption: $e');
      return false;
    }
  }

  /// Force-generate new keys (used as fallback when restore fails).
  /// WARNING: Old encrypted messages will no longer be decryptable after
  /// calling this, since the private key changes.
  Future<bool> generateNewKeys() async {
    debugPrint(
      '[Encryption] Force-generating new keys (old messages will be unreadable)...',
    );
    return setupEncryption();
  }

  /// Restore keys from server backup (Seamless - No PIN)
  Future<bool> restoreKeys() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      debugPrint('[Encryption] Fetching encrypted backup from server...');
      final response = await _supabase
              .from('profiles')
              .select('encrypted_private_key, public_key')
              .eq('id', userId)
              .single();

      final encryptedPrivateKey = response['encrypted_private_key'] as String?;
      final publicKeyPem = response['public_key'] as String?;

      if (encryptedPrivateKey == null || publicKeyPem == null) return false;

      // Decrypt private key with derived user key (Seamless)
      final backupKey = _deriveBackupKey(userId);
      final privateKeyPem = _decryptWithKey(encryptedPrivateKey, backupKey);

      if (privateKeyPem == null) return false;

      // Validate RSA key
      try {
        CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      } catch (e) {
        return false;
      }

      debugPrint('[Encryption] Saving restored keys to secure storage...');
      await _secureStorage.write(key: _privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: _publicKeyKey(userId), value: publicKeyPem);

      _isInitialized = true;
      debugPrint('[Encryption] Keys restored successfully.');
      return true;
    } catch (e) {
      debugPrint('[Encryption] Error restoring keys: $e');
      return false;
    }
  }

  /// Derive a 32-byte key from the User ID for seamless backup encryption
  encrypt.Key _deriveBackupKey(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Generate a new random AES key
  encrypt.Key generateAESKey() {
    return encrypt.Key.fromSecureRandom(32);
  }

  /// Encrypt binary data (files/media) with a specific AES key
  /// Prepends the 16-byte IV to the output
  Uint8List encryptData(Uint8List data, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Prepend IV
    final combined = BytesBuilder();
    combined.add(iv.bytes);
    combined.add(encrypted.bytes);

    return combined.toBytes();
  }

  /// Decrypt binary data (files/media) with a specific AES key
  /// Expects the first 16 bytes to be the IV
  Uint8List? decryptData(Uint8List combinedData, encrypt.Key key) {
    try {
      if (combinedData.length < 16) return null; // Too short

      // Extract IV
      final ivBytes = combinedData.sublist(0, 16);
      final iv = encrypt.IV(ivBytes);

      // Extract Encrypted Data
      final encryptedBytes = combinedData.sublist(16);
      final encrypted = encrypt.Encrypted(encryptedBytes);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      return null;
    }
  }

  /// Encrypt a message text. Can reuse an existing AES key.
  Future<EncryptedMessage> encryptMessage(
    String content,
    List<String> recipientPublicKeysPem, {
    encrypt.Key? reuseKey,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    if (!_isInitialized) {
      throw Exception('Encryption not initialized');
    }

    // Generate or reuse AES key
    final aesKey = reuseKey ?? encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);

    // Encrypt content with AES
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encryptedContent = encrypter.encrypt(content, iv: iv);

    // Encrypt AES key for each recipient with their RSA Public Key
    final encryptedKeys = <String, String>{};
    final publicKeyPem = await _secureStorage.read(key: _publicKeyKey(userId));

    // Add self to recipients so we can read our own messages
    final allPublicKeys = {...recipientPublicKeysPem}; // Set to dedupe
    if (publicKeyPem != null) {
      allPublicKeys.add(publicKeyPem);
    }

    for (final pubKeyPem in allPublicKeys) {
      try {
        final publicKey = CryptoUtils.rsaPublicKeyFromPem(pubKeyPem);
        final rsaEncrypter = encrypt.Encrypter(
          encrypt.RSA(publicKey: publicKey),
        );
        final encryptedKey = rsaEncrypter.encrypt(base64.encode(aesKey.bytes));
        final keyId = _hashPublicKey(pubKeyPem);
        encryptedKeys[keyId] = encryptedKey.base64;
      } catch (e) {
        debugPrint('Error encrypting for recipient: $e');
      }
    }

    return EncryptedMessage(
      encryptedContent: encryptedContent.base64,
      iv: iv.base64,
      encryptedKeys: encryptedKeys,
    );
  }

  /// Decrypt a message
  Future<String?> decryptMessage(
    String encryptedContentBase64,
    Map<String, dynamic> encryptedKeys,
    String ivBase64,
  ) async {
    if (!_isInitialized) {
      await init();
    }
    
    final key = await _decryptAESKey(encryptedKeys);
    if (key == null) return null;

    try {
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encryptedContent = encrypt.Encrypted.fromBase64(
        encryptedContentBase64,
      );

      return encrypter.decrypt(encryptedContent, iv: iv);
    } catch (e) {
      debugPrint('Error decrypting message: $e');
      return null;
    }
  }

  /// Helper to get the raw AES key for a message (used for decrypting attachments)
  Future<encrypt.Key?> getMessageKey(Map<String, dynamic> encryptedKeys) async {
    return _decryptAESKey(encryptedKeys);
  }

  Future<encrypt.Key?> _decryptAESKey(
    Map<String, dynamic> encryptedKeys,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    if (!_isInitialized) await init();

    try {
      // 1. Try with the current user's primary key
      final primaryPrivateKeyPem = await _secureStorage.read(key: _privateKeyKey(userId));
      if (primaryPrivateKeyPem != null) {
        final key = await _tryDecryptWithPrivateKey(primaryPrivateKeyPem, encryptedKeys);
        if (key != null) return key;
      }

      // 2. Fallback: Try legacy non-prefixed key (for users who haven't migrated yet)
      final legacyPrivateKeyPem = await _secureStorage.read(key: 'rsa_private_key');
      if (legacyPrivateKeyPem != null) {
        debugPrint('[Encryption] Attempting decryption with legacy private key...');
        final key = await _tryDecryptWithPrivateKey(legacyPrivateKeyPem, encryptedKeys);
        if (key != null) return key;
      }

      // 3. Last Resort: Try ALL stored private keys on this device
      // This handles the "Account A helps Account B" scenario automatically.
      final allKeys = await _secureStorage.readAll();
      for (final entry in allKeys.entries) {
        if (entry.key.startsWith('rsa_private_key_') && entry.key != _privateKeyKey(userId)) {
          debugPrint('[Encryption] Attempting decryption with alternate key: ${entry.key}');
          final key = await _tryDecryptWithPrivateKey(entry.value, encryptedKeys);
          if (key != null) return key;
        }
      }

      debugPrint('[Encryption] Decryption failed: No valid local key matches this message.');
      return null;
    } catch (e) {
      debugPrint('[Encryption] Error in _decryptAESKey: $e');
      return null;
    }
  }

  /// Brute-force attempt to decrypt the AES key using a specific RSA Private Key
  Future<encrypt.Key?> _tryDecryptWithPrivateKey(
    String privateKeyPem,
    Map<String, dynamic> encryptedKeys,
  ) async {
    try {
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));

      // We don't just look for the Hash ID because it might have changed.
      // We try to decrypt EVERY entry in the map. If it doesn't throw, we found it.
      for (final entry in encryptedKeys.entries) {
        try {
          final encryptedAESKey = encrypt.Encrypted.fromBase64(entry.value as String);
          final decryptedAESKeyBase64 = rsaEncrypter.decrypt(encryptedAESKey);
          return encrypt.Key(base64.decode(decryptedAESKeyBase64));
        } catch (_) {
          // Wrong identity entry, continue to next
          continue;
        }
      }
    } catch (e) {
      // Corrupted PEM or other issue
    }
    return null;
  }

  // Helper methods
  String _encryptWithKey(String data, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Prepend IV to the data (IV is 16 bytes)
    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);
    
    return base64.encode(combined);
  }

  String? _decryptWithKey(String encryptedDataBase64, encrypt.Key key) {
    try {
      final combined = base64.decode(encryptedDataBase64);
      if (combined.length < 16) return null;

      final iv = encrypt.IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);
      final encrypted = encrypt.Encrypted(encryptedBytes);

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('[Encryption] _decryptWithKey failed: $e');
      return null;
    }
  }

  String _hashPublicKey(String publicKeyPem) {
    // Normalize PEM: Remove headers, footers, and ALL whitespace/newlines
    // to ensure the hash is consistent regardless of formatting variations.
    final normalized = publicKeyPem
        .replaceAll(RegExp(r'-----(BEGIN|END)[\w\s]+-----'), '')
        .replaceAll(RegExp(r'\s+'), '');
        
    // Standardize to 16 chars for the key map
    return sha256.convert(utf8.encode(normalized)).toString().substring(0, 16);
  }

  Future<void> clearKeys() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _secureStorage.delete(key: _privateKeyKey(userId));
      await _secureStorage.delete(key: _publicKeyKey(userId));
    }
    // We explicitly do NOT call deleteAll() here to preserve legacy keys 
    // and keys belonging to other logged-out accounts on this device.
    _isInitialized = false;
  }

  /// Backup Signal Identity to server
  Future<bool> backupSignalIdentity(String identityKeyPairBase64, int registrationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final backupKey = _deriveBackupKey(userId);
      final data = jsonEncode({
        'identityKeyPair': identityKeyPairBase64,
        'registrationId': registrationId,
      });
      
      final encryptedData = _encryptWithKey(data, backupKey);

      await _supabase.from('profiles').update({
        'encrypted_signal_identity': encryptedData,
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('[Encryption] backupSignalIdentity failed: $e');
      return false;
    }
  }

  /// Restore Signal Identity from server
  Future<Map<String, dynamic>?> restoreSignalIdentity() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('encrypted_signal_identity')
          .eq('id', userId)
          .single();

      final encryptedData = response['encrypted_signal_identity'] as String?;
      if (encryptedData == null) return null;

      final backupKey = _deriveBackupKey(userId);
      final decryptedData = _decryptWithKey(encryptedData, backupKey);
      
      if (decryptedData == null) return null;

      return jsonDecode(decryptedData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Encryption] restoreSignalIdentity failed: $e');
      return null;
    }
  }
}

/// Standalone function for compute()
AsymmetricKeyPair _generateKeyPair(int keySize) {
  return CryptoUtils.generateRSAKeyPair(keySize: keySize);
}

enum EncryptionStatus { ready, needsSetup, needsRestore, error }

class EncryptedMessage {
  final String encryptedContent;
  final String iv;
  final Map<String, String> encryptedKeys;

  EncryptedMessage({
    required this.encryptedContent,
    required this.iv,
    required this.encryptedKeys,
  });
}
