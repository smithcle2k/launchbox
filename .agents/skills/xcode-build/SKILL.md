---
name: xcode-build
description: >-
  Builds the LaunchBox iOS target with xcodebuild for quick compile verification.
  Use when verifying changes compile, before commit, or when the user says "build" or "xcodebuild".
argument-hint: "[scheme]"
allowed-tools: Bash(xcodebuild *)
disable-model-invocation: true
---

# Xcode build

Optional argument: scheme name (default **`LaunchBox`**).

## Command (from repository root)

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
xcodebuild -scheme "${0:-LaunchBox}" -destination 'generic/platform=iOS Simulator' build
```

If you need a specific simulator runtime:

```bash
xcodebuild -scheme "${0:-LaunchBox}" -destination 'platform=iOS Simulator,name=iPhone 16' build
```

List simulators: **Xcode → Window → Devices and Simulators**, or:

```bash
xcrun simctl list devices available
```

## Tests

This boilerplate may not include a unit test target. If tests exist, add:

```bash
xcodebuild -scheme "${0:-LaunchBox}" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## On failure

Paste the first compiler error block; fix files in order of dependency (models → services → view models → views).
