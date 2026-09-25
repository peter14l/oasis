import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:win_toast/win_toast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:oasis/services/notification_manager.dart';

/// OS-level incoming-call notifications on Windows, macOS and Linux.
/// Android/iOS use flutter_callkit_incoming (FCM background handler).
///
/// Deliberately does *not* navigate — [CallController] state drives the
/// single CallRouter, which pushes the call screen.
class DesktopCallNotifier {
  DesktopCallNotifier._();

  static final DesktopCallNotifier instance = DesktopCallNotifier._();

  bool get _isWindows => !kIsWeb && Platform.isWindows;
  bool get _isMacOS => !kIsWeb && Platform.isMacOS;
  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _supported => _isWindows || _isMacOS || _isLinux;

  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    String? senderId,
  }) async {
    if (!_supported) return;
    if (_isWindows) {
      await _showWindowsToast(callerName);
    } else if (_isMacOS) {
      await NotificationManager.instance.showCallNotification(
        callId: callId,
        callerName: callerName,
        senderId: senderId,
      );
    } else if (_isLinux) {
      await _showLinuxNotification(callerName);
    }
  }

  Future<void> dismissIncomingCall() async {
    if (!_supported) return;
    if (_isMacOS) {
      await NotificationManager.instance.dismissCallNotification();
    }
    // Windows / Linux toasts have no programmatic dismiss.
  }

  Future<void> _showWindowsToast(String callerName) async {
    try {
      await WinToast.instance().showToast(
        type: ToastType.text02,
        title: 'Incoming Call',
        subtitle: '$callerName is calling...',
      );
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[DesktopCallNotifier] Windows toast failed: $e');
    }
  }

  Future<void> _showLinuxNotification(String callerName) async {
    try {
      await Process.run('notify-send', [
        '--app-name=Oasis',
        '--urgency=critical',
        '--expire-time=30000',
        '--icon=phone',
        'Incoming Call',
        '$callerName is calling...',
      ]);
    } catch (e) {
      debugPrint('[DesktopCallNotifier] Linux notify-send failed: $e');
    }
  }
}
