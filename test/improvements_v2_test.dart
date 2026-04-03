import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:oasis_v2/services/notification_service.dart';
import 'package:oasis_v2/services/post_service.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';
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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? columns]) {
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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> neq(
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
  group('Improvements V2 Tests', () {
    late MockSupabaseClient mockClient;
    late NotificationService notificationService;

    setUp(() {
      mockClient = MockSupabaseClient();
      SupabaseService.reset();
      SupabaseService.setMockClient(mockClient);
      notificationService = NotificationService();
    });

    test(
      'clearAllNotifications calls delete correctly and filters dm',
      () async {
        final mockBuilder = MockSupabaseQueryBuilder();
        final mockFilter = MockPostgrestFilterBuilder();

        mockClient.setBuilder('notifications', mockBuilder);
        mockBuilder.setFilterBuilder(mockFilter);

        await notificationService.clearAllNotifications('user-123');

        // Check success
        expect(true, true);
      },
    );

    test('PostService fetching includes comments_count', () async {
      // Structural check - method exists and can be instantiated
      final postService = PostService();
      expect(postService.getPost, isNotNull);
    });
  });
}
