# Phase 4: Scalability Improvements - Research

**Gathered:** 2026-04-12
**Status:** Research complete

---

## 1. Cursor-based Pagination (Feeds, Messages, Lists)

### Key Insights from Research

**Why Cursor > Offset for Large Datasets:**
- OFFSET pagination becomes unusable beyond page 100 on tables with 1M+ rows
- Cursor-based maintains ~50ms response time for any page vs 5+ seconds for OFFSET
- Uses index efficiently, no row skipping required

**Supabase Implementation:**
- Use composite cursors: `(created_at, id)` for deterministic ordering
- Always add unique column (id) to ensure deterministic ordering when ordering by non-unique column (created_at)
- Supabase's `.range()` method can be used, but cursor with `.gt()` is more performant

**Flutter Integration:**
- Package: `cursor_pagination` (pub.dev) - supports ChangeNotifier, BLoC/Cubit
- Key pattern: Store cursor from last item, use in next request
- Response format: `{ data: [...], nextCursor: "timestamp_id" }`

**Cursor Format:**
```
cursor = "${lastItem.createdAt.toIso8601String()}_${lastItem.id}"
```

**Best Practices:**
- Always create index on cursor columns: `CREATE INDEX idx_posts_created_at_id ON posts (created_at DESC, id DESC)`
- Handle edge cases: deleted rows, empty cursors, no more pages
- Don't support random access - users must navigate sequentially

---

## 2. Hive Offline Caching

### Key Insights from Research

**Why Hive (vs SQLite):**
- Lightweight, blazing-fast NoSQL written in pure Dart
- No SQL knowledge required
- Built-in AES encryption
- Ideal for: offline caches, API responses, user data, timelines

**Schema Versioning Strategy:**
- Use `@HiveField(n)` indices - never reuse or reorder
- Use `defaultValue` for new fields to maintain backward compatibility
- Store schema version in box: `await box.put('schema_version', 2)`
- Write one-time migration functions

**Migration Pattern:**
```dart
Future<void> migrateToV2() async {
  final box = Hive.box<Todo>('todos');
  final version = (await box.get('schema_version')) as int? ?? 1;
  if (version < 2) {
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Todo && v.createdAt == null) {
        v.createdAt = DateTime.now();
        await v.save();
      }
    }
    await box.put('schema_version', 2);
  }
}
```

**Sync Patterns:**
- Push-based: Queue local changes, push on connectivity
- Pull-based: Fetch deltas by timestamp/version
- Conflict resolution: Last-write-wins (compare timestamps)

**Box Organization (Per Context Decision D-02):**
- `messages_box` - Chat messages
- `feeds_box` - Feed items
- `profiles_box` - User profiles
- Separate boxes for logical organization and performance

**Performance Tips:**
- Use `putAll` for batch writes
- Use `LazyBox` for large datasets
- Debounce fast-changing data
- Compact occasionally after mass deletions

---

## 3. Route-based Code Splitting (Lazy Loading)

### Key Insights from Research

**Options in Flutter:**

1. **go_router_deferred** (Recommended for go_router users)
   - Package: `go_router_deferred: ^1.0.4`
   - Simple setup: Add `DeferredRoute.setup()` wrapper
   - Supports shell routes and stateful shell routes
   - Full type safety

2. **auto_route** with `deferredLoading: true`
   - Add `@RoutePage(deferredLoading: true)` annotation
   - Run build_runner - generates `loadLibrary()` calls

**Implementation Pattern:**
```dart
import 'screens/settings_screen.dart' deferred as settings_screen;

final router = GoRouter(
  routes: [
    DeferredRoute.setup(
      path: '/settings',
      loadLibrary: settings_screen.loadLibrary,
      builder: (context, state) => settings_screen.SettingsScreen(),
    ),
  ],
);
```

**Performance Impact (Realistic):**
- Startup time: 1.8s → 0.9s (50% reduction)
- Initial Dart code load: 100% → 45%
- Memory footprint: 200MB → 120MB

**Best Practices:**
- Use deferred imports for: Chat, Analytics, AI, Maps, PDF viewer
- Group related routes into feature modules
- Keep deferred imports minimal
- Handle import failures gracefully with error boundaries

---

## 4. Supabase CDN Image Optimization

### Key Insights from Research

**Built-in Features:**
- Supabase Storage includes automatic CDN
- Transformation API for resizing, format conversion
- Automatic WebP/AVIF conversion

**Usage with Supabase:**
```dart
// Get optimized URL
final url = supabase.storage
  .from('avatars')
  .getPublicUrl('avatar.jpg', transform: {
    'width': 200,
    'height': 200,
    'format': 'webp',
    'quality': 80,
  });
```

**Best Practices:**
- Use specific dimensions for use cases (thumbnails: 100x100, cards: 400x300)
- Convert to WebP for 30-50% size reduction
- Use quality 80 for balance of quality/size
- Cache transformed images (CDN handles this)

---

## 5. Exponential Backoff Retry Logic

### Key Insights from Research

**Why Exponential Backoff:**
- Progressive delay prevents overwhelming servers during outages
- Standard industry pattern for resilient apps
- Reduces "thundering herd" problem

**Recommended Configuration:**
- Initial delay: 1 second
- Max delay: 32 seconds
- Max attempts: 3-5
- Multiplier: 2x (exponential)
- Add jitter: ±25% randomization

**Implementation Pattern:**
```dart
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 32),
}) async {
  final random = Random();
  
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      
      // Calculate delay with jitter
      final baseDelay = initialDelay * pow(2, attempt - 1);
      final jitter = baseDelay.inMilliseconds * 0.25 * (random.nextDouble() * 2 - 1);
      final delay = Duration(
        milliseconds: (baseDelay.inMilliseconds + jitter).clamp(
          initialDelay.inMilliseconds,
          maxDelay.inMilliseconds,
        ),
      );
      
      await Future.delayed(delay);
    }
  }
  throw Exception('Max retry attempts reached');
}
```

**Best Practices:**
- Add jitter to prevent synchronized retries
- Consider circuit breaker for repeated failures
- Log retry attempts for debugging
- Distinguish retryable (network) vs non-retryable (auth) errors

---

## Integration Points

### Existing Codebase Patterns (from Context)
- Supabase client: `lib/core/network/supabase_client.dart`
- Provider pattern for state management
- Data sources follow remote/local pattern

### Implementation Order (Recommended)
1. Retry logic (infrastructure - used by everything else)
2. Pagination infrastructure (feeds, messages, profiles)
3. Hive setup and caching (depends on pagination)
4. Lazy loading (depends on routing)
5. CDN integration (independent, can be done anytime)

---

## Validation Architecture

The plans should include verification for:
1. Pagination: Load 100+ items, verify no duplicates/gaps
2. Offline: Go offline, verify cache works, sync on reconnect
3. Lazy loading: Check bundle size reduction
4. Retry: Test with network failures, verify exponential backoff

---

*Research complete. Ready for planning.*