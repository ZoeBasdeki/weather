import 'package:flutter/material.dart';

/// WMO weather interpretation codes as used by Open-Meteo.
/// See https://open-meteo.com/en/docs (section "WMO Weather interpretation codes").
class WeatherCode {
  const WeatherCode._(this.description, this.dayIcon, [IconData? nightIcon])
      : nightIcon = nightIcon ?? dayIcon;

  final String description;
  final IconData dayIcon;
  final IconData nightIcon;

  IconData icon({bool isDay = true}) => isDay ? dayIcon : nightIcon;

  static const unknown = WeatherCode._('Unknown', Icons.help_outline);

  static const Map<int, WeatherCode> _codes = {
    0: WeatherCode._('Clear sky', Icons.sunny, Icons.nightlight_round),
    1: WeatherCode._('Mainly clear', Icons.sunny, Icons.nightlight_round),
    2: WeatherCode._('Partly cloudy', Icons.wb_cloudy, Icons.cloud),
    3: WeatherCode._('Overcast', Icons.cloud),
    45: WeatherCode._('Fog', Icons.foggy),
    48: WeatherCode._('Depositing rime fog', Icons.foggy),
    51: WeatherCode._('Light drizzle', Icons.grain),
    53: WeatherCode._('Moderate drizzle', Icons.grain),
    55: WeatherCode._('Dense drizzle', Icons.grain),
    56: WeatherCode._('Light freezing drizzle', Icons.severe_cold),
    57: WeatherCode._('Dense freezing drizzle', Icons.severe_cold),
    61: WeatherCode._('Slight rain', Icons.water_drop),
    63: WeatherCode._('Moderate rain', Icons.water_drop),
    65: WeatherCode._('Heavy rain', Icons.umbrella),
    66: WeatherCode._('Light freezing rain', Icons.severe_cold),
    67: WeatherCode._('Heavy freezing rain', Icons.severe_cold),
    71: WeatherCode._('Slight snowfall', Icons.ac_unit),
    73: WeatherCode._('Moderate snowfall', Icons.ac_unit),
    75: WeatherCode._('Heavy snowfall', Icons.snowing),
    77: WeatherCode._('Snow grains', Icons.ac_unit),
    80: WeatherCode._('Slight rain showers', Icons.water_drop),
    81: WeatherCode._('Moderate rain showers', Icons.umbrella),
    82: WeatherCode._('Violent rain showers', Icons.umbrella),
    85: WeatherCode._('Slight snow showers', Icons.cloudy_snowing),
    86: WeatherCode._('Heavy snow showers', Icons.cloudy_snowing),
    95: WeatherCode._('Thunderstorm', Icons.thunderstorm),
    96: WeatherCode._('Thunderstorm with slight hail', Icons.thunderstorm),
    99: WeatherCode._('Thunderstorm with heavy hail', Icons.thunderstorm),
  };

  static WeatherCode fromCode(int? code) => _codes[code] ?? unknown;
}
