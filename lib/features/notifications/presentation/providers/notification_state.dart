import 'package:oasis/features/notifications/domain/models/notification_entity.dart';

enum NotificationLoadingState { initial, loading, loaded, error }

class NotificationState {
  final List<AppNotification> notifications;
  final NotificationLoadingState loadingState;
  final int unreadCount;
  final String? errorMessage;
  final bool hasMore;
  final int currentOffset;

  const NotificationState({
    this.notifications = const [],
    this.loadingState = NotificationLoadingState.initial,
    this.unreadCount = 0,
    this.errorMessage,
    this.hasMore = true,
    this.currentOffset = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    NotificationLoadingState? loadingState,
    int? unreadCount,
    String? errorMessage,
    bool? hasMore,
    int? currentOffset,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      loadingState: loadingState ?? this.loadingState,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}
