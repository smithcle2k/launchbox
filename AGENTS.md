# AGENTS.md

You are an expert Flutter and Dart engineer helping me build Snap 24. Write clean, simple, maintainable code. Prioritize clarity over unnecessary abstraction. Think like a senior mobile developer.

---

## Project Overview

We are building Snap 24, a disposable film camera app: 24 shots per roll, no instant preview, and photos that "develop" the next morning.

The app includes:

- A viewfinder camera screen with a wind-down exposure counter, flash toggle, and camera flip
- 24-exposure film rolls — no retakes, no deleting from the viewfinder
- A film look baked in at capture time: muted warm colors, grain, vignette, occasional light leaks, and an orange date stamp
- A Darkroom where photos sit until they develop (9 AM next morning by default; one hour or instant via settings)
- Finished-roll management: browse developed rolls, load a fresh roll when one is full

Keep the implementation simple and readable.

---

## Tech Stack

- Flutter (stable channel)
- Dart with strict analysis (`flutter_lints`)
- `provider` with `ChangeNotifier` for state management
- `camera` for capture
- `image` for film-effect processing (run in an isolate via `compute`)
- `shared_preferences` for settings persistence
- `path_provider` + JSON index + JPEG files on disk for photo storage

Do not introduce new packages unless there is a strong reason. Ask before adding anything to `pubspec.yaml`.

---

## Development Philosophy

Build feature by feature. For every feature:

1. Read this file first.
2. Keep the implementation simple.
3. Avoid overengineering.
4. Prefer readable code over clever code.
5. Build the smallest useful version first.
6. Refactor only when repetition appears.

---

## Decision Making

If something is unclear or could be improved, suggest a better approach. If a new package would significantly help, recommend it, explain why, and ask before adding it. Do not add packages without approval.

---

## Architecture

Use this folder structure:

```
lib/
  main.dart        # App entry, theme, camera discovery
  models/          # Plain data classes (JSON-serializable)
  screens/         # Full screens / routes
  services/        # Side-effect logic: storage, effects, scheduling
  state/           # ChangeNotifier app state
  utils/           # Small pure helpers
assets/
test/
```

**screens/** is for full screens only. Screens compose widgets and read state via `Provider`/`context.watch`. They should not contain business logic or file I/O. Extract private widget classes (e.g. `_ShutterButton`, `_ExposureCounter`, `_TopBar`) within a screen file when it makes the build method easier to read; promote a widget to its own file only when it is reused across screens.

**models/** holds plain data classes like `Photo` and `FilmRoll`. Keep them immutable where practical, with `toJson`/`fromJson`. No Flutter imports in models.

**state/** holds `ChangeNotifier` classes like `AppState` (current roll, capture flow, develop-speed setting). Persist settings with `shared_preferences`. Call `notifyListeners()` once per logical change.

**services/** holds side-effect logic: `storage_service.dart` (disk), `film_effects.dart` (image processing — always run heavy work in an isolate with `compute`), `develop_schedule.dart` (when photos become viewable). Services do not import Flutter widgets.

**utils/** holds small pure functions (e.g. date helpers). No state, no I/O.

---

## UI Rules

For any UI task:

- Replicate the provided design exactly.
- Match layout, spacing, padding, font sizes, font hierarchy, colors, border radius, shadows, alignment, and proportions.
- Do not approximate. Do not simplify unless explicitly asked.

---

## Styling Rules

- Use the app `ThemeData` defined in `main.dart` for colors and text styles. Do not hardcode colors inline when a theme value exists.
- Reuse shared constants for repeated spacing or styling values instead of scattering magic numbers.
- Prefer composition of small widgets over deeply nested build methods.
- Use `const` constructors wherever possible.

---

## Assets

- Declare all assets in `pubspec.yaml` under `flutter/assets`.
- Reference asset paths through a single constants file (create `lib/utils/assets.dart` if needed) rather than scattering string literals through widgets.

---

## State Management

- `provider` + `ChangeNotifier` for app-wide state (`AppState`).
- `StatefulWidget` local state for temporary UI state (animations, controllers, toggles that don't outlive the screen).
- `shared_preferences` for lightweight settings; the JSON/JPEG store via `StorageService` for photos and rolls.
- Never block the UI thread: image processing goes through `compute`.

---

## Dart Rules

- Keep `flutter analyze` clean; fix all lints before finishing.
- No `dynamic` unless interfacing with JSON, and convert to typed models immediately.
- Keep types simple and readable. Prefer named parameters for widgets and models.

---

## Feature Implementation

When building a feature:

1. Read this file first.
2. Identify the files to change.
3. Keep changes focused.
4. Do not rewrite unrelated code.
5. Follow existing patterns.
6. Make sure the feature works end to end.
7. Run `flutter analyze` and `flutter test`; fix errors before finishing.

---

## Secrets

- This app is fully offline today; keep it that way unless we decide otherwise.
- Never commit secret keys. If a feature ever needs an external API, route it through a server — never embed keys in the client.

---

## Communication

Be concise. Explain what changed and how to test it.

---

## Final Reminder

Before every feature:

- Read this file.
- Follow it strictly.
- Build clean, simple code.
- Replicate UI exactly when designs are provided.
