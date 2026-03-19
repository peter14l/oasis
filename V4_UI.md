# Morrow V4 UI/UX Redesign Plan: Direct Messages & Chat

This document outlines the strategic plan to transform the Morrow messaging experience from a functional utility into a "special" and "unique" immersive environment. The goal is to move away from "safe and corporate" layouts toward a kinetic, fluid, and deeply layered UI.

## 1. "Ethereal" Conversations List
The entry point to messaging should feel organized yet fluid, moving beyond static list tiles.

### Kinetic List Items (Squish & Stretch)
- **Concept:** Implement physics-based interaction for the conversation list.
- **Behavior:** As the user scrolls, cards subtly "compress" or "expand" based on scroll velocity. Reaching the end of the list triggers a "rubber-band" squish effect on the individual items.
- **Goal:** Provide a tactile, organic feel to navigation.

### Presence Ripples
- **Concept:** Transform static status dots into living indicators.
- **Behavior:** Online indicators feature a soft pulse/breath animation. When a contact is typing, a glowing "aura" ripples behind their avatar in the main list, providing immediate visual feedback without reading text.

### Vibe-Based Backgrounds
- **Concept:** Individualized conversation "previews."
- **Behavior:** Each list item features a subtle, semi-transparent mesh gradient background that reflects the color palette of that specific chat's theme (or the user's profile colors).
- **Goal:** Make the list look like a curated collection of unique "spaces."

### Bento-Grid Pinned Chats
- **Concept:** Visual hierarchy for close connections.
- **Behavior:** Move "Pinned" conversations from a vertical list into a "Bento Box" layout at the top with varying card sizes.
- **Goal:** Distinguish primary connections from the general message flow.

---

## 2. "Kinetic" Chat Experience
The chat screen is the heart of the interaction and should feel like a deep, layered space.

### Liquid Message Bubbles
- **Concept:** Physics-driven message shapes.
- **Behavior:** Replace static rounded corners with "Liquid Bubbles" using Custom Painters. Bubbles "wobble" slightly when they first appear or when the list is flicked, as if made of a soft, jelly-like material.
- **Logic:** Bubbles "stick" together slightly when sent in quick succession by the same user.

### Deep Glassmorphism (Triple-Layer)
- **Concept:** Enhanced visual depth.
- **Layering:**
    - *Layer 1 (Deep):* A slowly shifting, animated mesh gradient background.
    - *Layer 2 (Middle):* Glassmorphic message bubbles with high-sigma blur (30px+) and thin, vibrant borders.
    - *Layer 3 (Top):* Sharp text and high-contrast iconography.

### Stealth Whisper Mode
- **Concept:** An immersive "private" state.
- **Transition:** Enabling Whisper Mode triggers a "Stealth Transition"—colors shift to monochromatic dark tones with a subtle film-grain or glitch overlay.
- **Vaporization Effect:** When a message expires, it doesn't just disappear; it "vaporizes" using a particle smoke shader or a "glitch-out" animation.

### Glow-Wave Audio
- **Concept:** Reactive voice messaging.
- **Behavior:** Standard progress bars are replaced with glowing, interactive waveforms that react to the audio frequency during playback. The waveform "glows" brighter during louder segments.

---

## 3. Unique "Special" Interactivity
Features designed to set Morrow apart from traditional messaging apps.

### The "Canvas Peek"
- **Concept:** Merging Messaging with the Canvas identity.
- **Interaction:** Pulling down on the chat list (beyond the top) reveals a "Shared Canvas Peek." Users can quickly doodle a note or drawing that appears as a temporary background element for both participants.

### Burst Reactions
- **Concept:** Haptic-driven feedback.
- **Behavior:** Tapping a reaction triggers a "particle burst." Small fragments of the emoji's color explode from the touch point and settle onto the message bubble before fading.
- **Haptics:** Integrated "micro-clicks" for every particle explosion.

### Smart-Reply Glow
- **Concept:** Pro-active AI assistance.
- **Behavior:** Smart reply suggestions appear with a shimmering neon border (matching the chat's accent color), making them feel like an integrated part of the "system" rather than buttons added on top.

---

## 4. Technical Implementation Strategy

### Graphics & Performance
- **Custom Painters:** Required for liquid bubble shapes and "Squish & Stretch" logic.
- **Impeller Optimization:** All blurs and gradients must be profiled to ensure a locked 60/120 FPS on supported devices.
- **Shader Graph:** Utilize fragment shaders (.frag) for high-performance mesh gradients and the Whisper Mode "vaporization" effect.

### Interactive Elements
- **Haptic API:** Extensive use of `HapticFeedback` for "micro-interactions" (wobbles, bursts, and pulls).
- **Physics Engine:** Use `flutter_physics` or custom spring simulations for the list and bubble animations.

### Theming
- **Dynamic Palette Extraction:** Extend the `PaletteGenerator` logic to automatically update the "aura" and "vibe" backgrounds based on the latest shared media or profile updates.
