# Gen Z Redesign Plan for Morrow V2

This plan outlines the technical changes to transform the current "safe and corporate" UI into a vibrant, Gen Z-focused experience.

## User Review Required

> [!IMPORTANT]
> This redesign involves significant changes to the app's color palette and visual identity. Please review the proposed color shifts and element styles.

## Proposed Changes

### Theme & Colors
- [MODIFY] [app_colors.dart](file:///f:/morrow_v2/lib/themes/app_colors.dart): Update `primary`, `secondary`, and `tertiary` colors to more vibrant versions (e.g., Electric Blue, Magenta, Cyber Lime).
- [MODIFY] [app_theme.dart](file:///f:/morrow_v2/lib/themes/app_theme.dart):
    - Enhance `InputDecorationTheme` with neon glow effects on focus.
    - Update `ElevatedButtonTheme` to use multi-color gradients.
    - Increase `BackdropFilter` blur values for a more pronounced glassmorphism effect.

### Components
- [MODIFY] [post_card.dart](file:///f:/morrow_v2/lib/widgets/post_card.dart):
    - Add subtle mesh gradient backgrounds to the card itself (semi-transparent).
    - Implement a "pop" animation for heart/like interactions.
    - Use broader border radii (24px instead of 16px).
- [MODIFY] [stories_bar.dart](file:///f:/morrow_v2/lib/widgets/stories_bar.dart):
    - Update unviewed story rings to use a 3-color vibrant gradient.
    - Add a slight scale-up effect on hover/tap.

### Screens
- [MODIFY] [profile_screen.dart](file:///f:/morrow_v2/lib/screens/profile_screen.dart):
    - Refactor the stat area into a "Bento Grid" style layout with varied card sizes and vibrant background tints.
- [MODIFY] [feed_screen.dart](file:///f:/morrow_v2/lib/screens/feed_screen.dart):
    - Update the segmented button colors to be more distinct and vibrant.

## Verification Plan

### Automated Tests
- No automated UI tests currently exist for visual character. I will manually verify using the browser tool if applicable, or rely on screen inspections.

### Manual Verification
- **Visual Inspection**: Launch the app and go through Feed, Profile, and Stories.
- **Contrast Check**: Ensure text remains readable over vibrant backgrounds (WCAG compliance).
- **Animation Smoothness**: Verify that new gradients and blurs don't impact performance on low-end devices.
