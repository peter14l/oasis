import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/data/encryption_service.dart';

void main() {
  group('EncryptionStatus enum', () {
    test('should have all expected statuses', () {
      expect(EncryptionStatus.values, contains(EncryptionStatus.ready));
      expect(EncryptionStatus.values, contains(EncryptionStatus.needsSetup));
      expect(EncryptionStatus.values, contains(EncryptionStatus.needsRestore));
      expect(
        EncryptionStatus.values,
        contains(EncryptionStatus.needsSecurityUpgrade),
      );
      expect(
        EncryptionStatus.values,
        contains(EncryptionStatus.needsRecoveryBackup),
      );
      expect(EncryptionStatus.values, contains(EncryptionStatus.error));
    });

    test('should have correct number of statuses', () {
      expect(EncryptionStatus.values.length, equals(6));
    });
  });
}
