import 'package:flutter/foundation.dart';
import 'package:oasis_v2/services/presence_service.dart';

class UserPresence {
  final String status;
  final DateTime? lastSeen;
  UserPresence({required this.status, this.lastSeen});
}

class PresenceProvider with ChangeNotifier {
  final PresenceService _presenceService = PresenceService();
  final Map<String, UserPresence> _userPresence = {};

  UserPresence? getUserPresence(String userId) => _userPresence[userId];

  bool isUserOnline(String userId) => _userPresence[userId]?.status == 'online';

  void subscribeToUserPresence(String userId) {
    _presenceService.subscribeToUserPresence(
      userId: userId,
      onUpdate: (status, lastSeen) {
        _userPresence[userId] = UserPresence(status: status, lastSeen: lastSeen);
        notifyListeners();
      },
    );
  }

  void updateUserPresence(String userId, String status) {
    _presenceService.updateUserPresence(userId, status);
  }

  void unsubscribeFromUserPresence(String userId) {
    _presenceService.unsubscribeFromPresence(userId);
    _userPresence.remove(userId);
    notifyListeners();
  }
}
