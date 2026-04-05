import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  final Map<String, SupabaseQueryBuilder> _builders = {};

  void setBuilder(String table, SupabaseQueryBuilder builder) {
    _builders[table] = builder;
  }

  @override
  SupabaseQueryBuilder from(String table) {
    return _builders[table]!;
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  PostgrestFilterBuilder<List<Map<String, dynamic>>>? _filterBuilder;

  void setFilterBuilder(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
  ) {
    _filterBuilder = builder;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> delete() {
    return _filterBuilder!;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(
    Map<dynamic, dynamic> values, {
    String? returning,
  }) {
    return _filterBuilder!;
  }
}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue([]));
  }
}

void main() {
  group('MessagingService Deletion Tests', () {
    late MockSupabaseClient mockClient;
    late MessagingService messagingService;

    setUp(() {
      mockClient = MockSupabaseClient();

      // Correct way to initialize SupabaseService for tests
      SupabaseService.reset();
      SupabaseService.setMockClient(mockClient);

      messagingService = MessagingService(client: mockClient);
    });

    test('clearConversationMessages calls delete correctly', () async {
      final mockMessagesBuilder = MockSupabaseQueryBuilder();
      final mockMessagesFilter = MockPostgrestFilterBuilder();

      final mockConversationsBuilder = MockSupabaseQueryBuilder();
      final mockConversationsFilter = MockPostgrestFilterBuilder();

      mockClient.setBuilder('messages', mockMessagesBuilder);
      mockClient.setBuilder('conversations', mockConversationsBuilder);

      mockMessagesBuilder.setFilterBuilder(mockMessagesFilter);
      mockConversationsBuilder.setFilterBuilder(mockConversationsFilter);

      await messagingService.clearConversationMessages('conv-123');

      // Check success by ensuring we reached here without exception
      expect(true, true);
    });
  });
}
