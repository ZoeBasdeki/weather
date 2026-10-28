import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/json_utils.dart';
import '../models/place.dart';
import 'weather_service.dart';

/// City search via the Open-Meteo geocoding API (no API key needed).
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// Returns up to [count] matching places. Queries shorter than 2 characters
  /// return an empty list (the API does the same).
  Future<List<Place>> search(String query, {int count = 10}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': q,
      'count': '$count',
      'language': 'en',
      'format': 'json',
    });

    final body = await getJsonBody(_client, uri, _timeout);
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const WeatherServiceException('Invalid response from geocoding server');
    }
    // `results` is absent when there are no matches.
    return asList(asMap(decoded)['results'])
        .map(Place.fromGeocodingJson)
        .whereType<Place>()
        .toList();
  }
}
