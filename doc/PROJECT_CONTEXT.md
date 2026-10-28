# Project context (start here in a new chat)

Read this file first, then [ARCHITECTURE.md](ARCHITECTURE.md) and [TODO.md](TODO.md).

## What this is

Weather Z, a personal weather app for Android, written in Flutter/Dart.
- No ads, no backend for now.
- Firebase is set up in the Firebase console but not integrated in the code yet.
- Project folder: `E:\codes\weather`.

## Original requirements

- **Data source:** the Open-Meteo forecast API (no API key), with `timezone=auto` and metric units.
- **Data requested:** current conditions, hourly for 48 h and daily for 14 days. Fields:
  temperature, apparent temperature, precipitation probability and amount, wind speed and
  direction, humidity, `weather_code`.
- **Location:** device GPS via `geolocator`, plus city search via the Open-Meteo geocoding API.
- **Weather codes:** map WMO `weather_code` to icons and text descriptions.
- **Offline:** cache the last response locally and show cached data when offline.
- **Attribution:** "Weather data by Open-Meteo.com" (CC BY 4.0). It goes on an About page,
  which hasn't been built yet. This is the top must-do in TODO.md.
- **Architecture:** keep it simple, with models, a service layer and the UI. Use null-safe
  parsing.
- **Packages:** use current stable versions from pub.dev.

## Current status (2026-10-28)

**Done:**
- All of the above is implemented, except the About page.
- Multiple locations: swipe between My location and saved cities, with a drawer to jump or
  remove. Search adds a city. Forecasts are cached per place.
- `flutter analyze` reports no issues, and `flutter test` passes 6 of 6.
- The debug APK builds.

**Not yet verified:** running the app on a real device.

## Environment

| Item | Value |
|---|---|
| OS | Windows 11 |
| Flutter | 3.44.4 (stable) |
| Dart | 3.12.2 |
| Flutter SDK | `C:\src\flutter` |
| Phone | Samsung Galaxy A55 (SM A556B), device ID `R5CX31AZLED`, Android 16 (API 36) |
| Emulator | `emulator-5554`, Android 16 (API 36) |
| Platforms | Android only (`flutter create --platforms=android`) |
| App name | `Weather Z` (`android:label` in `AndroidManifest.xml` + `MaterialApp.title` in `main.dart`). The Dart package stays `weather`. |
| Application ID | `com.example.weather` (placeholder; must match the Firebase Android app before Firebase is added) |
| Git | not initialised yet |

## Packages

These were the latest versions on pub.dev as of 2026-10-28.

| Package | Version |
|---|---|
| `http` | ^1.6.0 |
| `geolocator` | ^14.1.2 |
| `shared_preferences` | ^2.5.6 |
| `intl` | ^0.20.3 |
| `flutter_lints` (dev) | ^6.0.0 |
| `flutter_launcher_icons` (dev) | ^0.14.4 |

`cupertino_icons` was removed because the app is Android only.

## Commands

```
flutter run -d R5CX31AZLED              # debug on phone (r = hot reload, R = restart, q = quit)
flutter run --release -d R5CX31AZLED    # release build, stays on phone, runs standalone
flutter analyze
flutter test
flutter build apk --debug               # output: build\app\outputs\flutter-apk\app-debug.apk
dart run flutter_launcher_icons         # regenerate launcher icon from assets/icon/ (config in pubspec.yaml)
```

## Gotchas already solved

- **Kotlin incremental compilation fails across drives.**
  - Symptom: the build fails with "Could not close incremental caches" (seen in
    `package_info_plus` and `shared_preferences_android`).
  - Cause: the project is on `E:` and the pub cache is on `C:`.
  - Fix: `kotlin.incremental=false` in `android/gradle.properties`.
- **INTERNET permission.** Release builds need it declared in the main `AndroidManifest.xml`.
  The template only adds it for debug and profile builds. The main manifest now declares it,
  along with `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- **No partly-cloudy Material icons.** Flutter's Material `Icons` has no
  `partly_cloudy_day/night`, so code 2 uses `wb_cloudy` (day) and `cloud` (night).

## Verified API facts

Checked against the live API on 2026-10-28.
- `forecast_hours=48` returns exactly 48 hourly rows, starting at the current hour.
- `forecast_days=14` returns 14 daily rows. Day 0 is "today" in the location's timezone.
- The daily field `relative_humidity_2m_mean` exists and is used.
- Times come back as ISO strings in local time, with no offset (because of `timezone=auto`).
- Geocoding leaves out the `results` key when nothing matches.
- On errors the API returns HTTP 400 with `{"error": true, "reason": "..."}`.

## Code conventions

- **State:** `StatefulWidget` + `setState`. `HomeScreen` owns the page list and each
  `ForecastPage` owns its own forecast state. There's no state management package.
- **JSON:** always read through `lib/models/json_utils.dart` (`asDouble`, `asInt`, `asList`,
  `at()`, and so on). Never cast JSON directly.
- **Dependency direction:** UI → services → models. Services take an optional `http.Client`
  for tests.
- **Error handling:** service errors are `WeatherServiceException(message)`; location errors
  are `LocationException(LocationFailure)`.
- **Formatting:** all display formatting lives in `lib/ui/format.dart` (`Fmt`). Null values
  render as `–`.
