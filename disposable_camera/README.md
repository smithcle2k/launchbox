# Snap 24 — a disposable camera app

A Flutter app that recreates the joy (and patience) of a disposable film
camera:

- **24 exposures per roll.** The counter winds down with every shot. No
  retakes, no deleting from the viewfinder.
- **No instant preview.** Shots go straight to the **Darkroom** and only
  become viewable once they've *developed* — by default at **9 AM the next
  morning** (changeable to one hour or instant in settings).
- **Film look baked in at capture time:** muted warm colors, grain,
  vignette, an occasional light leak, and the classic orange date stamp.
- **Flash toggle and camera flip**, just like flipping the little wheel on
  the real thing.
- Finished rolls live in the darkroom; load a fresh roll when one is full.

## Project layout

```
lib/
  main.dart                    # App entry, theme, camera discovery
  models/                      # Photo and FilmRoll (JSON-serializable)
  services/
    develop_schedule.dart      # When photos become viewable
    film_effects.dart          # The film look (runs in an isolate)
    storage_service.dart       # JSON index + JPEG files on disk
  state/app_state.dart         # ChangeNotifier with rolls/capture/settings
  screens/
    camera_screen.dart         # Viewfinder, counter, shutter
    darkroom_screen.dart       # Rolls, develop countdowns, gallery
    photo_view_screen.dart     # Full-screen developed photo
```

## Running

```sh
flutter pub get
flutter run            # on a real device — the camera needs hardware
```

## Tests

```sh
flutter test           # models, develop schedule, film effect pipeline
```
