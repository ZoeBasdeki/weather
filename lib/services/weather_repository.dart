import 'dart:convert';

import '../models/forecast.dart';
import '../models/json_utils.dart';
import '../models/place.dart';
import 'cache_service.dart';
import 'weather_service.dart';

/// A forecast ready for display, plus where it came from.
class ForecastResult {
  const ForecastResult({
    required this.place,
    required this.forecast,
    required this.fetchedAt,
    required this.fromCache,
    this.error,
  });

  final Place place;
  final Forecast forecast;
  final DateTime fetchedAt;

  /// True when the network fetch failed and this is the last saved response.
  final bool fromCache;

  /// Why the live fetch failed (only set when [fromCache] is true).
  final String? error;
}

/// Single entry point for the UI: fetch live, save to the place's cache entry,
/// fall back to that entry on failure.
class WeatherRepository {
  WeatherRepository({WeatherService? service, CacheService? cache})
      : _service = service ?? WeatherService(),
        _cache = cache ?? CacheService();

  final WeatherService _service;
  final CacheService _cache;

  /// Last cached result for the place with [placeId] ([Place.id]), for instant
  /// display. Null if none.
  Future<ForecastResult?> loadCached(String placeId) async {
    final cached = await _cache.load(placeId);
    if (cached == null) return null;
    final forecast = _parse(cached.json);
    if (forecast == null) return null;
    return ForecastResult(
      place: cached.place,
      forecast: forecast,
      fetchedAt: cached.fetchedAt,
      fromCache: true,
    );
  }

  /// Fetches a fresh forecast for [place]. On failure returns that place's
  /// cached forecast. For the GPS location the cached fix may be an older
  /// position. Rethrows only when there is nothing cached to fall back on.
  Future<ForecastResult> fetch(Place place) async {
    try {
      final json = await _service.fetchForecastJson(place.latitude, place.longitude);
      final forecast = _parse(json);
      if (forecast == null) {
        throw const WeatherServiceException('Invalid response from weather server');
      }
      final now = DateTime.now();
      try {
        await _cache.save(CachedForecast(place: place, json: json, fetchedAt: now));
      } catch (_) {
        // Failing to cache shouldn't hide fresh data.
      }
      return ForecastResult(
        place: place,
        forecast: forecast,
        fetchedAt: now,
        fromCache: false,
      );
    } on WeatherServiceException catch (e) {
      final cached = await loadCached(place.id);
      if (cached == null) rethrow;
      return ForecastResult(
        place: cached.place,
        forecast: cached.forecast,
        fetchedAt: cached.fetchedAt,
        fromCache: true,
        error: e.message,
      );
    }
  }

  /// Drops the cached forecast for a place that is no longer shown.
  Future<void> forget(String placeId) async {
    try {
      await _cache.remove(placeId);
    } catch (_) {
      // A leftover cache entry is harmless.
    }
  }

  static Forecast? _parse(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      return Forecast.fromJson(asMap(decoded));
    } on FormatException {
      return null;
    }
  }
}
