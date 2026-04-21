# OASIS: The Intentional Evolution Plan

## 🎯 Mission
Transitioning Oasis from a metric-driven social network into an intentional relationship-focused platform. Oasis is designed to be "on your side," prioritizing mental health, deep connection, and data sovereignty over dopamine loops and infinite scrolling.

---

## 🏛️ Seven Pillars of the Evolution

### 1. The Great Purge (Removal of Anti-Patterns)
*   **Target:** Surgical removal of the infinite Feed, Ripples (short-form video), and Global Search.
*   **Metrics:** Strip away all likes, view counts, and follower numbers from the database and UI.
*   **Infrastructure:** Decommission Ad Service and Creator Analytics.
*   **Goal:** Eliminate the performance anxiety and addictive loops that distract from real connection.

### 2. Data Sovereignty & Trust
*   **Local-First Media:** Flip the default to on-device storage for shared media. Cloud backup becomes a conscious opt-in.
*   **Privacy Receipt:** A prominent dashboard showing exactly what data exists and where, with one-tap deletion.
*   **Transparency:** A new "Revenue Transparency" screen and a direct link to the Open Source core cryptography on GitHub.

### 3. Ambient Wellness (The "Exhaling" UI)
*   **Ambient Wind-Down:** Dynamically cool the theme colors and slow down animation speeds as session duration increases or night approaches.
*   **Micro-Intention:** A 1-second "Landing Moment" on app open to break the reflex loop, and a "Session Summary" on close ("You spent 12 minutes with the people who matter").
*   **Neutral Notifications:** Remove red urgency badges. Use soft, non-threatening tones for alerts.

### 4. Intimacy Mechanics (Non-Verbal Presence)
*   **Check-Ins:** A lightweight, single-tap "Thinking of you" signal that requires no typing or obligation to reply.
*   **Shared Memory Lane:** Private surface of past shared moments on anniversaries, restricted to the involved circle members.
*   **Relationship Pulse:** Detect "quiet" friendships and surface a gentle prompt to reach out without creating guilt.

### 5. Mindful Expression
*   **Mood-Aware Pause:** A subtle prompt during late-night hours or rapid-fire posting: "Send this tomorrow morning, or now?"
*   **Draft Vault:** Repurposing the `Vault` as a private safe space for raw thoughts not intended for sharing.
*   **Ephemeral Aesthetic:** A tactile, "unpolished" UI for 24-48hr posts to lower the bar for authenticity.

### 6. Relational Circles
*   **Identity First:** Pivot Circles from "privacy settings" to "relationship maps." Encourage custom naming like "Sunday People" or "The Inner Circle."
*   **No Virality:** Explicitly lock content to its original circle. No reshare/forwarding mechanisms to strangers.

### 7. The Subscription Covenant
*   **Value Alignment:** Replace ad-based incentives with a subscription-first model. "You pay us so we never have to sell you."
*   **Revenue Reporting:** Annual plain-English report on how subscriber funds were used to build the platform.

---

## 🛠️ Detailed Implementation Phases

### Phase 1: Structural Gutting (The Purge)
1.  **Routing (`app_router.dart`):**
    *   Change `initialLocation` to `/messages`.
    *   Remove `/feed`, `/search`, `/ripples`, and `/create-ripple` routes.
2.  **State Management (`app_initializer.dart`):**
    *   Remove `FeedProvider`, `RipplesProvider`, `CurationTrackingService`, and `AdService` from the provider tree.
3.  **UI Navigation (`MainLayout`):**
    *   Remove "Feed" and "Search" tabs from `BottomNavigationBar` and `NavigationRail`.
    *   Delete the "New Post" and "New Ripple" options from the Floating Action Button / Create Menu.
4.  **Metric Removal:**
    *   Surgically remove `LikeCount` and `ViewCount` widgets from all components (PostCard, StoryView).

### Phase 2: Trust & Sovereignty (Data Layer)
1.  **Media Refactor:**
    *   Update `ChatMediaService` and `StorageService` to prioritize local cache paths over Supabase Bucket URLs.
    *   Implement "Upload to Cloud" as a per-item manual action or explicit toggle in Settings.
2.  **Privacy Receipt UI:**
    *   Create a dedicated `PrivacyDashboardScreen` in `features/settings`.
    *   Integrate `PrivacyAuditService` to list active data points (sessions, stored media, encryption keys).
3.  **Transparency Screens:**
    *   Add `RevenueReportScreen` showing simplified allocation of subscription funds.
    *   Add "Open Source Integrity" link in Settings leading to the encryption source code.

### Phase 3: The Exhaling UI (Ambient Wellness)
1.  **Reactive Theme Engine:**
    *   Create `OasisAmbientTheme` as a `ThemeExtension`.
    *   Connect `DigitalWellbeingService.totalSeconds` to a saturation and brightness multiplier in `AppTheme`.
    *   Slow down `motion.Animate` effects globally when "Wind-Down" is active.
2.  **Notification Refactor:**
    *   Update `NotificationManager` and `Badge` widgets to replace `Colors.red` with `OasisColors.mist` or similar neutral tones.
3.  **Intention Overlays:**
    *   Implement `IntentionSplashScreen` that displays for 800ms before showing the app shell.
    *   Implement `SessionSummarySheet` triggered on `LifecycleManager` pause state.

### Phase 4: Intimacy Mechanics (Relationship Layer)
1.  **Check-In System:**
    *   Create `CheckInService` with a single Supabase RPC: `send_ambient_ping(target_user_id)`.
    *   Add a "Thinking of you" button to Circle member profiles and DM headers.
2.  **Anniversary Engine:**
    *   Add `AnniversaryService` that scans local/cloud history for shared media on the current date (yearly).
    *   Surface these in a non-intrusive "Memory Lane" widget at the top of the Messages screen.
3.  **Pulse Detection:**
    *   Logic in `PresenceProvider` to identify Circle members with zero interactions > 21 days.

### Phase 5: Mindful Expression (Posting Flow)
1.  **Mood-Aware Logic:**
    *   Intercept `CreatePost` / `CreateStory` actions with a time-of-day check (12 AM - 5 AM).
    *   Show a soft modal: "It's late. Would you like to schedule this for 8 AM to protect your peace?"
2.  **Draft Vault:**
    *   Create a "Me Only" destination in the sharing flow that saves content to `VaultService` instead of the public Supabase `posts` table.
3.  **Ephemeral UI:**
    *   Apply a "Raw/Tactile" filter (slight grain, handwritten fonts) to all Ephemeral Stories to distinguish them from permanent content.

### Phase 6: Relational Circles (Naming & Sharing)
1.  **Naming Overhaul:**
    *   Update `CreateCircleScreen` to make "Circle Name" the primary focus, with prompts like "What do these people mean to you?"
2.  **Virality Block:**
    *   Remove "Forward" and "Share to..." buttons from all shared content.
    *   Implement a "Circle-Locked" watermark or UI indicator.

### Phase 7: The Covenant (Onboarding & Paywall)
1.  **Value-Based Onboarding:**
    *   Replace feature-slides with philosophy-slides (Privacy, No Metrics, Intentionality).
2.  **Subscription-First UI:**
    *   Frame the paywall as "Joining the Covenant" or "Supporting the Mission" rather than "Buying Pro."

---

## 🔒 Verification Protocol
*   **Build Integrity:** Ensure no broken imports remain after feature deletion.
*   **Philosophical Audit:** Verify no "Red" elements remain in the notification system.
*   **Performance:** Measure reduced background overhead after removing analytics/ads.
