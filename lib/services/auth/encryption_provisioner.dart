import 'dart:developer' as developer;
import 'package:oasis/features/messages/data/encryption_service.dart';

class EncryptionProvisioner {
  /// Silently provision or restore E2E encryption keys in the background.
  /// Called immediately after every sign-in / sign-up so keys are ready
  /// before the user ever opens a chat (identical to WhatsApp's approach).
  Future<void> provisionEncryptionKeys() async {
    try {
      final status = await EncryptionService().init();
      developer.log('[Auth] Encryption init status after login: $status');
    } catch (e) {
      developer.log('[Auth] Encryption init error after login: $e');
    }
  }
}
