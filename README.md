# Morrow

A modern social media app for sharing moments and connecting with communities.

## Features

- **Posts & Feed** - Share updates, photos, and connect with friends
- **Stories** - Share ephemeral content that expires after 24 hours
- **End-to-End Encrypted Messaging** - Secure private conversations with PIN-protected encryption
- **Communities** - Join and create interest-based communities with moderation tools
- **Collections** - Save and organize posts into custom collections
- **Screen Time** - Track your app usage and build healthy digital habits
- **Moderation** - Block, mute, and report users for a safer experience

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.7.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Supabase Account](https://supabase.com) for backend services

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/morrow_v2.git
   cd morrow_v2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the root directory with your Supabase credentials:
   ```env
   SUPABASE_URL=your-supabase-url
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

4. **Set up Supabase**
   
   See the [Supabase Setup Guide](supabase/README.md) for database migrations and configuration.

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/          # App configuration
├── exceptions/      # Custom exceptions
├── models/          # Data models
├── providers/       # State management (Provider)
├── routes/          # Navigation (GoRouter)
├── screens/         # UI screens
│   ├── auth/        # Login, register
│   ├── community/   # Community features
│   ├── legal/       # Privacy policy, ToS
│   ├── messages/    # Chat, DMs
│   ├── onboarding/  # First-time user experience
│   └── settings/    # App settings
├── services/        # Business logic & API
├── themes/          # App theming
├── utils/           # Utilities
└── widgets/         # Reusable widgets
```

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

## Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## Dependencies

Key packages used:
- **supabase_flutter** - Backend & real-time features
- **provider** - State management
- **go_router** - Navigation
- **sentry_flutter** - Error monitoring
- **flutter_secure_storage** - Secure credential storage
- **encrypt** - Message encryption

See [pubspec.yaml](pubspec.yaml) for the complete list.

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | ✅     |
| iOS      | ✅     |
| Windows  | ✅     |
| macOS    | ✅     |
| Linux    | ✅     |
| Web      | ⚠️ Limited |

## License

This project is proprietary and confidential.

## Support

For support, please contact support@morrow.app
