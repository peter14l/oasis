import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/notifications/domain/models/notification_entity.dart';

abstract class NotificationRepository {
  Future<Result<List<AppNotification>>> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  Future<Result<void>> markAsRead(String notificationId);

  Future<Result<void>> markAllAsRead();

  Future<Result<void>> deleteAllNotifications();

  Future<Result<int>> getUnreadCount();

  Stream<List<AppNotification>> get notificationsStream;
}
