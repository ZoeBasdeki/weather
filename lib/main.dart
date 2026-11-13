import 'package:flutter/material.dart';

import 'services/geocoding_service.dart';
import 'services/location_service.dart';
import 'services/saved_places_service.dart';
import 'services/theme_service.dart';
import 'services/weather_repository.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so the app doesn't flash the wrong theme.
  final themes = ThemeService();
  runApp(WeatherApp(themes: themes, initialThemeMode: await themes.load()));
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key, required this.themes, required this.initialThemeMode});

  final ThemeService themes;
  final ThemeMode initialThemeMode;

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  // Created once; rebuilding for a theme change must not replace them.
  final _repository = WeatherRepository();
  final _location = LocationService();
  final _geocoding = GeocodingService();
  final _savedPlaces = SavedPlacesService();

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.themes.save(mode);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Colors.lightBlue;
    return MaterialApp(
      title: 'Weather Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        repository: _repository,
        location: _location,
        geocoding: _geocoding,
        savedPlaces: _savedPlaces,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
