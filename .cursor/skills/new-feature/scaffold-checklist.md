# Feature scaffold checklist

Use with `/new-feature` or when hand-rolling a feature.

## Files

- [ ] `Views/<Feature>/<Feature>View.swift`
- [ ] `ViewModels/<Feature>ViewModel.swift`
- [ ] Optional: `Models/<Entity>.swift` + `Schema` in app entry

## Router

- [ ] New `AppRoute` case in `Core/AppRouter.swift`
- [ ] `RootView`: each `NavigationStack` that needs this destination has a matching `case` in `navigationDestination(for: AppRoute.self)`

## Quality

- [ ] File headers (`//  File.swift` / `//  LaunchBox`)
- [ ] No secrets in source — use `Secrets` + plist
- [ ] Interactive controls ≥ 44pt (`.minTapTarget()`)
