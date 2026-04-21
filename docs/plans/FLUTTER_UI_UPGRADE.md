# 🌿 Oasis: Flutter UI/UX Upgrade Blueprint

This document outlines how to translate the "Organic Luxury" aesthetic of the Oasis landing page into a high-fidelity, high-performance Flutter mobile experience.

## 🎨 1. Enhanced Color Palette (ThemeData)

The landing page uses a deep, layered green scheme. In Flutter, we should use these as `Color` constants and integrate them into a custom `ThemeData`.

```dart
// Suggested Color Palette
static const Color oasisDeep = Color(0xFF0D1F1A);   // Background / Scaffold
static const Color oasisMoss = Color(0xFF1E3A2F);   // Primary Surface
static const Color oasisSage = Color(0xFF3D6B55);   // Secondary Surface / Borders
static const Color oasisMist = Color(0xFFA8C5B5);   // Muted Text
static const Color oasisGlow = Color(0xFF7FFFD4);   // Accent / Primary Action
static const Color oasisSand = Color(0xFFE8D9C0);   // Display Headings
static const Color oasisWhite = Color(0xFFF5F5F0);  // Pure Text
```

### Recommendation:
- Use **Oasis Deep** as your `scaffoldBackgroundColor`.
- Use **Oasis Glow** for `floatingActionButtonTheme` and `progressIndicatorTheme`.
- Implement a **subtle radial gradient** in the background of your main views to mimic the "halo" effect from the website.

---

## ✍️ 2. Typography Strategy

The website relies on the contrast between editorial Serifs and clean Sans-serifs.

- **Headings (Page Titles/Headers):** Use `Cormorant Garamond` (Italic) or `DM Serif Display`. In Flutter, ensure these are loaded via `google_fonts` or local assets.
- **Body & UI Labels:** Use `Geist` or `Inter`. Keep tracking tight and line height generous.
- **Technical Stats:** Use `Space Mono` for usage metrics, time limits, and privacy labels.

---

## 🧊 3. Glassmorphism & Surfaces

The "Oasis" feel comes from the layered, blurred surfaces.

- **Implementation:** Use `BackdropFilter` with `ImageFilter.blur` for your App Bar and Bottom Navigation Bar.
- **Styling:**
    - Background: `oasisDeep.withOpacity(0.6)`
    - Border: `oasisGlow.withOpacity(0.1)` with a `1.0` width.
    - Corner Radius: Use large, organic radii (`24.0` or `32.0`).

---

## 🌊 4. Animation & Motion Design

Flutter's `AnimatePresence` equivalent involves `AnimatedSwitcher`, `Hero` widgets, and the `animations` package.

- **Intentional Loading:** Instead of a standard spinner, use a custom "Ripple" animation (expanding circles in `oasisGlow`) that mirrors the Oasis logo.
- **Staggered Lists:** Use `ListView.builder` combined with `flutter_staggered_animations` to ensure feed items fade and slide up as the user scrolls.
- **Hero Transitions:** Use `Hero` tags for user avatars and "Ripple" thumbnails to create a sense of continuity.
- **Smoothness:** Aim for "water-like" motion. Use `Curves.easeOutCubic` for most transitions.

---

## 🧘 5. "Oasis" Exclusive UX Patterns

To truly feel like the "anti-social-media" social network:

1.  **Intentional Friction:** Before opening an "infinite" feed, show a "Deep Breath" prompt or a quick summary of the user's current session time.
2.  **Time Capsules:** Implement a dedicated UI for the Time Capsule feature using an "Envelope" or "Seed" metaphor—avoid standard card layouts here to make it feel special.
3.  **Wellness Dashboard:** Use the "Session Dial" graphic from the website (animated SVG or CustomPainter) as a central widget in the app's home or profile view.
4.  **Privacy Shutter:** Create a physical gesture (like a long press or two-finger swipe) that "blurs" the entire screen—a quick privacy toggle for public spaces.

---

## 🛠 6. Technical Polish

- **Grain Texture:** You can apply a global grain effect in Flutter using a `ShaderMask` with a noise texture PNG, set to a very low opacity (`0.03`).
- **Haptics:** Use `HapticFeedback.lightImpact` for mindful interactions (like selecting a ripple) and `mediumImpact` for significant actions (like harvesting a Time Capsule).
