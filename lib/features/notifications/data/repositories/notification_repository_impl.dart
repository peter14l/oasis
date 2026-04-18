import 'dart:async';
import 'package:oasis/core/result/result.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:oasis/features/notifications/domain/models/notification_entity.dart';
import 'package:oasis/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _remoteDatasource;

  NotificationRepositoryImpl({NotificationRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? NotificationRemoteDatasource();

  @override
  Future<Result<List<AppNotification>>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseService().client.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(message: 'Not authenticated');
      }

      final notifications = await _remoteDatasource.getNotifications(
        userId: userId,
        limit: limit,
        offset: offset,
      );

      return Result.success(notifications);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _remoteDatasource.markAsRead(notificationId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    try {
      final userId = SupabaseService().client.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(message: 'Not authenticated');
      }

      await _remoteDatasource.markAllAsRead(userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<void>> deleteAllNotifications() async {
    try {
      final userId = SupabaseService().client.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(message: 'Not authenticated');
      }

      await _remoteDatasource.deleteAllNotifications(userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final userId = SupabaseService().client.auth.currentUser?.id;
      if (userId == null) {
        return const Result.success(0);
      }

      final count = await _remoteDatasource.getUnreadCount(userId);
      return Result.success(count);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Stream<List<AppNotification>> get notificationsStream {
    // For now, return an empty stream - realtime can be added later
    return const Stream.empty();
  }
}
