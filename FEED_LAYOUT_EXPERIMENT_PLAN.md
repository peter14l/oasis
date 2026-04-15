# Oasis Feed Layout Experiments: Implementation Plan

## Goal
Implement three distinct, creative feed layouts (Spatial Glider, Focused Flow, and Living Canvas) along with a layout switcher. This allows for A/B testing and user feedback collection to determine the most peaceful, engaging, and "Oasis-like" experience that stands out from traditional infinite scroll feeds.

## Phase 1: Architectural Foundation & Switcher
**Objective:** Prepare the state management and UI to support multiple feed rendering strategies.

1. **State Management (Provider):**
   - Create an enum `FeedLayoutType { classic, spatial, focused, canvas }`.
   - Update `UserSettingsProvider` (or create a new `FeedPreferencesProvider`) to store and persist the active `FeedLayoutType`.
2. **Layout Switcher UI:**
   - Add a subtle toggle in `FeedScreen` (e.g., an icon near the "Explore" / "Following" tabs or in the top app bar) that opens a bottom sheet or a segmented control.
   - This switcher will let users seamlessly cycle between the experimental layouts and the current (classic) layout.
3. **Feed Screen Refactor:**
   - Extract the current list/grid view implementation in `FeedScreen` into a separate widget (e.g., `ClassicFeedLayout`).
   - Refactor the main feed area to dynamically swap the child widget based on the active `FeedLayoutType`.

## Phase 2: Implementation of the "Focused Flow" Layout
**Concept:** A "One-at-a-time" magazine-style feed prioritizing intentionality over noise.

1. **Core Scrolling Mechanism:**
   - Replace standard scrolling with a `PageView` (vertical) or `ListView` utilizing custom `ScrollPhysics` (like `PagingScrollPhysics`) so the screen snaps to one post at a time.
2. **Visual Presentation:**
   - The active post takes up ~80% of the viewport.
   - Previous and next posts are partially visible but scaled down (e.g., 0.85 scale) and have reduced opacity (40%).
3. **Ambient Backdrop:**
   - Use the active post's primary image (or a generated gradient based on its colors) heavily blurred as the screen's background.
4. **Integration:** Implement as `FocusedFlowFeedLayout` and hook it up to the layout switcher.

## Phase 3: Implementation of the "Spatial Glider" Layout
**Concept:** A 2.5D space where posts feel like floating islands, creating a sense of exploration.

1. **Core Scrolling Mechanism:**
   - Use a `CustomScrollView` with a staggered grid or a specialized mapping that staggers cards horizontally as the user scrolls vertically.
2. **Depth and Scale (Parallax):**
   - Assign subtle parallax effects based on scroll position. As posts near the center of the screen, they scale up slightly to 1.0; as they move to the edges, they scale down to simulate depth.
   - Remove hard borders from `PostCard`, utilizing soft drop shadows to create the floating effect.
3. **Ambient Environment:**
   - Implement a slow-moving, subtle background animation (e.g., a slow-panning nebula or gentle water ripples) behind the scrolling elements.
4. **Integration:** Implement as `SpatialGliderFeedLayout` and add to the layout switcher.

## Phase 4: Implementation of the "Living Canvas" Layout
**Concept:** A borderless, organic experience with connecting visual fibers, treating the feed like a single cohesive piece of art.

1. **Core Scrolling Mechanism:**
   - A highly frictionless, fluid `ListView` or `CustomScrollView`.
2. **Visual Presentation:**
   - Render content (text, images, author info) directly onto the background without "card" containers.
   - Ensure high contrast for text readability against the dynamic background.
3. **Visual Connectivity (Fibers):**
   - Use `CustomPaint` with a `CustomPainter` to draw soft, glowing bezier curves between consecutive posts, visually linking them.
4. **Integration:** Implement as `LivingCanvasFeedLayout` and add to the layout switcher.

## Phase 5: Feedback Collection & Telemetry
**Objective:** Measure user sentiment and engagement to make a data-driven decision.

1. **In-App Feedback Prompt:**
   - After a user spends a specific duration (e.g., 5 minutes) in one of the new layouts, surface a subtle, non-intrusive prompt (e.g., a toast or a small inline widget).
   - Question: *"How does this layout feel?"*
   - Options: Calm, Engaging, Distracting, Confusing.
2. **Analytics Integration:**
   - Track active time per layout.
   - Track engagement metrics (likes, comments, ripples sessions initiated) segmented by layout type.

## Execution Order
1. Execute **Phase 1** to establish the foundation and the `classic` fallback.
2. Execute **Phase 2** (Focused Flow) as the first prototype, as it requires the least custom painting and relies on established Flutter scrolling physics.
3. Execute **Phase 3** and **Phase 4** iteratively, refining their visual effects.
4. Deploy **Phase 5** alongside the first beta release of these layouts.