/// Static hooks bridging native/OS call events (CallKit accept/decline/end,
/// macOS notification actions) into the [CallController]-owned flow.
///
/// Deliberately holds *callbacks*, not a controller reference, so
/// notification code can reach the call flow without importing the
/// controller (which imports NotificationManager).
class CallNativeBridge {
  CallNativeBridge._();

  /// Set by CallKit before the controller exists (cold start): consumed by
  /// the controller when it is created.
  static String? pendingAcceptCallId;
  static String? pendingDeclineCallId;

  static void Function(String callId)? _onAccept;
  static void Function(String callId)? _onDecline;
  static void Function()? _onEnd;

  /// Called by CallController on construction / dispose.
  static void register({
    required void Function(String callId) onAccept,
    required void Function(String callId) onDecline,
    required void Function() onEnd,
  }) {
    _onAccept = onAccept;
    _onDecline = onDecline;
    _onEnd = onEnd;
  }

  static void unregister() {
    _onAccept = null;
    _onDecline = null;
    _onEnd = null;
  }

  /// Native side says the user accepted (CallKit / notification action).
  static void accept(String callId) {
    final cb = _onAccept;
    if (cb != null) {
      cb(callId);
    } else {
      pendingAcceptCallId = callId;
    }
  }

  /// Native side says the user declined.
  static void decline(String callId) {
    final cb = _onDecline;
    if (cb != null) {
      cb(callId);
    } else {
      pendingDeclineCallId = callId;
    }
  }

  /// Native side ended the call (Android notification / CallKit).
  static void end() {
    _onEnd?.call();
  }
}
