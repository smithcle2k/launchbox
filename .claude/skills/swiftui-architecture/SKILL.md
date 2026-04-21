---
name: swiftui-architecture
description: >-
  LaunchBox SwiftUI MVVM conventions: folder layout, naming, routing, and layer boundaries.
  Use when creating or moving Swift files, scaffolding features, or refactoring structure.
paths:
  - "**/*.swift"
---

# LaunchBox architecture

## Folder layout (under `LaunchBox/`)

| Area | Purpose |
|------|---------|
| `Core/` | App-wide: `AppRouter`, `AppTheme`, extensions, `Secrets` |
| `Models/` | SwiftData models and domain types shared across features |
| `Services/` | Side effects: networking, push, haptics — no SwiftUI in services |
| `ViewModels/` | One primary type per screen: `<Feature>ViewModel` |
| `Views/<Feature>/` | SwiftUI for that feature: `<Feature>View.swift`, subviews |
| `Resources/` | Plists, assets docs (e.g. `SECRETS_SETUP.md`, `Secrets.sample.plist`) |

## Naming

- Views: `HomeView`, `ExploreView` — suffix `View`.
- View models: `HomeViewModel`, `ExploreViewModel` — suffix `ViewModel`.
- Router types live in `Core/AppRouter.swift`: `AppPhase`, `AppTab`, `AppRoute`, `AppRouter`.

## MVVM boundaries

- **Views**: SwiftUI, `@Bindable` / `@Environment`, call view model methods; avoid business logic beyond formatting and trivial UI state.
- **View models**: `@Observable`, `@MainActor`, `final class`; hold screen state, async work, SwiftData `ModelContext` usage coordinated from the view or injected.
- **Models**: persistence and value types; no UI imports unless needed for lightweight helpers.
- **Services**: singletons or injectable types; no direct reference to `View` types.

## Routing

- Tabs: `AppTab` + `AppRouter.selectedTab` and per-tab `NavigationPath` (`homePath`, `explorePath`, etc.).
- Stack destinations: `enum AppRoute` in `AppRouter.swift`; `navigationDestination(for: AppRoute.self)` in `RootView` (repeat the `switch` for each tab stack that needs the route).

## App entry

- `LaunchBoxApp.swift`: `ModelContainer`, `WindowGroup`, root view (`RootAppView` / shell).
- Prefer `String(localized:)` for user-visible copy.

## File header

Every new Swift file:

```text
//
//  FileName.swift
//  LaunchBox
//
```

## Additional references

- Theme tokens: `Core/AppTheme.swift`
- Touch targets: `Core/Extensions/View+Helpers.swift` (`.minTapTarget()`)
