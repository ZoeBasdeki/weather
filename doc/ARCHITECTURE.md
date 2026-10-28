# Architecture

Weather Z, a personal Android weather app built with Flutter. No ads, no backend. Weather data comes from
[Open-Meteo](https://open-meteo.com/) (free, no API key).

## Layers

Three layers. Dependencies only point downward: UI → services → models.

```
lib/
├── main.dart                     App entry, theme, wires services into HomeScreen
├── models/                       Plain data classes + null-safe JSON parsing (no Flutter I/O)
│   ├── json_utils.dart           asDouble / asInt / asString / asList / asMap / at() helpers
│   ├── forecast.dart             Forecast, CurrentWeather, HourlyWeather, DailyWeather
│   ├── place.dart                Place (geocoded city or GPS fix) + (de)serialisation
│   └── weather_code.dart         WMO weather_code → description + Material icon (day/night)
├── services/                     I/O: network, GPS, local storage
│   ├── weather_service.dart      Open-Meteo /v1/forecast client; shared getJsonBody() helper
│   ├── geocoding_service.dart    Open-Meteo geocoding search (city lookup)
│   ├── location_service.dart     geolocator wrapper: permission flow + one low-accuracy fix
│   ├── cache_service.dart        SharedPreferences store: last raw response per place (Place.id)
│   ├── saved_places_service.dart SharedPreferences store: saved places list + last shown page
│   └── weather_repository.dart   fetch → cache, or fall back to that place's cache on failure
└── ui/
    ├── home_screen.dart          PageView of locations, drawer, add/remove; owns the saved list
    ├── forecast_page.dart        One location's forecast; owns its own load/error state
    ├── search_screen.dart        City search with 400 ms debounce; pops the chosen Place
    ├── format.dart               Display formatting (°, %, mm, km/h, compass, dates)
    └── widgets/
        ├── current_conditions.dart
        ├── hourly_strip.dart     Horizontal 48 h list
        ├── daily_list.dart       14-day list, rows expand for details
        └── wind_arrow.dart
```

State management is just `StatefulWidget` + `setState`. `HomeScreen` owns the list of saved
places and the current page. Each `ForecastPage` owns its own forecast/loading/error state and
uses `AutomaticKeepAliveClientMixin`, so swiping back doesn't refetch. If more screens need
shared state later, move it into a `ChangeNotifier`.

## Multiple locations

- Page 0 is always **My location** (GPS). Saved places follow in the order they were added.
- Searching a city adds it as a page (or jumps to it if it's already there).
- The app bar's delete button (or ✕ in the drawer) removes a city, with Undo in a snackbar.
  Removing a city also deletes its cache entry.
- The drawer lists every page for jumping straight to one. Dots at the bottom show the position.
- The last shown page (`Place.id`) is stored and restored on the next start.
- `Place.id` is `"lat,lon"` for cities and `"gps"` for every GPS fix. Saved places, cache
  entries and page keys all use it.

## Data flow

```
App start
  └─ HomeScreen._init()  ──► load saved places + last shown page ──► PageView at that page

Each ForecastPage, when first built (PageView builds pages lazily as you swipe to them)
  └─ ForecastPage._start()
       ├─ repository.loadCached(place.id)  ──► show cached forecast right away (if any)
       └─ city page?  ──► repository.fetch(city)
          GPS page    ──► location.currentPlace() ──► repository.fetch(gps)
                           (GPS fails → keep the cached GPS forecast, show a snackbar)

repository.fetch(place)
  ├─ ok   → save raw JSON + place + timestamp under place.id → ForecastResult(fromCache: false)
  └─ fail → load that place's cache → ForecastResult(fromCache: true, error: msg)   [banner]
            no cache                → rethrow                                 [empty/error view]
```

## Open-Meteo request

`GET https://api.open-meteo.com/v1/forecast`

| Param | Value |
|---|---|
| `latitude`, `longitude` | from GPS or geocoding |
| `timezone` | `auto` (times returned in the location's local time) |
| `temperature_unit` / `wind_speed_unit` / `precipitation_unit` | `celsius` / `kmh` / `mm` (metric) |
| `forecast_hours` | `48` (hourly series starts at the current hour) |
| `forecast_days` | `14` |
| `current`, `hourly` | `temperature_2m, apparent_temperature, precipitation_probability, precipitation, wind_speed_10m, wind_direction_10m, relative_humidity_2m, weather_code, is_day` |
| `daily` | `weather_code, temperature_2m_max/min, apparent_temperature_max/min, precipitation_probability_max, precipitation_sum, wind_speed_10m_max, wind_direction_10m_dominant, relative_humidity_2m_mean` |

Geocoding: `GET https://geocoding-api.open-meteo.com/v1/search?name=…&count=10&language=en&format=json`.
The `results` key is missing when nothing matches.

## Design decisions

- **Null-safe parsing.** Each value is read through `json_utils.dart`, so nothing throws. A bad
  value becomes `null` and renders as `–`. Hourly/daily data arrives as parallel arrays. Rows are
  built by index with bounds checks (`at()`), and a row whose time won't parse is skipped.
  Open-Meteo does return `null`, e.g. for `precipitation_probability` beyond the model horizon.
- **Cache the raw JSON, not the parsed model.** If the models change, the old cache still loads.
  One response is kept per place, under separate keys (`forecast.<id>.json` / `.place` /
  `.fetchedAt`), so pages loading at the same time don't overwrite each other. Storage is
  `SharedPreferencesAsync`.
- **Offline detection = request failed.** There's no connectivity package. Any network error
  falls back to the cache, and the UI says how old the data is.
- **Times are location-local.** Since `timezone=auto`, times come back without an offset and
  get parsed as naive `DateTime`s. The UI never compares them with the device clock. "Today"
  and "Tomorrow" come from the daily index, and "Now" is the first hourly entry.
- **Location accuracy is low.** City-level accuracy is enough for weather. It's faster and uses
  less battery. Android 12+ lets the user grant approximate location only.
- **Icons are built-in Material Icons.** No icon package is needed. Day and night variants
  exist only for clear and partly cloudy (codes 0–2).
- **Services take an optional `http.Client`** so they can be tested with `MockClient`.

## Dependencies

| Package | Purpose |
|---|---|
| `http` | REST calls |
| `geolocator` | GPS position + permission handling |
| `shared_preferences` | Local cache |
| `intl` | Date/time formatting |

Firebase is set up in the Firebase console but **not** integrated in the app yet (see TODO.md).

## Android config

- `AndroidManifest.xml` has `INTERNET`, `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- The application ID is still the template default, `com.example.weather` (see TODO.md).
- `android/gradle.properties` sets `kotlin.incremental=false`. The project is on `E:` and the
  pub cache is on `C:`. Kotlin incremental compilation fails on plugin sources across drives,
  with the error "Could not close incremental caches". You can remove the setting if both end
  up on the same drive.

## Tests

`test/models_test.dart` covers JSON parsing (including malformed input), `Place.id`, WMO
mapping and compass formatting. Run it with `flutter test`.
