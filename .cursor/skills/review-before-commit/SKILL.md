---
name: review-before-commit
description: >-
  Pre-commit checklist for LaunchBox: style, theme tokens, secrets, build.
  Use before git commit, or when the user asks for a quick review pass.
disable-model-invocation: true
---

# Review before commit

Run through this list on the **changed** files and fix issues before committing.

## 1. Hygiene

- [ ] No stray `print(` / `debugPrint(` in release paths (OK behind `#if DEBUG` if needed).
- [ ] No commented-out blocks of dead code left from experiments.
- [ ] File headers present on new Swift files (`//  Name.swift` / `//  LaunchBox`).

## 2. UI / theme

- [ ] No raw spacing numbers — use `AppTheme.Spacing` / `Radius` / `Shadow`.
- [ ] Tappable controls use `.minTapTarget()` where appropriate.
- [ ] User-visible strings use `String(localized:)` for new copy.

## 3. Secrets

- [ ] No new hardcoded URLs or keys — follow `secrets-guard` / `Secrets.swift`.

## 4. Build

From repo root (macOS Terminal):

```bash
cd /path/to/LaunchBox
xcodebuild -scheme LaunchBox -destination 'generic/platform=iOS Simulator' build
```

Adjust scheme name if the fork renamed the target. Fix compile errors before commit.

## 5. Output

Summarize: what changed, any remaining TODOs, and confirmation checklist above is addressed.
