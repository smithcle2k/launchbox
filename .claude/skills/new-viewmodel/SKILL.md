---
name: new-viewmodel
description: >-
  Creates a LaunchBox view model using @Observable @MainActor final class, matching HomeViewModel style.
  Use when adding screen state, or the user says "new view model".
argument-hint: "<Name>"
---

# New view model

Arguments: feature name stem (e.g. `Bookmarks` → type `BookmarksViewModel`).

## Steps

1. Create `ViewModels/<Name>ViewModel.swift`.
2. Start from [template-viewmodel.swift](template-viewmodel.swift); replace `__FEATURE__` with the name stem.
3. Add imports only as needed: `Foundation`, `SwiftData`, `SwiftUI` (SwiftUI if using `Color`/`Image` in VM — prefer keeping VMs free of SwiftUI when possible).
4. Prefer async methods for work that touches `ModelContext` or network.
5. Use `String(localized:)` for any user-facing error strings stored in the VM.

## Patterns (from existing VMs)

- Loading + error: `isLoading`, `errorMessage` optional `String`, or feature-specific flags like `isSearching`.
- For lists: fetch with `FetchDescriptor`, handle errors by clearing data and setting `errorMessage`.

## Anti-patterns

- Do not use `ObservableObject` / `@Published` unless migrating an older module — new code uses `@Observable`.
