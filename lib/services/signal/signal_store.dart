import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// A persistent implementation of SignalProtocolStore using flutter_secure_storage
/// for identity keys, and SharedPreferences for session/prekey state.
class PersistentSignalStore implements SignalProtocolStore {
  final InMemorySignalProtocolStore _inMemoryStore;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final SharedPreferences _prefs;

  bool _initialized = false;
  
  // Keys for SharedPreferences / Secure Storage
  static const String _identityKeyPairKey = 'signal_identity_key_pair';
  static const String _localRegistrationIdKey = 'signal_registration_id';
  static const String _sessionsKeyPrefix = 'signal_session_';
  static const String _preKeysKeyPrefix = 'signal_prekey_';
  static const String _signedPreKeyKeyPrefix = 'signal_signed_prekey_';

  PersistentSignalStore(IdentityKeyPair identityKeyPair, int registrationId)
      : _inMemoryStore = InMemorySignalProtocolStore(identityKeyPair, registrationId);

  /// Check if local keys exist
  static Future<bool> hasKeys() async {
    const secureStorage = FlutterSecureStorage();
    final identityKeyString = await secureStorage.read(key: _identityKeyPairKey);
    final registrationIdString = await secureStorage.read(key: _localRegistrationIdKey);
    return identityKeyString != null && registrationIdString != null;
  }

  /// Check if we have any pre-keys stored locally
  Future<bool> hasPreKeys() async {
    final keys = _prefs.getKeys();
    return keys.any((k) => k.startsWith(_preKeysKeyPrefix));
  }

  /// Check if we have any signed pre-keys stored locally
  Future<bool> hasSignedPreKeys() async {
    final keys = _prefs.getKeys();
    return keys.any((k) => k.startsWith(_signedPreKeyKeyPrefix));
  }

  /// Manually save keys and initialize (used for restoration)
  static Future<PersistentSignalStore> saveAndInit(IdentityKeyPair identityKeyPair, int registrationId) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    await secureStorage.write(
        key: _identityKeyPairKey, 
        value: base64Encode(identityKeyPair.serialize())
    );
    await secureStorage.write(
        key: _localRegistrationIdKey, 
        value: registrationId.toString()
    );

    final store = PersistentSignalStore(identityKeyPair, registrationId);
    store._prefs = prefs;
    await store._loadState();
    store._initialized = true;
    return store;
  }

  static Future<PersistentSignalStore> init() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    // Load or generate Identity Key Pair
    final identityKeyString = await secureStorage.read(key: _identityKeyPairKey);
    final registrationIdString = await secureStorage.read(key: _localRegistrationIdKey);

    IdentityKeyPair identityKeyPair;
    int registrationId;

    if (identityKeyString != null && registrationIdString != null) {
      identityKeyPair = IdentityKeyPair.fromSerialized(base64Decode(identityKeyString));
      registrationId = int.parse(registrationIdString);
    } else {
      // Generate new keys
      identityKeyPair = generateIdentityKeyPair();
      registrationId = generateRegistrationId(false);
      
      await secureStorage.write(
          key: _identityKeyPairKey, 
          value: base64Encode(identityKeyPair.serialize())
      );
      await secureStorage.write(
          key: _localRegistrationIdKey, 
          value: registrationId.toString()
      );
    }

    final store = PersistentSignalStore(identityKeyPair, registrationId);
    store._prefs = prefs;

    // Load existing sessions, prekeys, and signed prekeys into _inMemoryStore
    await store._loadState();
    store._initialized = true;

    return store;
  }

  Future<void> _loadState() async {
    final existingKeys = _prefs.getKeys();

    for (final key in existingKeys) {
      if (key.startsWith(_sessionsKeyPrefix)) {
        final addressName = key.replaceFirst(_sessionsKeyPrefix, '');
        // format is name_deviceId
        final parts = addressName.split('_');
        if (parts.length == 2) {
          final address = SignalProtocolAddress(parts[0], int.parse(parts[1]));
          final sessionData = _prefs.getString(key);
          if (sessionData != null) {
            final record = SessionRecord.fromSerialized(base64Decode(sessionData));
            _inMemoryStore.storeSession(address, record);
          }
        }
      } else if (key.startsWith(_preKeysKeyPrefix)) {
        final preKeyId = int.tryParse(key.replaceFirst(_preKeysKeyPrefix, ''));
        if (preKeyId != null) {
          final preKeyData = _prefs.getString(key);
          if (preKeyData != null) {
            final record = PreKeyRecord.fromBuffer(base64Decode(preKeyData));
            _inMemoryStore.storePreKey(preKeyId, record);
          }
        }
      } else if (key.startsWith(_signedPreKeyKeyPrefix)) {
        final signedPreKeyId = int.tryParse(key.replaceFirst(_signedPreKeyKeyPrefix, ''));
        if (signedPreKeyId != null) {
          final stringData = _prefs.getString(key);
          if (stringData != null) {
            final record = SignedPreKeyRecord.fromSerialized(base64Decode(stringData));
            _inMemoryStore.storeSignedPreKey(signedPreKeyId, record);
          }
        }
      }
    }
  }

  // --- IdentityKeyStore ---

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async {
    return _inMemoryStore.getIdentityKeyPair();
  }

  @override
  Future<int> getLocalRegistrationId() async {
    return _inMemoryStore.getLocalRegistrationId();
  }

  @override
  Future<bool> saveIdentity(SignalProtocolAddress address, IdentityKey? identityKey) async {
    final result = await _inMemoryStore.saveIdentity(address, identityKey);
    // Identity saving happens on session builds. We might want to persist it.
    // InMemorySignalProtocolStore manages trusted identities internally.
    return result;
  }

  @override
  Future<bool> isTrustedIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey, Direction direction) async {
    return _inMemoryStore.isTrustedIdentity(address, identityKey, direction);
  }

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    return _inMemoryStore.getIdentity(address);
  }

  // --- SessionStore ---

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    return _inMemoryStore.loadSession(address);
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    return _inMemoryStore.getSubDeviceSessions(name);
  }

  @override
  Future<void> storeSession(SignalProtocolAddress address, SessionRecord record) async {
    await _inMemoryStore.storeSession(address, record);
    // Persist to SharedPreferences
    final key = '$_sessionsKeyPrefix${address.getName()}_${address.getDeviceId()}';
    await _prefs.setString(key, base64Encode(record.serialize()));
  }

  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    return _inMemoryStore.containsSession(address);
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await _inMemoryStore.deleteSession(address);
    final key = '$_sessionsKeyPrefix${address.getName()}_${address.getDeviceId()}';
    await _prefs.remove(key);
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    await _inMemoryStore.deleteAllSessions(name);
    final existingKeys = _prefs.getKeys();
    for (final key in existingKeys) {
      if (key.startsWith('$_sessionsKeyPrefix${name}_')) {
        await _prefs.remove(key);
      }
    }
  }

  // --- PreKeyStore ---

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    return _inMemoryStore.loadPreKey(preKeyId);
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    await _inMemoryStore.storePreKey(preKeyId, record);
    await _prefs.setString('$_preKeysKeyPrefix$preKeyId', base64Encode(record.serialize()));
  }

  @override
  Future<bool> containsPreKey(int preKeyId) async {
    return _inMemoryStore.containsPreKey(preKeyId);
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    await _inMemoryStore.removePreKey(preKeyId);
    await _prefs.remove('$_preKeysKeyPrefix$preKeyId');
  }

  // --- SignedPreKeyStore ---

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    return _inMemoryStore.loadSignedPreKey(signedPreKeyId);
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    return _inMemoryStore.loadSignedPreKeys();
  }

  @override
  Future<void> storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) async {
    await _inMemoryStore.storeSignedPreKey(signedPreKeyId, record);
    await _prefs.setString('$_signedPreKeyKeyPrefix$signedPreKeyId', base64Encode(record.serialize()));
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    return _inMemoryStore.containsSignedPreKey(signedPreKeyId);
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    await _inMemoryStore.removeSignedPreKey(signedPreKeyId);
    await _prefs.remove('$_signedPreKeyKeyPrefix$signedPreKeyId');
  }

  /// Wipe everything from the store
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _identityKeyPairKey);
    await _secureStorage.delete(key: _localRegistrationIdKey);
    
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_sessionsKeyPrefix) ||
          key.startsWith(_preKeysKeyPrefix) ||
          key.startsWith(_signedPreKeyKeyPrefix)) {
        await _prefs.remove(key);
      }
    }
    _initialized = false;
  }
}
