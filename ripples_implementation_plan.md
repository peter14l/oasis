# Detailed Implementation Plan: Ripples, Stories & Messaging Enhancements

## 1. Database Schema (Supabase SQL)

### Ripples Table & Interactions
- **Create/Update `ripples` Table**:
  ```sql
  CREATE TABLE ripples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    is_private BOOLEAN DEFAULT false -- Defaults to user's profile privacy
  );
  ```

- **Interaction Tables**:
  - `ripple_likes`: (id, ripple_id, user_id, created_at)
  - `ripple_comments`: (id, ripple_id, user_id, content, created_at)
  - `ripple_saves`: (id, ripple_id, user_id, created_at)

- **Message Table Updates**:
  ```sql
  ALTER TABLE messages 
  ADD COLUMN ripple_id UUID REFERENCES ripples(id) ON DELETE SET NULL,
  ADD COLUMN story_id UUID REFERENCES stories(id) ON DELETE SET NULL;
  ```

- **Profile Adaptive Lockout Updates**:
  ```sql
  ALTER TABLE profiles 
  ADD COLUMN ripples_lockout_multiplier FLOAT DEFAULT 1.0,
  ADD COLUMN ripples_last_session_end TIMESTAMPTZ,
  ADD COLUMN ripples_remaining_duration_ms BIGINT DEFAULT 0;
  ```

## 2. Ripples Screen UI & Interactions

### Interaction Bar
- Add a vertical/horizontal interaction bar on the Ripples screen.
- **Icons (Fluent UI)**:
  - Like: `FluentIcons.heart_24_regular` / `filled`
  - Comment: `FluentIcons.comment_24_regular`
  - Save: `FluentIcons.bookmark_24_regular`
  - Share: `FluentIcons.share_24_regular`
- **Flows**:
  - **Liking**: Optimistic UI update, trigger DB increment.
  - **Commenting**: Slide-up bottom sheet with a list of comments and an input field.
  - **Saving**: Toggle save status in `ripple_saves`.
  - **Sharing**: Opens a "Share to Chat" sheet (list of recent conversations).

### Header Refinement
- Glass-circle "X" (`dismiss_24_filled`) and "Layout Switcher" (`grid_24_regular`).
- Layouts kept: `kineticCardStack` and `choiceMosaic`.

## 3. Messaging Integration (Chat Screen)

### Ripple Sharing
- **Thumbnail UI**: New `RippleBubble` widget in `chat_screen.dart`.
  - Displays a thumbnail, caption snippet, and play icon overlay.
  - Click action: Navigates to a fullscreen viewer for that specific Ripple.
- **Reply with Context**:
  - If a user replies to a Ripple message, the `reply_to_data` will now include the Ripple's metadata (thumbnail, ID) to show the same context-attached UI as other media.

### Story Replies (Fix)
- **StoryViewScreen**: Update `_sendReply` to:
  1. Set `message_type` to `story_reply` (or a dedicated type).
  2. Pass `story_id` to `sendMessage`.
  3. UI: Show a "Story Reply" context in the chat bubble (like Instagram).

## 4. Adaptive Lockout & Session Persistence

- **Adaptive Algorithm**:
  - Increase `ripples_lockout_multiplier` by 0.5 for consecutive "Enter Ripples" actions within 30 minutes of lockout expiry.
  - Decay multiplier over 24 hours.
- **Session Continuity**:
  - If user exits early (e.g., 13 mins into a 15-min session), save `remaining_duration_ms`.
  - If re-entered within 30 mins, resume from 2 mins left.
  - Reset if app is closed/idle for > 30 mins.

## 5. Oasis Pro & Global Pricing

- Detect region via locale/IP.
- Display pricing in USD, INR, EUR, or GBP.
- Button redirects to `https://morrow.app/pricing?user_id=...` for web-based checkout.

## 6. Testing & Validation

- **Unit Tests**:
  - `RipplesService`: Test adaptive lockout math, persistence logic, and filtering based on account privacy.
  - `MessagingService`: Test sending ripple/story-reply message types.
  - `Validation`: Ensure no memory leaks in `VideoPlayer` controllers within Ripples screen.
- **Performance**: Use `CachedNetworkImage` for thumbnails and optimized video caching.

---

Please review this expanded plan. Once approved, I will begin the implementation starting with the SQL migrations.
