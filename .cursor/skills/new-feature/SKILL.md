---
name: new-feature
description: >-
  Scaffolds a LaunchBox feature: View, ViewModel, optional Model, and AppRoute wiring.
  Use when adding a new screen with navigation, or when the user says "new feature" or "scaffold".
argument-hint: "<FeatureName>"
---

# New feature scaffold

Arguments: feature name in PascalCase, e.g. `Bookmarks` (produces `BookmarksView`, `BookmarksViewModel`).

## Steps

1. **Pick folder name** — Usually the same as the feature: `Views/Bookmarks/`.
2. **Create ViewModel** — `ViewModels/BookmarksViewModel.swift` using the pattern in [template-viewmodel.swift](../new-viewmodel/template-viewmodel.swift) (adapt imports if SwiftData not needed).
3. **Create View** — `Views/Bookmarks/BookmarksView.swift` using [template-view.swift](../new-view/template-view.swift).
4. **Add route** — In `Core/AppRouter.swift`, extend `AppRoute`:

   ```swift
   case bookmarks  // or .bookmarksDetail(UUID) with associated values as needed
   ```

5. **Wire navigation** — In `Views/RootView.swift`, extend **each** `navigationDestination(for: AppRoute.self)` `switch` that should present this screen:

   ```swift
   case .bookmarks:
       BookmarksView(router: router)
   ```

6. **Navigate from a tab** — Where appropriate, e.g. `router.homePath.append(AppRoute.bookmarks)` (use the correct path property for that tab).
7. **Xcode** — Add new files to the LaunchBox target (folder references usually pick them up; verify in Project Navigator).
8. **Optional model** — If the feature needs persistence, add `Models/YourModel.swift`, register in `LaunchBoxApp` `Schema`, and migrate if needed.

## Checklist

Copy and track:

- [ ] `AppRoute` case added
- [ ] All relevant `navigationDestination` switches updated (often four stacks in `RootView`)
- [ ] View uses `AppTheme` and `.minTapTarget()` for controls
- [ ] Strings use `String(localized:)` where user-visible

See also [scaffold-checklist.md](scaffold-checklist.md).
