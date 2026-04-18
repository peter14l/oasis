import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/notifications/domain/models/notification_entity.dart';
import 'package:oasis/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;

  GetNotifications(this._repository);

  Future<Result<List<AppNotification>>> call({int limit = 50, int offset = 0}) {
    return _repository.getNotifications(limit: limit, offset: offset);
  }
}

class MarkNotificationRead {
  final NotificationRepository _repository;

  MarkNotificationRead(this._repository);

  Future<Result<void>> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

class MarkAllNotificationsRead {
  final NotificationRepository _repository;

  MarkAllNotificationsRead(this._repository);

  Future<Result<void>> call() {
    return _repository.markAllAsRead();
  }
}

class DeleteAllNotifications {
  final NotificationRepository _repository;

  DeleteAllNotifications(this._repository);

  Future<Result<void>> call() {
    return _repository.deleteAllNotifications();
  }
}

class GetUnreadNotificationCount {
  final NotificationRepository _repository;

  GetUnreadNotificationCount(this._repository);

  Future<Result<int>> call() {
    return _repository.getUnreadCount();
  }
}
