# Oasis Product Strategy & Growth Hooks

Based on the architectural scan of the current Flutter codebase, Oasis has incredibly strong foundations for emotional connectivity. 

Here is an enhanced planning guide to drive user acquisition, skyrocket retention (hooks), and organically push users toward the $4.99/mo Oasis Pro plan without restricting core social features like short-form video.

## 1. Organic Growth Loops (User Acquisition)
To grow fast without paid ads, the app itself must do the marketing.

*   **The "Time Capsule" Invite Loop:** 
    *   *Mechanism:* When a user drops a Time Capsule in a Canvas, allow them to share it directly to iMessage/WhatsApp via a Deep Link.
    *   *Hook:* "Sarah buried a memory in a Time Capsule. It unlocks on May 12th. Download Oasis to open it together."
    *   *Why it Works:* Deep psychological suspense and high emotional stakes.
*   **Accountability Pings (Circles):**
    *   *Mechanism:* Allow users to invite an "Accountability Partner" via SMS who isn't on the app yet to verify their commitments.
    *   *Hook:* "Alex committed to 'No social media after 10pm'. He invited you to be his judge. Download Oasis to verify his streak."
*   **Web Teasers for Short-Form Video:**
    *   *Mechanism:* When sharing a video outside the app, the web landing page should play the first 3 seconds, then blur with a glassmorphic overlay: "Unlock the rest of this moment on the Oasis App."

## 2. Retention Mechanics (Hooking the Free User)
Free users should have unlimited access to scrolling and creating short-form video (Reels equivalent) as this is highly addictive.

*   **Real-Time "Pulse" Notifications:**
    *   *Mechanism:* [TimelineCanvasScreen](file:///f:/morrow_v2/lib/screens/canvas/timeline_canvas_screen.dart#32-39) has a gorgeous real-time [_sendPulse](file:///f:/morrow_v2/lib/screens/canvas/timeline_canvas_screen.dart#121-130) feature. If a user enters a shared Canvas, instantly send a silent push notification to the other members: "Emma is looking at your Summer 2024 Canvas right now."
    *   *Why it Works:* Knowing someone is actively looking at your shared memories is highly validating and drives immediate app opens.
*   **Commitment Graveyard (Loss Aversion):**
    *   In Circles, if a user breaks a commitment streak, show a dramatic visual "shattering" animation in Flutter. Users will log in simply to keep the glass from breaking.
*   **Digital Wellbeing as a Feature:**
    *   While video is unmetered, you can still let users set their *own* lockouts to promote a positive, guilt-free environment compared to TikTok. "You've scrolled for 20 mins, time to check on your Circles!"

## 3. High-Value Triggers for Oasis Pro ($4.99/mo)
We want free users to love the app, but eventually hit a natural ceiling on the "Memory Storage" side of the app where upgrading feels like a no-brainer.

*   **The "Infinite Memory" Paywall:**
    *   Allow free users to create a maximum of 2 Canvases (e.g., one for family, one for close friends). When they try to create a 3rd (e.g., for a new trip), trigger the paywall: *"Your memory vaults are full. Upgrade to Oasis Pro for infinite Canvases."*
*   **Extended Time Capsules:**
    *   Free users can lock a Time Capsule for a maximum of 14 days. Oasis Pro users can lock Time Capsules for 1 year, 5 years, or 10 years.
*   **Custom Feed Layouts:**
    *   The [FeedScreen](file:///f:/morrow_v2/lib/screens/feed_screen.dart#22-28) currently features a `ZenCarousel` and `PulseMap` layout. Make the standard feed free, but lock the immersive/spatial layouts behind Pro to incentivize power users to upgrade for the aesthetic.
