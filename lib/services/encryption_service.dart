import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/services/key_management_service.dart';

export 'package:oasis/services/key_management_service.dart' show EncryptionStatus;

/// Provider for cryptographic operations. 
/// 
/// Handles RSA/AES encryption and decryption for messages and media.
/// Orchestrates the initialization and restoration of encryption keys 
/// via [KeyManagementService].
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final KeyManagementService _keyManager = KeyManagementService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool get isInitialized => _isInitialized;

  EncryptionStatus? _lastStatus;

  /// Initializes the encryption system.
  /// 
  /// Checks for local keys, handles legacy key migration, and attempts 
  /// auto-restoration from the server if local keys are missing.
  Future<EncryptionStatus> init() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return EncryptionStatus.error;

    if (_isInitialized && _lastStatus != EncryptionStatus.needsSecurityUpgrade) {
      return _lastStatus ?? EncryptionStatus.ready;
    }

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _lastStatus ?? (_isInitialized ? EncryptionStatus.ready : EncryptionStatus.needsSetup);
    }

    _isInitializing = true;
    try {
      // 1. Migration of legacy ghost keys
      final legacyPrivate = await _secureStorage.read(key: 'rsa_private_key');
      final legacyPublic = await _secureStorage.read(key: 'rsa_public_key');

      if (legacyPrivate != null && legacyPublic != null) {
        debugPrint('[Encryption] Migrating legacy keys for $userId...');
        await _secureStorage.write(key: KeyManagementService.privateKeyKey(userId), value: legacyPrivate);
        await _secureStorage.write(key: KeyManagementService.publicKeyKey(userId), value: legacyPublic);

        final backupKey = _keyManager.deriveLegacyBackupKey(userId);
        final encryptedPrivateKey = _keyManager.encryptWithKey(legacyPrivate, backupKey);
        await _supabase.from('profiles').update({'public_key': legacyPublic, 'encrypted_private_key': encryptedPrivateKey}).eq('id', userId);

        await _secureStorage.delete(key: 'rsa_private_key');
        await _secureStorage.delete(key: 'rsa_public_key');

        _isInitialized = true;
        _isInitializing = false;
        _lastStatus = EncryptionStatus.ready;
        return EncryptionStatus.ready;
      }

      // 2. Check local prefixed keys & Server Status for Upgrade
      final privateKeyPem = await _secureStorage.read(key: KeyManagementService.privateKeyKey(userId));
      final publicKeyPem = await _secureStorage.read(key: KeyManagementService.publicKeyKey(userId));

      // Fetch the security status from the server regardless of local keys
      final response = await _supabase.from('profiles')
          .select('encrypted_private_key, encrypted_private_key_v2, key_salt, public_key, has_upgraded_security')
          .eq('id', userId)
          .maybeSingle();

      if (privateKeyPem != null && publicKeyPem != null) {
        try {
          CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
          
          // Check if this user needs an upgrade (they have local keys, but are still on v1)
          if (response != null && 
              response['has_upgraded_security'] != true && 
              response['encrypted_private_key'] != null) {
            _isInitialized = true; // Still initialized (can decrypt), but needs upgrade
            _isInitializing = false;
            _lastStatus = EncryptionStatus.needsSecurityUpgrade;
            return EncryptionStatus.needsSecurityUpgrade;
          }

          _isInitialized = true;
          _isInitializing = false;
          _lastStatus = EncryptionStatus.ready;
          return EncryptionStatus.ready;
        } catch (e) {
          debugPrint('[Encryption] Local key corruption detected.');
        }
      }

      // 3. Server Check & Auto-Restore (When local keys are MISSING)
      if (response != null) {
        // Check if they have v2 (requires PIN to restore)
        if (response['encrypted_private_key_v2'] != null) {
          _isInitializing = false;
          _lastStatus = EncryptionStatus.needsRestore;
          return EncryptionStatus.needsRestore; // UI must prompt for PIN
        }

        // Check if they only have v1 (Legacy auto-restore)
        if (response['encrypted_private_key'] != null) {
          final restored = await _restoreLegacyKeys(response);
          if (restored) {
            _isInitialized = true;
            _isInitializing = false;
            _lastStatus = EncryptionStatus.needsSecurityUpgrade;
            // Return a special status so the UI knows to ask them to upgrade
            return EncryptionStatus.needsSecurityUpgrade;
          }
        }
      }

      // 4. Fresh Setup
      _isInitializing = false;
      _lastStatus = EncryptionStatus.needsSetup;
      return EncryptionStatus.needsSetup;
    } catch (e) {
      _isInitializing = false;
      _lastStatus = EncryptionStatus.error;
      debugPrint('[Encryption] Init Error: $e');
      return EncryptionStatus.error;
    }
  }

  /// Restores keys from legacy backup (auto-restore).
  Future<bool> _restoreLegacyKeys(Map<String, dynamic> response) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final encryptedPrivateKey = response['encrypted_private_key'] as String?;
      final publicKeyPem = response['public_key'] as String?;
      if (encryptedPrivateKey == null || publicKeyPem == null) return false;

      final backupKey = _keyManager.deriveLegacyBackupKey(userId);
      final privateKeyPem = _keyManager.decryptWithKey(encryptedPrivateKey, backupKey);
      if (privateKeyPem == null) return false;

      await _secureStorage.write(key: KeyManagementService.privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: KeyManagementService.publicKeyKey(userId), value: publicKeyPem);
      return true;
    } catch (e) {
      debugPrint('[Encryption] Legacy Restore Error: $e');
      return false;
    }
  }

  /// Restores keys from the server backup using PIN-derived decryption (v2).
  Future<bool> restoreSecureKeys(String pin) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.from('profiles')
          .select('encrypted_private_key_v2, key_salt, public_key')
          .eq('id', userId)
          .single();

      final encryptedPrivateKey = response['encrypted_private_key_v2'] as String?;
      final salt = response['key_salt'] as String?;
      final publicKeyPem = response['public_key'] as String?;

      if (encryptedPrivateKey == null || salt == null || publicKeyPem == null) return false;

      final secureKey = _keyManager.deriveSecureBackupKey(pin, salt);
      final privateKeyPem = _keyManager.decryptWithKey(encryptedPrivateKey, secureKey);
      if (privateKeyPem == null) return false; // Wrong PIN

      await _secureStorage.write(key: KeyManagementService.privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: KeyManagementService.publicKeyKey(userId), value: publicKeyPem);

      _isInitialized = true;
      _lastStatus = EncryptionStatus.ready;
      return true;
    } catch (e) {
      debugPrint('[Encryption] Secure Restore Error: $e');
      return false;
    }
  }

  /// Upgrades a user from v1 (legacy) to v2 (PIN-based) security.
  Future<bool> upgradeSecurity(String pin) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // 1. Get the current private key from local secure storage
      final privateKeyPem = await _secureStorage.read(key: KeyManagementService.privateKeyKey(userId));
      if (privateKeyPem == null) return false;

      // 2. Generate new salt and derive new secure key
      final salt = _keyManager.generateSalt();
      final secureKey = _keyManager.deriveSecureBackupKey(pin, salt);

      // 3. Encrypt private key with the new secure key
      final encryptedPrivateKeyV2 = _keyManager.encryptWithKey(privateKeyPem, secureKey);

      // 4. Save to Supabase and mark as upgraded
      await _supabase.from('profiles').update({
        'encrypted_private_key_v2': encryptedPrivateKeyV2,
        'key_salt': salt,
        'has_upgraded_security': true,
        // Optional: Set legacy key to null to completely remove the vulnerability
        'encrypted_private_key': null 
      }).eq('id', userId);

      _lastStatus = EncryptionStatus.ready;
      return true;
    } catch (e) {
      debugPrint('[Encryption] Security Upgrade Error: $e');
      return false;
    }
  }

  /// Alias for setupEncryption to support legacy calls.
  Future<bool> generateNewKeys() => setupEncryption();

  /// Sets up a new encryption identity (RSA keys) and backs them up to the server.
  /// 🚩 VULNERABLE: This version uses legacy derivation if PIN is not provided.
  /// Added optional PIN support for fresh setup.
  Future<bool> setupEncryption({String? pin}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final keySize = kIsWeb ? 1024 : 2048;
      final keyPair = await _keyManager.generateKeyPair(keySize);

      final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(keyPair.privateKey as dynamic);
      final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(keyPair.publicKey as dynamic);

      if (pin != null) {
        final salt = _keyManager.generateSalt();
        final secureKey = _keyManager.deriveSecureBackupKey(pin, salt);
        final encryptedPrivateKeyV2 = _keyManager.encryptWithKey(privateKeyPem, secureKey);

        await _supabase.from('profiles').update({
          'public_key': publicKeyPem,
          'encrypted_private_key_v2': encryptedPrivateKeyV2,
          'key_salt': salt,
          'has_upgraded_security': true
        }).eq('id', userId);
      } else {
        final backupKey = _keyManager.deriveLegacyBackupKey(userId);
        final encryptedPrivateKey = _keyManager.encryptWithKey(privateKeyPem, backupKey);

        await _supabase.from('profiles').update({
          'public_key': publicKeyPem,
          'encrypted_private_key': encryptedPrivateKey
        }).eq('id', userId);
      }

      await _secureStorage.write(key: KeyManagementService.privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: KeyManagementService.publicKeyKey(userId), value: publicKeyPem);

      _isInitialized = true;
      _lastStatus = EncryptionStatus.ready;
      return true;
    } catch (e) {
      debugPrint('[Encryption] Setup Error: $e');
      return false;
    }
  }

  /// Restores keys from the server backup using seamless ID-derived decryption.
  /// Deprecated: Use init() and restoreSecureKeys(pin) instead.
  @deprecated
  Future<bool> restoreKeys() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.from('profiles').select('encrypted_private_key, public_key').eq('id', userId).single();
      final encryptedPrivateKey = response['encrypted_private_key'] as String?;
      final publicKeyPem = response['public_key'] as String?;

      if (encryptedPrivateKey == null || publicKeyPem == null) return false;

      final backupKey = _keyManager.deriveLegacyBackupKey(userId);
      final privateKeyPem = _keyManager.decryptWithKey(encryptedPrivateKey, backupKey);
      if (privateKeyPem == null) return false;

      await _secureStorage.write(key: KeyManagementService.privateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: KeyManagementService.publicKeyKey(userId), value: publicKeyPem);

      _isInitialized = true;
      _lastStatus = EncryptionStatus.ready;
      return true;
    } catch (e) {
      debugPrint('[Encryption] Restore Error: $e');
      return false;
    }
  }

  // --- Cryptographic Operations ---

  encrypt.Key generateAESKey() => encrypt.Key.fromSecureRandom(32);

  Uint8List encryptData(Uint8List data, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return (BytesBuilder()..add(iv.bytes)..add(encrypted.bytes)).toBytes();
  }

  Uint8List? decryptData(Uint8List combinedData, encrypt.Key key) {
    try {
      if (combinedData.length < 16) return null;
      final iv = encrypt.IV(combinedData.sublist(0, 16));
      final encrypted = encrypt.Encrypted(combinedData.sublist(16));
      return Uint8List.fromList(encrypt.Encrypter(encrypt.AES(key)).decryptBytes(encrypted, iv: iv));
    } catch (e) {
      debugPrint('[Encryption] Data Decrypt Error: $e');
      return null;
    }
  }

  Future<EncryptedMessage> encryptMessage(String content, List<String> recipientPublicKeysPem, {encrypt.Key? reuseKey}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !_isInitialized) throw Exception('Encryption not ready');

    final aesKey = reuseKey ?? generateAESKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encryptedContent = encrypt.Encrypter(encrypt.AES(aesKey)).encrypt(content, iv: iv);

    final encryptedKeys = <String, String>{};
    final myPublicKey = await _secureStorage.read(key: KeyManagementService.publicKeyKey(userId));
    
    final allKeys = {...recipientPublicKeysPem};
    if (myPublicKey != null) allKeys.add(myPublicKey);

    for (final pubKeyPem in allKeys) {
      try {
        final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(publicKey: CryptoUtils.rsaPublicKeyFromPem(pubKeyPem)));
        final encryptedKey = rsaEncrypter.encrypt(base64.encode(aesKey.bytes));
        encryptedKeys[_keyManager.hashPublicKey(pubKeyPem)] = encryptedKey.base64;
      } catch (e) {
        debugPrint('[Encryption] Recipient Encrypt Error: $e');
      }
    }

    return EncryptedMessage(encryptedContent: encryptedContent.base64, iv: iv.base64, encryptedKeys: encryptedKeys);
  }

  Future<String?> decryptMessage(String encryptedContentBase64, Map<String, dynamic> encryptedKeys, String ivBase64) async {
    final key = await _decryptAESKey(encryptedKeys);
    if (key == null) return null;
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedContentBase64), iv: encrypt.IV.fromBase64(ivBase64));
    } catch (e) {
      debugPrint('[Encryption] Message Decrypt Error: $e');
      return null;
    }
  }

  Future<encrypt.Key?> _decryptAESKey(Map<String, dynamic> encryptedKeys) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    if (!_isInitialized) await init();

    final primaryKey = await _secureStorage.read(key: KeyManagementService.privateKeyKey(userId));
    if (primaryKey != null) {
      final key = await _tryDecryptWithPrivateKey(primaryKey, encryptedKeys);
      if (key != null) return key;
    }

    final allKeys = await _secureStorage.readAll();
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith('rsa_private_key_')) {
        final key = await _tryDecryptWithPrivateKey(entry.value, encryptedKeys);
        if (key != null) return key;
      }
    }
    return null;
  }

  Future<encrypt.Key?> _tryDecryptWithPrivateKey(String privateKeyPem, Map<String, dynamic> encryptedKeys) async {
    try {
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(privateKey: CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem)));
      for (final entry in encryptedKeys.entries) {
        try {
          return encrypt.Key(base64.decode(rsaEncrypter.decrypt(encrypt.Encrypted.fromBase64(entry.value as String))));
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // --- Signal Support ---

  Future<bool> backupSignalIdentity(String identityKeyPairBase64, int registrationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final encrypted = _keyManager.encryptWithKey(jsonEncode({'identityKeyPair': identityKeyPairBase64, 'registrationId': registrationId}), _keyManager.deriveLegacyBackupKey(userId));
      await _supabase.from('profiles').update({'encrypted_signal_identity': encrypted}).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> restoreSignalIdentity() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _supabase.from('profiles').select('encrypted_signal_identity').eq('id', userId).single();
      final decrypted = _keyManager.decryptWithKey(response['encrypted_signal_identity'] as String, _keyManager.deriveLegacyBackupKey(userId));
      return decrypted != null ? jsonDecode(decrypted) as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearKeys() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _secureStorage.delete(key: KeyManagementService.privateKeyKey(userId));
      await _secureStorage.delete(key: KeyManagementService.publicKeyKey(userId));
    }
    _isInitialized = false;
  }
}

class EncryptedMessage {
  final String encryptedContent;
  final String iv;
  final Map<String, String> encryptedKeys;
  EncryptedMessage({required this.encryptedContent, required this.iv, required this.encryptedKeys});
}
