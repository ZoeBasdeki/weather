# TODO & open issues

## Next steps (Play Store release, agreed 2026-11-04)

Status: version 1.0.1+2 is committed and pushed, with attribution, the About page, the privacy
policy (public URL works), approximate location only, and the MIT licence. It has been used
daily on the real phone.

1. **Store graphics.** All made by Claude: a 512×512 icon (from `assets/icon/`), a 1024×500
   feature graphic, and 2–8 phone screenshots taken from the **emulator only, never the
   personal phone**.
2. **Store texts.** A short description (80 characters max) and a full description (4000
   characters max), crediting Zoe as the maker. Consider a Greek translation of the listing too.
3. **Testers.** Nektarios is collecting the Google account emails (12 or more) of people with
   Android phones.
4. **Play Console** (done together in the browser):
   - Create the app: free, "App", default language.
   - Upload `build/app/outputs/bundle/release/app-release.aab` to a **Closed testing**
     track. Add the testers' emails and send them the opt-in link.
   - Testers must stay opted in for **14 days in a row**. First check whether the
     dashboard actually shows the 12-tester rule for this account.
   - App content forms. The answers are drafted under "Publishing" below.
   - After the test, apply for production access, then publish.
5. **Optional, decide first:** the commit author email (Nektarios's personal email) is
   visible in the public git history. Options:
   - Rewrite history to a GitHub noreply address. This needs a force-push.
   - Leave it as it is. In either case, set a noreply address for future commits.
6. **Later:** Greek app translation; F-Droid (see below); the features and tech items below.

## To do

### Must do
- [x] **About page with the Open-Meteo attribution.** ⓘ in the app bar opens `AboutScreen`
      (attribution + CC BY 4.0 link, privacy summary, version, open-source licences). The
      licence page also says "You must include a link next to any location Open-Meteo data are
      displayed", so every forecast page ends with a linked "Weather data by Open-Meteo.com".
- [x] **Privacy policy public URL.** `PRIVACY.md`, served at
      https://github.com/ZoeBasdeki/weather/blob/main/PRIVACY.md (repo is public). Linked from
      the About page.
- [ ] **Set the real application ID.** It's still `com.example.weather` in
      `android/app/build.gradle.kts` (`namespace` + `applicationId`), and
      `MainActivity.kt` sits in that package path. It has to match the Android app registered
      in the Firebase project before Firebase is added.
- [ ] **Release signing.** Release builds are signed with the debug key right now (template
      default). Create a keystore and a `key.properties` file, and keep both out of version
      control.

### Publishing
- [ ] **Google Play.** Closed test → production. Data safety form: location (approximate +
      precise) collected, sent to Open-Meteo for app functionality, not stored by the developer,
      not shared for ads. No ads. Content rating questionnaire. Store listing screenshots.
- [ ] **F-Droid (later).** Free store for open-source apps; fits Weather Z (no ads, no
      tracking). Needs: public source repo with a FOSS licence (done: MIT, in `LICENSE`); no proprietary dependencies (adding Firebase would block it, or need a
      separate flavour); a merge request to `fdroiddata` on GitLab with build metadata; and
      Fastlane metadata in the repo (`fastlane/metadata/android/en-US/` with title,
      descriptions, screenshots, changelogs). F-Droid builds the APK itself from source and
      signs it with its own key (or uses reproducible builds to ship the developer signature).

### Firebase (when needed)
- [ ] Run `flutterfire configure`, which generates `firebase_options.dart` and
      `google-services.json`.
- [ ] Add `firebase_core` and initialise it in `main()`.
- [ ] Decide what Firebase is for: Crashlytics? Remote Config? Syncing saved cities with
      Firestore?

### Features
- [ ] Reverse geocoding so the GPS location shows a place name instead of "My location"
      (Open-Meteo has no reverse geocoding; use the `geocoding` package or Nominatim).
- [x] App launcher icon (`flutter_launcher_icons`, sources in `assets/icon/`).
- [ ] Splash screen.
- [ ] Better weather icons: a proper weather icon set or SVGs with real day/night variants. Use
      `is_day` for every code, not only 0–2.
- [ ] Charts for hourly temperature and precipitation.
- [ ] Sunrise/sunset, UV index, pressure, visibility (all available from Open-Meteo).
- [ ] Settings: units (°F, mph, inch), 12/24 h clock.
- [ ] Home screen widget.
- [ ] Weather alerts / rain notifications (needs background work, e.g. `workmanager`).

### Tech
- [ ] Service tests with `MockClient` (HTTP errors, timeouts, falling back to the cache).
- [ ] Widget tests for ForecastPage states (loading, empty, from cache, normal) and HomeScreen
      add/remove/undo page handling.
- [ ] Reorder saved places (e.g. `ReorderableListView` in the drawer).
- [ ] Set up a git repo and CI (`flutter analyze` + `flutter test`).
- [ ] Localisation (Greek?) with `intl` / `flutter_localizations`.

## Open issues / known limitations

1. **Adding a city while offline** creates a page that shows an error until the network is
   back, since nothing is cached for it yet.
2. **Stale data has no maximum age.** Cached data is shown however old it is. Consider hiding
   past hours/days from an old cache, or warning when it's older than X hours.
3. **"Now" in the hourly list is the first hourly entry**, not the device clock. That's
   correct while the data is fresh, but for old cached data the first entry is in the past.
4. **Night icons.** Only codes 0–2 have night variants (moon / cloud). Daily rows always use
   the day icon.
5. **GPS timeout.** A fix times out after 15 s and then falls back to the last known position.
   On a cold GPS indoors this can still fail with "Could not determine your location".
6. **Geocoding language** is hard-coded to `en`.
7. **Hourly date marker.** At midnight the hourly strip shows the weekday instead of `00:00`.
   This is intentional, but check that it reads well.
8. **No rate limiting or backoff.** Pull-to-refresh can be spammed. Open-Meteo's free tier
   allows 10k calls a day for non-commercial use, so this is fine for personal use.
9. **`precipitation_probability_max` is often `null` beyond about 10 days**, depending on the
   model. It shows as `–`.
