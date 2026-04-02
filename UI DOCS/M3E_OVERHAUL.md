# Material 3 Expressive (M3E) Overhaul

## Overview
Material 3 Expressive is an evolution of the Material 3 design system that focuses on emotional, high-contrast, and personalized user experiences. It aims to improve usability and identification of key UI elements.

## Core Principles
- **Vibrancy**: Moving beyond flat minimalist aesthetics to rich, high-contrast palettes.
- **Emphasis**: Using shape, typography, and containment to guide focus and prioritize actions.
- **Fluidity**: Implementing motion that feels springy, natural, and responsive.

## 1. Color System (Vibrant & High Contrast)
- **Primary/Secondary/Tertiary**: Use expanded vibrant tones (purples, corals, pinks) to create energy.
- **Surface Tones**: High-contrast surface roles to make primary actions pop.
- **Tonal Roles**: Every key color (Primary, Secondary, Tertiary, Neutral, Error) has 13 tones for maximum accessibility.
- **Dynamic Harmonization**: Brand colors are subtly shifted to match user themes while maintaining semantic meaning.

## 2. Shapes & Containment (Iconic & Adaptive)
- **Shape Library**: Introduction of 35+ iconic shapes (abstract, floral, geometric) for avatars, crops, and decorative elements.
- **Shape Morphing**: Smooth transitions between shapes during interactions (e.g., FAB morphing into a sheet).
- **Corner Radii**: 
  - Five levels: Extra-Small, Small, Medium, Large, Extra-Large.
  - "Full" token for complete rounding.
- **Contrasted Containers**: High-contrast borders and backgrounds for interactive regions to signify interactive potential.

## 3. Typography (Editorial & Expressive)
- **Emphasized Styles**: 15 type styles (Display Large to Label Small) with increased weights for headlines and CTAs.
- **Variable Fonts**: Utilization of fonts like **Roboto Flex** and **Roboto Serif** with dynamic weight/width adjustments.
- **Motion-Linked Type**: Text weight increases on hover/tap/scroll for better tactile feedback.

## 4. Motion (Natural & Springy)
- **Standard Easing Replace**: Move to motion physics (springs) for more organic-feeling transitions.
- **State Feedback**: Use fluid animations for state changes (button presses, list loading).

## Implementation Strategy
- **Toggle State**: Managed in `ThemeProvider`.
- **Theme Delivery**: `AppTheme` will provide alternate `m3eLightTheme` and `m3eDarkTheme` based on the toggle.
- **Global Impact**: Using Flutter's `ThemeData` to propagate changes across all standard widgets.
- **Custom Components**: Update custom widgets to respect the M3E configuration from the theme.
