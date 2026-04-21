---
name: theme-and-hig
description: >-
  Enforces LaunchBox design tokens (AppTheme) and Human Interface Guidelines: 44pt targets, Dynamic Type.
  Use when styling SwiftUI views, reviewing UI code, or the user mentions spacing, padding, or accessibility.
paths:
  - "LaunchBox/Views/**/*.swift"
---

# Theme and HIG

## Spacing and layout

- Use `AppTheme.Spacing` (`xs`, `sm`, `md`, `lg`, `xl`) for padding and stack spacing — **no magic numbers** in `padding()` / `VStack(spacing:)` except `0` when intentional.
- Corner radii: `AppTheme.Radius` (`button`, `card`).
- Shadows: `AppTheme.Shadow` for card-style elevation.

## Touch targets (HIG)

- Minimum interactive area **44×44 pt**: use `.minTapTarget()` from `View+Helpers.swift` on tappable rows and toolbar buttons.
- Pair with `.accessibilityLabel` where the label is not obvious.

## Dynamic Type

- Prefer standard text styles (`.body`, `.headline`, etc.) over fixed font sizes for primary content.
- Use `.sectionHeader()` on `Text` for grouped list section titles when matching existing screens.

## Do / don’t

- Do: `padding(AppTheme.Spacing.md)`
- Don’t: `padding(16)` without a token

Reference: `LaunchBox/Core/AppTheme.swift`, `LaunchBox/Core/Extensions/View+Helpers.swift`.
