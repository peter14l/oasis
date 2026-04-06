import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  final Map<String, MockSupabaseQueryBuilder> _tables = {};

  @override
  SupabaseQueryBuilder from(String table) {
    if (!_tables.containsKey(table)) {
      _tables[table] = MockSupabaseQueryBuilder();
    }
    return _tables[table]!;
  }
  
  @override
  GoTrueClient get auth => MockGoTrueClient();
  
  @override
  RealtimeChannel channel(String name, {RealtimeChannelConfig opts = const RealtimeChannelConfig()}) {
    return MockRealtimeChannel();
  }
}

class MockRealtimeChannel extends Mock implements RealtimeChannel {
  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    required String schema,
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeFilter? filter,
  }) {
    // Stub definition for channel builder pattern
    return this;
  }
  
  @override
  void subscribe([void Function(RealtimeSubscribeStatus status, [dynamic error])? callback]) {
    if (callback != null) {
      callback(RealtimeSubscribeStatus.subscribed);
    }
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(
    dynamic values, {
    bool defaultToNull = true,
  }) {
    return MockPostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> upsert(
    dynamic values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return MockPostgrestFilterBuilder();
  }
  
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockPostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(Map<String, dynamic> values) {
    return MockPostgrestFilterBuilder();
  }
}

class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {
  // We mock a generic filter builder that always completes with dummy maps.
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, dynamic value) {
    return this;
  }
  @override
  PostgrestFilterBuilder<dynamic> order(String column, {bool ascending = false, bool nullsFirst = false}) {
    return this;
  }
  @override
  PostgrestTransformBuilder<dynamic> limit(int count, {String? referencedTable}) {
    return MockPostgrestTransformBuilder();
  }
  @override
  Future<dynamic> maybeSingle() async {
    return <String, dynamic>{};
  }
}

class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<dynamic> {
  @override
  Future<dynamic> catchError(Function onError, {bool Function(Object error)? test}) async {
    return [];
  }
}

class MockGoTrueClient extends Mock implements GoTrueClient {
  @override
  User? get currentUser => const User(
    id: 'test-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2023-01-01T00:00:00Z',
  );
}

// Service mocks for bypassing actual network layers during extreme functional stress tests
import 'package:oasis/features/messages/data/chat_messaging_service.dart';
import 'package:oasis/features/messages/data/message_operations_service.dart';
import 'package:oasis/features/messages/domain/models/message.dart';

class MockChatMessagingService extends Mock implements ChatMessagingService {
  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
    String? mediaFileName,
    int? mediaFileSize,
    String? mediaMimeType,
    int? voiceDuration,
    Map<String, String>? encryptedKeys,
    String? iv,
    int? signalMessageType,
    String? signalSenderContent,
    int? signalSenderMessageType,
    int whisperMode = 0,
    String? callId,
    String? replyToId,
    String? rippleId,
    String? storyId,
    String? postId,
    Map<String, dynamic>? shareData,
    String mediaViewMode = 'unlimited',
  }) async {
    // Simulate database delay
    await Future.delayed(const Duration(milliseconds: 10));
    return Message(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      text: content,
      type: messageType,
      createdAt: DateTime.now(),
    );
  }
}

class MockMessageOperationsService extends Mock implements MessageOperationsService {
  int markReadCalls = 0;
  
  @override
  Future<void> markMessagesAsRead(
    String conversationId,
    List<String> messageIds,
    String userId,
  ) async {
    // Simulate database batching latency
    await Future.delayed(const Duration(milliseconds: 20));
    markReadCalls++;
  }
}
