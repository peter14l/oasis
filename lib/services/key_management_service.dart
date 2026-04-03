import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

enum EncryptionStatus { ready, needsSetup, needsRestore, error }

/// Service for managing the lifecycle of cryptographic keys.
/// 
/// Handles derivation of backup keys from user IDs, generation of RSA key pairs,
/// hashing of public keys for identification, and AES encryption/decryption 
/// of private keys for secure server-side storage (auto-restore).
class KeyManagementService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the secure storage key for a user's private RSA key.
  static String privateKeyKey(String uid) => 'rsa_private_key_$uid';

  /// Returns the secure storage key for a user's public RSA key.
  static String publicKeyKey(String uid) => 'rsa_public_key_$uid';

  /// Derives a 32-byte key from the User ID for seamless backup encryption.
  encrypt.Key deriveBackupKey(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Normalizes and hashes a public key for consistent identification.
  String hashPublicKey(String publicKeyPem) {
    final normalized = publicKeyPem
        .replaceAll(RegExp(r'-----(BEGIN|END)[\w\s]+-----'), '')
        .replaceAll(RegExp(r'\s+'), '');
    return sha256.convert(utf8.encode(normalized)).toString().substring(0, 16);
  }

  /// Encrypts data with a specific key (used for backups).
  String encryptWithKey(String data, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);

    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// Decrypts data with a specific key (used for restores).
  String? decryptWithKey(String encryptedDataBase64, encrypt.Key key) {
    try {
      final combined = base64.decode(encryptedDataBase64);
      if (combined.length < 16) return null;

      final iv = encrypt.IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);
      final encrypted = encrypt.Encrypted(encryptedBytes);

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('[KeyManager] Decryption failed: $e');
      return null;
    }
  }

  /// Generates a new RSA key pair.
  Future<AsymmetricKeyPair> generateKeyPair(int keySize) async {
    return await compute(_generateKeyPairInternal, keySize);
  }
}

AsymmetricKeyPair _generateKeyPairInternal(int keySize) {
  return CryptoUtils.generateRSAKeyPair(keySize: keySize);
}
