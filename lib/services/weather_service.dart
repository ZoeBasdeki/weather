import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown for any network / HTTP / parse failure when talking to Open-Meteo.
class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin client for the Open-Meteo forecast API (no API key needed).
/// Returns the raw JSON body so the caller can cache it verbatim.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'api.open-meteo.com';
  static const _timeout = Duration(seconds: 15);

  static const _vars = [
    'temperature_2m',
    'apparent_temperature',
    'precipitation_probability',
    'precipitation',
    'wind_speed_10m',
    'wind_direction_10m',
    'relative_humidity_2m',
    'weather_code',
    'is_day',
  ];

  static const _dailyVars = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'apparent_temperature_max',
    'apparent_temperature_min',
    'precipitation_probability_max',
    'precipitation_sum',
    'wind_speed_10m_max',
    'wind_direction_10m_dominant',
    'relative_humidity_2m_mean',
  ];

  /// Fetches current conditions, the next 48 hours and 14 days.
  /// Returns the raw JSON body; parsing happens in the repository.
  Future<String> fetchForecastJson(double latitude, double longitude) {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'timezone': 'auto',
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
      'precipitation_unit': 'mm',
      'forecast_days': '14',
      'forecast_hours': '48',
      'current': _vars.join(','),
      'hourly': _vars.join(','),
      'daily': _dailyVars.join(','),
    });

    return getJsonBody(_client, uri, _timeout);
  }
}

/// Shared GET helper: maps transport errors to [WeatherServiceException].
Future<String> getJsonBody(http.Client client, Uri uri, Duration timeout) async {
  final http.Response res;
  try {
    res = await client.get(uri).timeout(timeout);
  } on TimeoutException {
    throw const WeatherServiceException('Request timed out');
  } on SocketException {
    throw const WeatherServiceException('No internet connection');
  } on http.ClientException catch (e) {
    throw WeatherServiceException('Network error: ${e.message}');
  }

  if (res.statusCode != 200) {
    // Open-Meteo returns {"error": true, "reason": "..."} on 400.
    String? reason;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['reason'] is String) {
        reason = decoded['reason'] as String;
      }
    } on FormatException {
      // ignore, fall through to generic message
    }
    throw WeatherServiceException(reason ?? 'Server error (${res.statusCode})');
  }
  return res.body;
}
