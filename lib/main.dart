import 'package:flutter/material.dart';

import 'services/geocoding_service.dart';
import 'services/location_service.dart';
import 'services/saved_places_service.dart';
import 'services/weather_repository.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.lightBlue;
    return MaterialApp(
      title: 'Weather Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomeScreen(
        repository: WeatherRepository(),
        location: LocationService(),
        geocoding: GeocodingService(),
        savedPlaces: SavedPlacesService(),
      ),
    );
  }
}
