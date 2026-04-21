# Windows Build Compatibility Notes

## Disabled Features for Windows Build

To ensure the app builds successfully on Windows, the following features have been temporarily disabled:

### 1. Local Notifications
- **Package**: `flutter_local_notifications`
- **Reason**: Requires ATL/MFC components from Visual Studio
- **Impact**: System popup notifications won't appear on Windows
- **Workaround**: In-app notifications still work via `NotificationsScreen`
- **Location**: Commented out in `pubspec.yaml` line 74

### 2. Voice Recording & Playback
- **Packages**: `record`, `audioplayers`
- **Reason**: Linux-specific dependencies causing Windows build errors
- **Impact**: Voice messages disabled in chat
- **Workaround**: Text and image messages still work
- **Location**: Commented out in `pubspec.yaml` lines 94-95

### 3. Affected Files
- `pubspec.yaml` - Packages commented out
- `lib/services/local_notification_service.dart` - Deleted
- `lib/screens/messages/chat_screen.dart` - Audio code commented out
- `lib/main.dart` - Notification initialization removed

## Re-enabling Features

To re-enable these features:

1. **For Local Notifications**:
   - Install Visual Studio "Desktop development with C++" workload
   - Include ATL/MFC components
   - Uncomment line 74 in `pubspec.yaml`
   - Restore `local_notification_service.dart` from git
   - Update `main.dart` to initialize notifications

2. **For Voice Messages**:
   - Uncomment lines 94-95 in `pubspec.yaml`
   - Uncomment audio code in `chat_screen.dart`
   - Run `flutter pub get`

## Desktop Adaptation Status

✅ **Complete** - All responsive features working:
- Side navigation rail on desktop
- Max-width content constraints
- Grid layouts for search
- 11 screens fully adapted
- Smooth responsive transitions

The app is fully functional on Windows with these features disabled.
