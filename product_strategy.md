# Oasis Product Strategy & Growth Hooks

Based on the architectural scan of the current Flutter codebase, Oasis has incredibly strong foundations for emotional connectivity and **Digital Wellbeing**.

Here is an enhanced planning guide to drive user acquisition, skyrocket retention (hooks), and organically push users toward the $4.99/mo Oasis Pro plan while explicitly breaking away from the toxic UI patterns of legacy social media.

## 1. Organic Growth Loops (User Acquisition)
To grow fast without paid ads, the app itself must do the marketing.

*   **The "Time Capsule" Invite Loop:** 
    *   *Mechanism:* When a user drops a Time Capsule in a Canvas, allow them to share it directly to iMessage/WhatsApp via a Deep Link.
    *   *Hook:* "Sarah buried a memory in a Time Capsule. It unlocks on May 12th. Download Oasis to open it together."
*   **Accountability Pings (Circles):**
    *   *Mechanism:* Allow users to invite an "Accountability Partner" via SMS who isn't on the app yet to verify their commitments.
    *   *Hook:* "Alex committed to 'No social media after 10pm'. He invited you to be his judge. Download Oasis to verify his streak."

## 2. Retention Mechanics (Hooking the Free User)
Free users should have unlimited access to scrolling and creating short-form video (Clips) but in a way that respects their time.

*   **Real-Time "Pulse" Notifications:**
    *   *Mechanism:* [TimelineCanvasScreen](file:///f:/morrow_v2/lib/screens/canvas/timeline_canvas_screen.dart#33-40) has a real-time [_sendPulse](file:///f:/morrow_v2/lib/screens/canvas/timeline_canvas_screen.dart#134-143) feature. If a user enters a shared Canvas, send a silent push notification to the other members: "Emma is looking at your Summer 2024 Canvas right now."
*   **Commitment Graveyard (Loss Aversion):**
    *   In Circles, if a user breaks a commitment streak, show a dramatic visual "shattering" animation in Flutter.

## 3. High-Value Triggers for Oasis Pro ($4.99/mo)
We want free users to hit a natural ceiling on the "Memory Storage" side of the app where upgrading feels like a no-brainer.

*   **The "Infinite Memory" Paywall:**
    *   Limit free users to 2 Canvases. Trigger the paywall on the 3rd.
*   **Custom Feed Layouts:**
    *   Lock immersive spatial feed layouts (PulseMap) behind Pro.

## 4. The "Anti-Doomscroll" UI Philosophy (Core Differentiator)
Unlike Instagram, TikTok, or Messenger, Oasis is designed with **Intentional Friction** to break the toxic muscle memory of endless scrolling. The UI is meant to be artistic, slow, and cinematic.

*   **The 3D Kinetic Card Stack:**
    *   The 3D-axis rotation on short-form video (Clips) creates a physical, tactile feeling of moving through space, rather than a mindless slot-machine swipe. This must be preserved as the signature feel of the app.
*   **Hidden Action Buttons:**
    *   By hiding the Like, Comment, and Share buttons inside the expandable caption pill, Oasis forces the user to *actively choose* to interact. This prevents mindless "double-tap liking" and ensures that every interaction is genuine and intentional.
*   **Video Preloading:** 
    *   Implement video pre-caching *underneath* the 3D scroll to ensure the artistic transitions remain seamless without buffering.

## 5. Subtle Social Enhancements
*   **Fluid Profile Navigation:** Implement `Hero` animations from the Profile Grid to the Post Details screen so images expand seamlessly, fitting the cinematic aesthetic.
*   **Voice Note Replies:** Add a microphone icon to drop voice notes in the comments (utilizing the audio logic from the Canvas) to keep conversations deeply human and connected.

## 6. Elevating "Circles" (Accountability UX)
The current Circles implementation is functional but basic. To make accountability feel premium and weighty:
*   **Tactile Check-Ins (Fluid Fill):** Replace the standard "Mark Complete ✅" button on the [CommitmentCard](file:///f:/morrow_v2/lib/widgets/circles/commitment_card.dart#5-183) with a long-press gesture. As the user holds it, the card fills up with a fluid/water graphic until it "pops" and marks as complete. This physical exertion adds to the intentionality.
*   **Dynamic Health Header:** Replace the static [SliverAppBar](file:///f:/morrow_v2/lib/screens/profile_screen.dart#644-672) gradient in [circle_detail_screen.dart](file:///f:/morrow_v2/lib/screens/circles/circle_detail_screen.dart) with a slow-moving, animated fluid mesh background. If the circle's streak is high, it glows vibrantly; if the streak is broken (0), it turns dark and muted.
*   **Voice Accountability:** Allow users to drop 10-second self-destructing voice notes directly onto a friend's commitment card (e.g., words of encouragement or a gentle nudge).

## 7. Elevating "Canvas" (Digital Journal & Memory Scrapbook)
The Canvas is Oasis's masterpiece. To fulfill the vision of a deeply personal, hyper-premium "Digital Journal," we need to break away from the rigid vertical timeline and embrace the organic, messy beauty of a physical scrapbook:
*   **Scattered Polaroid Layouts:** When a user uploads multiple photos from the same day, instead of just a neat vertical list, the UI should arrange them into a beautiful, slightly chaotic "thrown on a desk" mosaic with varied rotation angles and overlapping edges.
*   **Textural "Scrapbook" Elements:** Introduce subtle visual motifs across Canvas items: pieces of digital tape holding photos, torn paper edges on text notes, or paper clips attaching Voice Memos to images.
*   **Long-form Journal Entries:** Create a specific `CanvasItemType.journal`. Instead of a glowing neon note, this renders as a beautiful, textured piece of paper utilizing elegant serif typography (e.g., standardizing on a font like *Cormorant Garamond* or *Playfair Display*) for pouring out long-form thoughts.
*   **Interactive "Spread" Stacks:** Upgrade the `InfiniteCardStack`. When tapped, the stack of cards smoothly animates and "spreads out" across the screen like dealing a deck of cards, allowing the user to see everything at once before collapsing it back down.
*   **Cinematic Map Transition:** Toggling between the Journal Timeline and the Spatial Map mode shouldn't be an instant cut. We need a fluid, zooming transition that pulls the linear timeline backward until it reveals the massive 2D map.
*   **Gyroscope Parallax Depth:** Map Mode uses flat x/y positioning. By integrating the device gyroscope, we can add a subtle parallax effect so elements shift slightly as the user tilts their phone, giving the physical Journal true 3D depth.
*   **Ambient Audio Clustering:** If a user scrolls into a month on the Timeline that contains several video/audio clips, subtly fade in a muted, overlapping audio loop of those memories to create an ambient soundscape.
