import 'package:flutter/foundation.dart';
import 'package:oasis/features/messages/data/encryption_service.dart';

class EncryptionProvisioner {
  /// Silently provision or restore E2E encryption keys in the background.
  /// Called immediately after every sign-in / sign-up so keys are ready
  /// before the user ever opens a chat (identical to WhatsApp's approach).
  Future<void> provisionEncryptionKeys() async {
    try {
      final encryptionService = EncryptionService();
      final status = await encryptionService.init();
      if (kDebugMode) {}

      if (status == EncryptionStatus.needsSetup) {
        if (kDebugMode) {}
        await encryptionService.setupEncryption();
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }
}
