# Canvas "Linear Timeline" Implementation Plan

## 1. Vision & Architecture

The Canvas feature is transitioning from a 2D spatial whiteboard (freeform drag-and-drop) into a **Linear Memory Timeline**. It will act as a shared, living journal for communities and relationships. 

### Core Concepts:
- **Vertical Timeline**: The primary navigation is a vertical scroll, sorted chronologically (newest at the top or oldest at the top, depending on user preference, defaulting to newest).
- **Fast-Scrubber**: A custom vertical slider on the right edge of the screen allowing users to scrub rapidly through years and months.
- **Infinite Card Stacks**: Media (photos, videos) uploaded at the same time/event will be grouped into a "stack." Swiping the top card sends it to the bottom of the stack, bringing the next one forward.
- **Neon "Core Memories"**: Text notes are displayed in dark boxes with vibrant, animated neon/glowing borders.
- **Interactive Elements**: Voice memos with custom waveforms, holographic shimmers on stickers, and real-time "Pulse" reactions.

## 2. Database & Data Model Changes

The current database structure (`canvas_items`) is well-suited for this, but requires some metadata adjustments.

### `CanvasItem` Model Adjustments:
Instead of relying primarily on `x_pos` and `y_pos` for layout, the primary layout driver will be the item's chronological timestamp and group affiliation.
- **Add `groupId` (Optional)**: To group multiple images/cards uploaded together into a single "Stack."
- **Repurpose Coordinates (Optional)**: `x_pos` and `y_pos` can be used for slight randomized offsets within the card stack to give it an organic, messy Polaroid feel.
- **Update Item Types**: 
  - `CanvasItemType.text` -> Becomes the "Glowing Note" widget.
  - `CanvasItemType.photo` -> Becomes part of a "Card Stack".
  - `CanvasItemType.voice` -> Becomes a playable audio widget.
  - `CanvasItemType.sticker` -> Becomes a holographic overlay attached to a specific card or timestamp.

## 3. UI/UX Component Implementation

### A. `TimelineCanvasScreen` (Replaces `CanvasDetailScreen`)
- **Layout**: `CustomScrollView` with slivers.
- **Background**: Deep, dark ambient color (e.g., `#0C0F14`) or the canvas's custom cover color applied as a highly blurred background mesh gradient.
- **Right Scrubber**: A `GestureDetector` mapping vertical drag to a `ScrollController.animateTo` / `jumpTo` function, showing a pop-out tooltip of the current Year/Month.

### B. `InfiniteCardStack` Widget
- **Functionality**: A custom stateful widget taking a list of `CanvasItem` photos.
- **Animation**: 
  - Uses `Stack` with `AnimatedPositioned` and `AnimatedScale`.
  - Top card handles horizontal pan gestures.
  - On swipe threshold met: Top card animates out, z-index changes to lowest, and it animates back in at the bottom. The remaining cards scale up.

### C. `GlowingNote` Widget
- **Functionality**: Replaces the standard text note.
- **Styling**: 
  - Inner container: Dark, semi-transparent.
  - Outer border: Uses `BoxDecoration` with `boxShadow` (blurRadius: 15-20) and vibrant colors (Electric Blue, Cyber Lime, Neon Pink) based on the `color` property of the `CanvasItem`.

### D. `VoiceMemo` Widget
- **Functionality**: Plays audio. 
- **Styling**: A pill-shaped UI with a play button and a visual audio waveform (can be generative or static for V1) that lights up when playing.

### E. `PulseReaction` (Future/Stretch)
- **Functionality**: Long-pressing a card triggers a Supabase Realtime broadcast event.
- **Styling**: A glowing ripple effect expanding from the touch point, visible to all active users on the canvas.

## 4. Step-by-Step Execution Plan

**Phase 1: Foundation & Data Migration**
- [ ] Update `CanvasItem` model in Flutter to support `groupId` and new metadata properties.
- [ ] Create basic `CustomScrollView` structure in `TimelineCanvasScreen`.

**Phase 2: Core Components**
- [ ] Build the `InfiniteCardStack` widget with the swipe-to-back animation.
- [ ] Build the `GlowingNote` widget with customizable neon borders.
- [ ] Implement the `TimelineFastScrubber` on the right side of the screen.

**Phase 3: Integration & Layout**
- [ ] Update `CanvasProvider` to sort items chronologically and group items with the same `groupId` or items created within the same hour into stacks.
- [ ] Map the grouped items into the `CustomScrollView` as timeline events.
- [ ] Add month/year headers between groups.

**Phase 4: Polish & Interactivity**
- [ ] Add haptic feedback to the fast-scrubber and card swiping.
- [ ] Implement the "Pulse" long-press reaction using Supabase Realtime presence/broadcasts.
- [ ] Build the Voice Memo UI.

## 5. Required Dependencies
- `audioplayers` (for voice memos, if not already installed).
- `sensors_plus` (if we implement the accelerometer-based holographic sticker stretch goal).
- `lottie` or custom `CustomPainter` (for the audio waveforms).