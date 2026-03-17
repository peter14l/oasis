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

  static const String _privateKeyKey = 'rsa_private_key';
  static const String _publicKeyKey = 'rsa_public_key';
  
  /// Global toggle for E2EE messaging
  static bool isEnabled = true;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize encryption service
  Future<EncryptionStatus> init() async {
    try {
      // Check if keys exist in secure storage
      final privateKeyPem = await _secureStorage.read(key: _privateKeyKey);
      final publicKeyPem = await _secureStorage.read(key: _publicKeyKey);

      if (privateKeyPem != null && publicKeyPem != null) {
        _isInitialized = true;
        return EncryptionStatus.ready;
      }

      // No local keys — check Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        try {
          final response =
              await _supabase
                  .from('profiles')
                  .select('encrypted_private_key, public_key')
                  .eq('id', userId)
                  .single();

          if (response['encrypted_private_key'] != null &&
              response['public_key'] != null) {
            // Server backup exists — try to restore it
            debugPrint(
              '[Encryption] Backup found on server — attempting auto-restore...',
            );
            final restored = await restoreKeys();
            if (restored) {
              debugPrint('[Encryption] Auto-restore successful.');
              return EncryptionStatus.ready;
            }

            // Restore failed. The backup is likely from an incompatible/older
            // encryption scheme (pad block error). It cannot be recovered.
            // Silently generate a fresh key pair so the user can keep using
            // the app — old messages will remain locked, but everything going
            // forward works instantly (same approach WhatsApp uses).
            debugPrint(
              '[Encryption] Backup is unrecoverable (wrong key/scheme). '
              'Auto-generating fresh keys...',
            );
            final freshSuccess = await setupEncryption();
            if (freshSuccess) {
              debugPrint('[Encryption] Fresh keys generated successfully.');
              return EncryptionStatus.ready;
            }

            // Both restore AND fresh generation failed → genuine outage
            debugPrint(
              '[Encryption] Fresh key generation also failed — network issue?',
            );
            return EncryptionStatus.needsRestore;
          }
        } catch (e) {
          debugPrint('[Encryption] No backup found or network error: $e');
        }

        // No backup on server at all → first-time setup
        debugPrint(
          '[Encryption] No backup on server — running first-time setup...',
        );
        final setupSuccess = await setupEncryption();
        if (setupSuccess) return EncryptionStatus.ready;
      }

      return EncryptionStatus.needsSetup;
    } catch (e) {
      debugPrint('[Encryption] Error initializing encryption: $e');
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
      // Using 1024 on Web to avoid long freezes, 2048 elsewhere
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

      // Upload to server FIRST so the backup always exists before we rely on local keys.
      // Using update (not upsert) — every authenticated user already has a profile row.
      await _supabase
          .from('profiles')
          .update({
            'public_key': publicKeyPem,
            'encrypted_private_key': encryptedPrivateKey,
          })
          .eq('id', userId);

      // Store keys locally only after the server backup is confirmed
      await _secureStorage.write(key: _privateKeyKey, value: privateKeyPem);
      await _secureStorage.write(key: _publicKeyKey, value: publicKeyPem);

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
      if (userId == null) {
        debugPrint('[Encryption] restoreKeys: no authenticated user.');
        return false;
      }

      debugPrint('[Encryption] Fetching encrypted backup from server...');
      final response =
          await _supabase
              .from('profiles')
              .select('encrypted_private_key, public_key')
              .eq('id', userId)
              .single();

      final encryptedPrivateKey = response['encrypted_private_key'] as String?;
      final publicKeyPem = response['public_key'] as String?;

      if (encryptedPrivateKey == null) {
        debugPrint(
          '[Encryption] restoreKeys: no encrypted_private_key on server.',
        );
        return false;
      }
      if (publicKeyPem == null) {
        debugPrint('[Encryption] restoreKeys: no public_key on server.');
        return false;
      }

      // Decrypt private key with derived user key (Seamless)
      debugPrint('[Encryption] Decrypting private key from backup...');
      final backupKey = _deriveBackupKey(userId);
      final privateKeyPem = _decryptWithKey(encryptedPrivateKey, backupKey);

      if (privateKeyPem == null) {
        debugPrint(
          '[Encryption] restoreKeys: decryption of private key failed. Key may be corrupted or was encrypted with a different method.',
        );
        return false;
      }

      // Validate that the decrypted PEM is a valid RSA key before storing
      try {
        CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      } catch (e) {
        debugPrint(
          '[Encryption] restoreKeys: decrypted data is not a valid RSA private key: $e',
        );
        return false;
      }

      debugPrint('[Encryption] Saving restored keys to secure storage...');
      await _secureStorage.write(key: _privateKeyKey, value: privateKeyPem);
      await _secureStorage.write(key: _publicKeyKey, value: publicKeyPem);

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
    final publicKeyPem = await _secureStorage.read(key: _publicKeyKey);

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
    if (!_isInitialized) return null;

    try {
      final privateKeyPem = await _secureStorage.read(key: _privateKeyKey);
      final publicKeyPem = await _secureStorage.read(key: _publicKeyKey);

      if (privateKeyPem == null || publicKeyPem == null) return null;

      final keyId = _hashPublicKey(publicKeyPem);
      final encryptedKeyBase64 = encryptedKeys[keyId] as String?;

      if (encryptedKeyBase64 == null) {
        debugPrint('No encrypted key found for this user');
        return null;
      }

      // Decrypt the AES key using our RSA Private Key
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(privateKey: privateKey),
      );
      final encryptedKey = encrypt.Encrypted.fromBase64(encryptedKeyBase64);
      final aesKeyBase64 = rsaEncrypter.decrypt(encryptedKey);
      return encrypt.Key(base64.decode(aesKeyBase64));
    } catch (e) {
      debugPrint('Error decrypting AES key: $e');
      return null;
    }
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
      // If direct decryption failed, try the legacy zero-IV method for ONE LAST transition
      try {
        final iv = encrypt.IV.fromLength(16);
        final encrypter = encrypt.Encrypter(encrypt.AES(key)); // Default mode
        return encrypter.decrypt64(encryptedDataBase64, iv: iv);
      } catch (legacyError) {
        debugPrint('[Encryption] Legacy fallback also failed: $legacyError');
      }
      return null;
    }
  }

  String _hashPublicKey(String publicKeyPem) {
    // Standardize to 16 chars for the key map
    return sha256.convert(utf8.encode(publicKeyPem)).toString().substring(0, 16);
  }

  Future<void> clearKeys() async {
    await _secureStorage.deleteAll();
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
