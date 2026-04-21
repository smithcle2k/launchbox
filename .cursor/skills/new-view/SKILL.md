---
name: new-view
description: >-
  Creates a LaunchBox SwiftUI view file with header, Preview, AppTheme spacing, and min tap targets.
  Use when adding a standalone view or the user says "new SwiftUI view".
argument-hint: "<Name> [subfolder under Views]"
---

# New SwiftUI view

Arguments: `$0` = view name (PascalCase, no `View` suffix required — e.g. `Bookmarks` or `BookmarksView`). `$1` optional: subfolder under `Views/` (default: same as name, e.g. `Bookmarks`).

Output: `Views/<Folder>/<Name>View.swift` (if name lacks `View`, append `View`).

## Steps

1. Resolve `Folder` = `$1` if present, else `$0` stripping a trailing `View` if any.
2. Copy structure from [template-view.swift](template-view.swift); replace `__FEATURE__` with the feature name stem (e.g. `Bookmarks`).
3. Add `import SwiftUI` only unless the view needs SwiftData, etc.
4. Ensure buttons/links use `.minTapTarget()` and `AppTheme.Spacing` for padding.
5. Add `#Preview` with minimal dependencies (inject `AppRouter()` if the real view needs it).

## Conventions

- `String(localized:)` for user-visible text.
- Prefer semantic spacing from `AppTheme.Spacing` over raw numbers in `padding` / `spacing`.
