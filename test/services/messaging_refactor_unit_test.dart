import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:oasis/services/chat_decryption_service.dart';
import 'package:oasis/services/encryption_service.dart';
import 'package:oasis/services/signal/signal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:oasis/services/conversation_service.dart';
import 'package:oasis/services/chat_messaging_service.dart';
import 'package:oasis/services/chat_media_service.dart';
import 'package:oasis/services/message_operations_service.dart';

@GenerateMocks([
  EncryptionService,
  SignalService,
  SupabaseClient,
  ChatDecryptionService,
  ConversationService,
  ChatMessagingService,
  ChatMediaService,
  MessageOperationsService,
])
import 'messaging_refactor_unit_test.mocks.dart';

void main() {
  group('MessagingService Delegation Tests', () {
    late MessagingService messagingService;
    late MockConversationService mockConversation;
    late MockChatMessagingService mockChatMessaging;
    late MockChatMediaService mockChatMedia;
    late MockMessageOperationsService mockMessageOps;

    setUp(() {
      mockConversation = MockConversationService();
      mockChatMessaging = MockChatMessagingService();
      mockChatMedia = MockChatMediaService();
      mockMessageOps = MockMessageOperationsService();

      messagingService = MessagingService(
        conversationService: mockConversation,
        chatMessagingService: mockChatMessaging,
        chatMediaService: mockChatMedia,
        messageOpsService: mockMessageOps,
      );
    });

    test('getConversations should delegate to ConversationService', () async {
      when(mockConversation.getConversations(userId: 'u1')).thenAnswer((_) async => []);
      await messagingService.getConversations(userId: 'u1');
      verify(mockConversation.getConversations(userId: 'u1')).called(1);
    });

    test('sendMessage should delegate to ChatMessagingService', () async {
      // Mocking sendMessage is complex due to many params, using any for brevity in this example
      // Message return value would need to be mocked if we were checking results
      await messagingService.sendMessage(
        conversationId: 'c1',
        senderId: 'u1',
        content: 'hello',
      );
      verify(mockChatMessaging.sendMessage(
        conversationId: 'c1',
        senderId: 'u1',
        content: 'hello',
      )).called(1);
    });

    test('uploadChatMedia should delegate to ChatMediaService', () async {
      when(mockChatMedia.uploadChatMedia('path')).thenAnswer((_) async => 'url');
      await messagingService.uploadChatMedia('path');
      verify(mockChatMedia.uploadChatMedia('path')).called(1);
    });

    test('deleteMessage should delegate to MessageOperationsService', () async {
      await messagingService.deleteMessage('m1');
      verify(mockMessageOps.deleteMessage('m1')).called(1);
    });
  });

  group('ChatDecryptionService Unit Tests', () {
    late ChatDecryptionService decryptionService;
    late MockEncryptionService mockEncryption;
    late MockSignalService mockSignal;

    setUp(() {
      mockEncryption = MockEncryptionService();
      mockSignal = MockSignalService();
      decryptionService = ChatDecryptionService(
        encryptionService: mockEncryption,
        signalService: mockSignal,
      );
    });

    test('Should decrypt received message using Signal Protocol', () async {
      when(mockSignal.init()).thenAnswer((_) async => true);
      when(mockSignal.decryptMessage('s1', 'cipher', 3))
          .thenAnswer((_) async => 'Decrypted');

      final result = await decryptionService.decryptMessageContent(
        senderId: 's1',
        currentUserId: 'me',
        content: 'cipher',
        signalMessageType: 3,
      );

      expect(result, 'Decrypted');
    });
  });
}
