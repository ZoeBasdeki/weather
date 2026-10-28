import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather/models/forecast.dart';
import 'package:weather/models/place.dart';
import 'package:weather/models/weather_code.dart';
import 'package:weather/ui/format.dart';

void main() {
  group('Forecast.fromJson', () {
    test('parses a typical response', () {
      final f = Forecast.fromJson(jsonDecode(_sample) as Map<String, dynamic>);
      expect(f.timezone, 'Europe/Athens');
      expect(f.current?.temperature, 13.8);
      expect(f.current?.humidity, 57);
      expect(f.current?.isDay, isTrue);
      expect(f.hourly, hasLength(2));
      expect(f.hourly[1].precipitationProbability, isNull); // null in JSON
      expect(f.daily, hasLength(2));
      expect(f.daily[0].temperatureMax, 14.9);
      expect(f.daily[1].precipitationProbabilityMax, isNull); // short array
    });

    test('survives missing / wrongly typed sections', () {
      final f = Forecast.fromJson({
        'current': 'oops',
        'hourly': {'time': ['bad-date', '2026-10-28T10:00'], 'temperature_2m': 'x'},
      });
      expect(f.current, isNull);
      expect(f.hourly, hasLength(1));
      expect(f.hourly.single.temperature, isNull);
      expect(f.daily, isEmpty);
    });
  });

  test('Place geocoding parse rejects entries without coordinates', () {
    expect(Place.fromGeocodingJson({'name': 'X'}), isNull);
    final p = Place.fromGeocodingJson(
        {'name': 'Athens', 'latitude': 37.98, 'longitude': 23.72, 'country': 'Greece'});
    expect(p?.subtitle, 'Greece');
    expect(Place.fromJson(p!.toJson())?.name, 'Athens');
  });

  test('Place.id is stable across JSON and shared by all GPS fixes', () {
    const athens = Place(name: 'Athens', latitude: 37.98, longitude: 23.72);
    expect(Place.fromJson(athens.toJson())?.id, athens.id);
    expect(athens.id, isNot(Place.currentLocationId));
    const gps1 = Place(name: 'My location', latitude: 1, longitude: 2, isCurrentLocation: true);
    const gps2 = Place(name: 'My location', latitude: 3, longitude: 4, isCurrentLocation: true);
    expect(gps1.id, Place.currentLocationId);
    expect(gps2.id, gps1.id);
  });

  test('WMO codes map to descriptions, unknown falls back', () {
    expect(WeatherCode.fromCode(0).description, 'Clear sky');
    expect(WeatherCode.fromCode(95).description, 'Thunderstorm');
    expect(WeatherCode.fromCode(1234), WeatherCode.unknown);
    expect(WeatherCode.fromCode(null), WeatherCode.unknown);
  });

  test('compass directions', () {
    expect(Fmt.compass(0), 'N');
    expect(Fmt.compass(350), 'N');
    expect(Fmt.compass(90), 'E');
    expect(Fmt.compass(225), 'SW');
  });
}

const _sample = '''
{
  "timezone": "Europe/Athens",
  "utc_offset_seconds": 7200,
  "current": {"time": "2026-10-28T16:30", "temperature_2m": 13.8, "apparent_temperature": 11.5,
    "precipitation_probability": 0, "precipitation": 0.0, "wind_speed_10m": 8.5,
    "wind_direction_10m": 306, "relative_humidity_2m": 57, "weather_code": 1, "is_day": 1},
  "hourly": {
    "time": ["2026-10-28T16:00", "2026-10-28T17:00"],
    "temperature_2m": [13.9, 13.1],
    "precipitation_probability": [0, null],
    "weather_code": [1, 2],
    "is_day": [1, 0]
  },
  "daily": {
    "time": ["2026-10-28", "2026-10-29"],
    "weather_code": [80, 61],
    "temperature_2m_max": [14.9, 19.4],
    "temperature_2m_min": [9.4, 9.9],
    "precipitation_probability_max": [100]
  }
}
''';
